//
//  ContentView.swift
//  DevDeckMac
//
//  Created by Harsh Upadhyay on 24/10/2026.
//

import DevDeckKit
import SwiftUI

struct ContentView: View {
    @State private var store = DeckStore()
    @State private var selectedActionID: String?

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            HStack(spacing: 0) {
                PhonePreview(actions: store.actions)
                    .frame(maxWidth: .infinity)

                Divider()

                Group {
                    if let selectedActionID {
                        ActionEditorView(store: store, actionID: selectedActionID)
                    } else {
                        ContentUnavailableView(
                            "No Action Selected",
                            systemImage: "square.grid.2x2",
                            description: Text("Choose an action from the sidebar, or add a new one.")
                        )
                    }
                }
                .frame(width: 320)
            }
        }
        .navigationTitle("Dev Deck")
    }

    private var sidebar: some View {
        List(selection: $selectedActionID) {
            Section("Device") {
                Label("Connect to Device...", systemImage: "wifi")
                    .foregroundStyle(.secondary)
                    .disabled(true)
            }

            Section("Actions") {
                ForEach(store.actions) { action in
                    Label(action.title, systemImage: action.systemImage)
                        .foregroundStyle(action.isDestructive ? .red : .primary)
                        .tag(action.id)
                }
            }
        }
        .toolbar {
            ToolbarItem {
                Button(action: store.addAction) {
                    Label("Add Action", systemImage: "plus")
                }
            }
        }
        .navigationSplitViewColumnWidth(min: 200, ideal: 220)
    }
}

#Preview {
    ContentView()
}
