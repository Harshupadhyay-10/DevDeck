//
//  ActionRunner.swift
//  DevDeckIOS
//
//  Created by Harsh Upadhyay on 02/11/2026.
//

import CryptoKit
import DevDeckKit
import Foundation
import Observation

/// Talks to the paired Mac's always-on run service: syncs the deck on
/// every connection and, when asked, runs one action. Rediscovers the
/// Mac fresh each time via Bonjour rather than reusing a cached address,
/// since the Mac's host and port can change between launches.
@Observable
final class ActionRunner {
    enum RunStatus: Equatable {
        case idle
        case running(String)
        case failed(String)
    }

    private(set) var actions: [DeckAction] = []
    private(set) var runStatus: RunStatus = .idle

    private let macStore: PairedDeviceStore
    private let browser = BonjourBrowser()

    init(macStore: PairedDeviceStore) {
        self.macStore = macStore
    }

    func refreshDeck() async {
        guard let mac = macStore.devices.first else {
            runStatus = .failed("No paired Mac on this phone.")
            return
        }
        do {
            try await withSession(expectedPeerPublicKey: mac.publicKeyData) { connection, key in
                let sync = try await RunSession.receive(DeckSyncMessage.self, from: connection, using: key)
                self.actions = sync.actions
            }
            runStatus = .idle
        } catch {
            runStatus = .failed("Could not load the deck: \(error)")
        }
    }

    func run(_ action: DeckAction) async {
        guard let mac = macStore.devices.first else {
            runStatus = .failed("No paired Mac.")
            return
        }
        runStatus = .running(action.id)

        let result: RunActionResult? = try? await withSession(expectedPeerPublicKey: mac.publicKeyData) { connection, key in
            let sync = try await RunSession.receive(DeckSyncMessage.self, from: connection, using: key)
            self.actions = sync.actions
            try await RunSession.send(RunActionRequest(actionID: action.id), on: connection, using: key)
            return try await RunSession.receive(RunActionResult.self, from: connection, using: key)
        }

        if let result, result.succeeded {
            runStatus = .idle
        } else {
            runStatus = .failed(result?.errorMessage ?? "Could not reach the Mac.")
        }
    }

    private func withSession<T: Sendable>(
        expectedPeerPublicKey: Data,
        _ body: @escaping @Sendable (TCPConnection, SymmetricKey) async throws -> T
    ) async throws -> T {
        try await withPairingTimeout(seconds: 10) {
            let hostPort = try await self.discoverMac()
            let connection = try await TCPConnection.connect(host: hostPort.host, port: hostPort.port)
            defer { connection.close() }

            let sessionKey = try await RunSession.authenticateAsClient(
                connection: connection,
                ourPrivateKey: PhoneIdentity.privateKey,
                expectedPeerPublicKey: expectedPeerPublicKey
            )

            return try await body(connection, sessionKey)
        }
    }

    private func discoverMac() async throws -> (host: String, port: UInt16) {
        try await withCheckedThrowingContinuation { continuation in
            var didResume = false
            browser.onUpdate = { [weak self] hostPorts in
                guard !didResume, let first = hostPorts.values.first else { return }
                didResume = true
                self?.browser.stop()
                continuation.resume(returning: first)
            }
            browser.start(type: DevDeckService.runType)
        }
    }
}
