//
//  DeckStore.swift
//  DevDeckMac
//
//  Created by Harsh Upadhyay on 24/10/2026.
//

import DevDeckKit
import Foundation
import Observation

/// Holds the action definitions edited on the Mac. In-memory only for now;
/// persistence and syncing to paired phones come later.
@Observable
final class DeckStore {
    var actions: [DeckAction] = DeckAction.previewActions

    func addAction() {
        let newAction = DeckAction(id: UUID().uuidString, title: "New Action", systemImage: "star")
        actions.append(newAction)
    }

    func update(_ action: DeckAction) {
        guard let index = actions.firstIndex(where: { $0.id == action.id }) else { return }
        actions[index] = action
    }

    func remove(_ action: DeckAction) {
        actions.removeAll { $0.id == action.id }
    }
}
