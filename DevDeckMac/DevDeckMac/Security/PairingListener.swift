//
//  PairingListener.swift
//  DevDeckMac
//
//  Created by Harsh Upadhyay on 29/10/2026.
//

import CryptoKit
import DevDeckKit
import Foundation
import Observation

/// Advertises this Mac over Bonjour and accepts one phone's pairing
/// handshake while a pairing session is open. Not listening at all
/// outside of that, so there is nothing to connect to unless someone is
/// actively pairing on an unlocked Mac. Fails closed: any malformed
/// message or failed confirmation ends the connection without trusting
/// it, and pairing stops entirely after too many bad attempts.
@Observable
final class PairingListener {
    enum Status: Equatable {
        case idle
        case waiting
        case paired(String)
        case failed(String)
    }

    private(set) var status: Status = .idle
    private(set) var qrPayload: PairingQRPayload?
    private(set) var pin: String = ""
    /// Most recent step, for visibility into exactly where a stalled or
    /// failed handshake stopped making progress.
    private(set) var lastEvent: String = "Waiting for a connection..."

    private let tcpListener = TCPListener()
    private let advertiser = BonjourAdvertiser()
    private var remainingAttempts = 5
    private var token = Data()
    private let deviceStore: PairedDeviceStore

    init(deviceStore: PairedDeviceStore) {
        self.deviceStore = deviceStore
    }

    func start() {
        stop()
        status = .waiting
        lastEvent = "Waiting for a connection..."
        remainingAttempts = 5
        token = Data((0..<16).map { _ in UInt8.random(in: .min ... .max) })
        pin = String(format: "%06d", Int.random(in: 0..<1_000_000))

        let serviceName = "DevDeck-\(UUID().uuidString.prefix(8))"

        guard let host = LocalNetwork.primaryIPv4Address() else {
            status = .failed("Could not determine this Mac's network address.")
            return
        }

        do {
            try tcpListener.start { [weak self] connection in
                self?.handle(connection)
            }
        } catch {
            status = .failed("Could not start listening: \(error)")
            return
        }

        let port = tcpListener.port
        qrPayload = PairingQRPayload(
            macPublicKey: MacIdentity.privateKey.publicKey.rawRepresentation,
            token: token,
            serviceName: serviceName,
            macDisplayName: MacIdentity.displayName,
            host: host,
            port: port
        )

        let txtRecord = PairingTXTRecord.encode(host: host, port: port)
        advertiser.publish(name: serviceName, type: DevDeckService.pairingType, port: port, txtRecord: txtRecord)
    }

    func stop() {
        advertiser.stop()
        tcpListener.stop()
        qrPayload = nil
        pin = ""
        if status == .waiting {
            status = .idle
        }
    }

    private func handle(_ connection: TCPConnection) {
        lastEvent = "Connection received, opening..."
        Task {
            do {
                try await withPairingTimeout(seconds: 10) {
                    try await self.runHandshake(connection)
                }
            } catch {
                lastEvent = "Connection failed or timed out: \(error)"
                connection.close()
            }
        }
    }

    private func runHandshake(_ connection: TCPConnection) async throws {
        lastEvent = "Connection open, waiting for the phone's identity..."
        let hello = try await connection.receive(PairingHello.self)
        lastEvent = "Received identity from \(hello.displayName)."

        guard remainingAttempts > 0 else {
            connection.close()
            return
        }

        let macHello = PairingHello(
            publicKey: MacIdentity.privateKey.publicKey.rawRepresentation,
            displayName: MacIdentity.displayName
        )
        try await connection.send(macHello)
        lastEvent = "Sent our identity, waiting for confirmation..."

        let confirm = try await connection.receive(PairingConfirm.self)
        lastEvent = "Received confirmation, checking the secret..."

        guard let sessionKey = resolveSessionKey(clientPublicKey: hello.publicKey, confirm: confirm) else {
            lastEvent = "Confirmation did not match the QR token or PIN."
            remainingAttempts -= 1
            connection.close()
            if remainingAttempts == 0 {
                status = .failed("Too many failed pairing attempts.")
                stop()
            }
            return
        }

        let existingID = deviceStore.devices.first { $0.publicKeyData == hello.publicKey }?.id
        let device = PairedDevice(
            id: existingID ?? UUID().uuidString,
            displayName: hello.displayName,
            publicKeyData: hello.publicKey,
            pairedAt: Date()
        )
        deviceStore.save(device)

        let ack = try PairingCrypto.seal(PairingConfirm.macMagic, using: sessionKey)
        try await connection.send(PairingConfirm(sealed: ack))

        status = .paired(device.displayName)
        stop()
    }

    /// Tries the QR token first, then the PIN, since the Mac does not
    /// know which one the phone used. Whichever successfully opens the
    /// confirmation message is the real session key; a derived key from
    /// the wrong secret never throws on its own; only the attempt to open
    /// the sealed box with it does.
    private func resolveSessionKey(clientPublicKey: Data, confirm: PairingConfirm) -> SymmetricKey? {
        for secret in [token, Data(pin.utf8)] {
            guard let key = try? PairingCrypto.sessionKey(
                ourPrivateKey: MacIdentity.privateKey,
                theirPublicKeyData: clientPublicKey,
                outOfBandSecret: secret
            ) else { continue }

            if let opened = try? PairingCrypto.open(confirm.sealed, using: key),
               opened == PairingConfirm.clientMagic {
                return key
            }
        }
        return nil
    }
}
