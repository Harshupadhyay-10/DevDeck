//
//  ActionEditorView.swift
//  DevDeckMac
//
//  Created by Harsh Upadhyay on 24/10/2026.
//

import DevDeckKit
import SwiftUI

/// Editor for one deck action: display (title, SF Symbol, destructive,
/// appearance) plus the actual command behind it, which stays on the Mac
/// and is never sent to the phone. The Mac is the only place actions are
/// edited.
struct ActionEditorView: View {
    @Bindable var store: DeckStore
    @Bindable var commandStore: ActionCommandStore
    let actionID: String

    private var index: Int? {
        store.actions.firstIndex { $0.id == actionID }
    }

    private var commandBinding: Binding<String> {
        Binding(
            get: { commandStore.command(for: actionID) ?? "" },
            set: { commandStore.setCommand($0, for: actionID) }
        )
    }

    var body: some View {
        if let index {
            Form {
                Section("Details") {
                    TextField("Title", text: $store.actions[index].title)
                    TextField("SF Symbol name", text: $store.actions[index].systemImage)
                    Toggle("Destructive", isOn: $store.actions[index].isDestructive)
                }

                Section("Appearance") {
                    Picker("Style", selection: $store.actions[index].style.material) {
                        Text("Glass").tag(TileStyle.Material.glass)
                        Text("Solid").tag(TileStyle.Material.solid)
                    }
                    .pickerStyle(.segmented)

                    SwatchColorPicker(title: "Tint", selection: tintBinding(index: index))

                    if store.actions[index].style.material == .solid {
                        BackgroundEditorView(background: $store.actions[index].style.background)
                    }
                }

                Section("Command") {
                    TextField("Shell command", text: commandBinding, axis: .vertical)
                        .lineLimit(2...6)
                        .font(.system(.body, design: .monospaced))
                    Text("Runs as you, via /bin/zsh, when this action is triggered from a paired device.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button("Delete Action", role: .destructive) {
                        commandStore.removeCommand(for: actionID)
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

    private func tintBinding(index: Int) -> Binding<Color> {
        Binding(
            get: {
                store.actions[index].style.tintColor?.color
                    ?? (store.actions[index].isDestructive ? .red : .accentColor)
            },
            set: { store.actions[index].style.tintColor = TileColor($0) }
        )
    }
}
