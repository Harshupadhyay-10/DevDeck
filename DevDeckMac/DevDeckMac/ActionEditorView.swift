//
//  ActionEditorView.swift
//  DevDeckMac
//
//  Created by Harsh Upadhyay on 24/10/2026.
//

import DevDeckKit
import SwiftUI

/// Editor for one deck action's display: title, SF Symbol, and whether it
/// is destructive. The Mac is the only place actions are edited.
struct ActionEditorView: View {
    @Bindable var store: DeckStore
    let actionID: String

    private var index: Int? {
        store.actions.firstIndex { $0.id == actionID }
    }

    var body: some View {
        if let index {
            Form {
                Section("Details") {
                    TextField("Title", text: $store.actions[index].title)
                    TextField("SF Symbol name", text: $store.actions[index].systemImage)
                    Toggle("Destructive", isOn: $store.actions[index].isDestructive)
                }

                Section {
                    Button("Delete Action", role: .destructive) {
                        store.remove(store.actions[index])
                    }
                }
            }
            .formStyle(.grouped)
            .frame(minWidth: 280)
        } else {
            ContentUnavailableView(
                "No Action Selected",
                systemImage: "square.grid.2x2",
                description: Text("Choose an action from the sidebar, or add a new one.")
            )
        }
    }
}
