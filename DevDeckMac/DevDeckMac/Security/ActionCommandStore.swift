//
//  ActionCommandStore.swift
//  DevDeckMac
//
//  Created by Harsh Upadhyay on 02/11/2026.
//

import Foundation
import Observation

/// The actual command behind each action id. Never sent to the phone or
/// anywhere over the network; the phone only ever sees the id. Stored as
/// a local file with user-only permissions, matching the threat model's
/// requirement for action definitions.
@Observable
final class ActionCommandStore {
    private(set) var commands: [String: String] = [:]

    private let fileURL: URL

    init() {
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DevDeck", isDirectory: true)
        try? FileManager.default.createDirectory(at: supportDir, withIntermediateDirectories: true)
        fileURL = supportDir.appendingPathComponent("commands.json")
        load()
    }

    func command(for actionID: String) -> String? {
        commands[actionID]
    }

    func setCommand(_ command: String, for actionID: String) {
        commands[actionID] = command
        save()
    }

    func removeCommand(for actionID: String) {
        commands.removeValue(forKey: actionID)
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([String: String].self, from: data) else { return }
        commands = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(commands) else { return }
        try? data.write(to: fileURL, options: .atomic)
        try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
    }
}
