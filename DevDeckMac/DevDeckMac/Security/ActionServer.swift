//
//  ActionServer.swift
//  DevDeckMac
//
//  Created by Harsh Upadhyay on 02/11/2026.
//

import CoreGraphics
import CryptoKit
import DevDeckKit
import Foundation
import Observation

/// Listens continuously (while the app is running) for already-paired
/// devices to sync the deck or run an action. Unlike pairing, this never
/// trusts a new device on its own; every connection must present a
/// public key already in the paired device list, and is rejected
/// immediately otherwise. Refuses to run anything while the screen is
/// locked.
@Observable
final class ActionServer {
    private let tcpListener = TCPListener()
    private let advertiser = BonjourAdvertiser()
    private let deviceStore: PairedDeviceStore
    private let deckStore: DeckStore
    private let commandStore: ActionCommandStore

    init(deviceStore: PairedDeviceStore, deckStore: DeckStore, commandStore: ActionCommandStore) {
        self.deviceStore = deviceStore
        self.deckStore = deckStore
        self.commandStore = commandStore
    }

    func start() {
        guard let host = LocalNetwork.primaryIPv4Address() else { return }

        do {
            try tcpListener.start { [weak self] connection in
                self?.handle(connection)
            }
        } catch {
            return
        }

        let serviceName = "DevDeckRun-\(MacIdentity.privateKey.publicKey.rawRepresentation.prefix(4).map { String(format: "%02x", $0) }.joined())"
        let txtRecord = PairingTXTRecord.encode(host: host, port: tcpListener.port)
        advertiser.publish(name: serviceName, type: DevDeckService.runType, port: tcpListener.port, txtRecord: txtRecord)
    }

    func stop() {
        advertiser.stop()
        tcpListener.stop()
    }

    private func handle(_ connection: TCPConnection) {
        Task {
            do {
                try await withPairingTimeout(seconds: 15) {
                    try await self.runSession(connection)
                }
            } catch {
                print("DevDeck: run session failed or was rejected: \(error)")
                connection.close()
            }
        }
    }

    private func runSession(_ connection: TCPConnection) async throws {
        let (sessionKey, peerHello) = try await RunSession.authenticateAsServer(
            connection: connection,
            ourPrivateKey: MacIdentity.privateKey
        ) { [deviceStore] publicKey in
            deviceStore.devices.contains { $0.publicKeyData == publicKey }
        }

        if let screen = peerHello.deviceScreen,
           var device = deviceStore.devices.first(where: { $0.publicKeyData == peerHello.publicKey }) {
            device.screen = screen
            deviceStore.save(device)
        }

        let sync = DeckSyncMessage(actions: deckStore.actions, background: deckStore.background)
        try await RunSession.send(sync, on: connection, using: sessionKey)

        guard let request = try? await RunSession.receive(RunActionRequest.self, from: connection, using: sessionKey) else {
            connection.close()
            return
        }

        let result = await runAction(request.actionID)
        try await RunSession.send(result, on: connection, using: sessionKey)
        connection.close()
    }

    private func runAction(_ actionID: String) async -> RunActionResult {
        guard !Self.isScreenLocked() else {
            return RunActionResult(actionID: actionID, succeeded: false, errorMessage: "Mac is locked.")
        }
        guard let command = commandStore.command(for: actionID), !command.isEmpty else {
            return RunActionResult(actionID: actionID, succeeded: false, errorMessage: "No command set for this action.")
        }

        let succeeded = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/bin/zsh")
                process.arguments = ["-c", command]
                do {
                    try process.run()
                    process.waitUntilExit()
                    continuation.resume(returning: process.terminationStatus == 0)
                } catch {
                    continuation.resume(returning: false)
                }
            }
        }

        return RunActionResult(actionID: actionID, succeeded: succeeded, errorMessage: succeeded ? nil : "The command failed.")
    }

    private static func isScreenLocked() -> Bool {
        guard let info = CGSessionCopyCurrentDictionary() as? [String: Any] else { return false }
        return info["CGSSessionScreenIsLocked"] as? Bool ?? false
    }
}
