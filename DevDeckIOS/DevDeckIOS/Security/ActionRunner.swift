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
import UIKit

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
    private(set) var background: TileStyle.Background = .none
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
                self.background = sync.background
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
            self.background = sync.background
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
        // Read on the caller's (main) context, not inside the Sendable
        // closure below, since UIScreen.main is actor-isolated.
        let screen = Self.currentScreenSize()

        return try await withPairingTimeout(seconds: 10) {
            let hostPort = try await self.discoverMac()
            let connection = try await TCPConnection.connect(host: hostPort.host, port: hostPort.port)
            defer { connection.close() }

            let sessionKey = try await RunSession.authenticateAsClient(
                connection: connection,
                ourPrivateKey: PhoneIdentity.privateKey,
                expectedPeerPublicKey: expectedPeerPublicKey,
                deviceScreen: DeviceScreenInfo(widthPoints: screen.width, heightPoints: screen.height)
            )

            return try await body(connection, sessionKey)
        }
    }

    /// A window's bounds reflect the current interface orientation;
    /// UIScreen's do not, always reporting the device's fixed native
    /// (portrait) size regardless of how it is actually held. We want
    /// the live one, so the Mac's preview shows the orientation the
    /// phone was actually in at the moment of the last sync.
    @MainActor
    private static func currentScreenSize() -> CGSize {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?.bounds.size ?? CGSize(width: 390, height: 844)
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
