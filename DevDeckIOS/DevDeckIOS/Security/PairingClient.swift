//
//  PairingClient.swift
//  DevDeckIOS
//
//  Created by Harsh Upadhyay on 29/10/2026.
//

import CryptoKit
import DevDeckKit
import Foundation
import Observation

/// Finds a Mac over Bonjour and runs the pairing handshake against it,
/// either from a scanned QR code (the Mac's public key, host, port and
/// token travel out of band, so this path can't be man-in-the-middled)
/// or a manually entered PIN (weaker, rate-limited by the Mac, meant as
/// a fallback). Always connects to a concrete host/port the Mac handed
/// over directly, via plain TCP sockets rather than Network.framework,
/// which proved unreliable for local connections in testing.
@Observable
final class PairingClient {
    enum Status: Equatable {
        case idle
        case browsing
        case connecting(String)
        case paired(String)
        case failed(String)
    }

    private(set) var status: Status = .idle
    private(set) var discoveredMacs: [String] = []

    private var discoveredHostPorts: [String: (host: String, port: UInt16)] = [:]
    private let browser = BonjourBrowser()
    private let macStore: PairedDeviceStore

    init(macStore: PairedDeviceStore) {
        self.macStore = macStore
        browser.onUpdate = { [weak self] hostPorts in
            self?.discoveredHostPorts = hostPorts
            self?.discoveredMacs = hostPorts.keys.sorted()
        }
    }

    func startBrowsing() {
        discoveredMacs = []
        discoveredHostPorts = [:]
        browser.start(type: DevDeckService.pairingType)
    }

    func stopBrowsing() {
        browser.stop()
    }

    func pair(qrString: String) {
        guard let data = qrString.data(using: .utf8),
              let payload = try? JSONDecoder().decode(PairingQRPayload.self, from: data) else {
            status = .failed("That QR code isn't a DevDeck pairing code.")
            return
        }
        pair(
            host: payload.host,
            port: payload.port,
            displayName: payload.serviceName,
            macPublicKeyHint: payload.macPublicKey,
            secret: payload.token
        )
    }

    func pair(serviceName: String, pin: String) {
        guard let hostPort = discoveredHostPorts[serviceName] else {
            status = .failed("Lost track of that Mac on the network. Try again.")
            return
        }
        pair(
            host: hostPort.host,
            port: hostPort.port,
            displayName: serviceName,
            macPublicKeyHint: nil,
            secret: Data(pin.utf8)
        )
    }

    private func pair(host: String, port: UInt16, displayName: String, macPublicKeyHint: Data?, secret: Data) {
        status = .connecting("Connecting to \(displayName)...")
        stopBrowsing()

        Task {
            do {
                let mac = try await withPairingTimeout(seconds: 10) {
                    try await self.runHandshake(host: host, port: port, macPublicKeyHint: macPublicKeyHint, secret: secret)
                }
                macStore.save(mac)
                status = .paired(mac.displayName)
            } catch let error as PairingFailure {
                status = .failed(error.message)
            } catch is PairingTimeout {
                status = .failed("Timed out connecting to that Mac.")
            } catch {
                status = .failed("Could not connect to that Mac.")
            }
        }
    }

    private func runHandshake(host: String, port: UInt16, macPublicKeyHint: Data?, secret: Data) async throws -> PairedDevice {
        status = .connecting("Opening connection...")
        let connection = try await TCPConnection.connect(host: host, port: port)
        defer { connection.close() }

        status = .connecting("Sending identity...")
        let hello = PairingHello(
            publicKey: PhoneIdentity.privateKey.publicKey.rawRepresentation,
            displayName: PhoneIdentity.displayName
        )
        try await connection.send(hello)

        status = .connecting("Waiting for the Mac to respond...")
        let macHello = try await connection.receive(PairingHello.self)

        if let macPublicKeyHint, macPublicKeyHint != macHello.publicKey {
            throw PairingFailure("The Mac's identity did not match the QR code.")
        }

        status = .connecting("Confirming...")
        let sessionKey = try PairingCrypto.sessionKey(
            ourPrivateKey: PhoneIdentity.privateKey,
            theirPublicKeyData: macHello.publicKey,
            outOfBandSecret: secret
        )

        let sealed = try PairingCrypto.seal(PairingConfirm.clientMagic, using: sessionKey)
        try await connection.send(PairingConfirm(sealed: sealed))

        let ack = try await connection.receive(PairingConfirm.self)
        let opened = try PairingCrypto.open(ack.sealed, using: sessionKey)
        guard opened == PairingConfirm.macMagic else {
            throw PairingFailure("Pairing could not be confirmed.")
        }

        let existingID = macStore.devices.first { $0.publicKeyData == macHello.publicKey }?.id
        return PairedDevice(
            id: existingID ?? UUID().uuidString,
            displayName: macHello.displayName,
            publicKeyData: macHello.publicKey,
            pairedAt: Date()
        )
    }
}

private struct PairingFailure: Error {
    let message: String
    init(_ message: String) { self.message = message }
}
