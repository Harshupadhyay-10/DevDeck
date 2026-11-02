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
    @State private var deviceStore: PairedDeviceStore
    @State private var pairingListener: PairingListener
    @State private var showingPairingSheet = false

    init() {
        let deviceStore = PairedDeviceStore(service: MacIdentity.pairedDevicesService)
        _deviceStore = State(initialValue: deviceStore)
        _pairingListener = State(initialValue: PairingListener(deviceStore: deviceStore))
    }

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
        .sheet(isPresented: $showingPairingSheet) {
            PairingSheet(listener: pairingListener)
        }
    }

    private var sidebar: some View {
        List(selection: $selectedActionID) {
            Section("Device") {
                Button {
                    showingPairingSheet = true
                } label: {
                    Label("Connect to Device...", systemImage: "wifi")
                }
                .buttonStyle(.plain)

                ForEach(deviceStore.devices) { device in
                    Label(device.displayName, systemImage: "iphone")
                        .contextMenu {
                            Button("Remove", role: .destructive) {
                                deviceStore.remove(device)
                            }
                        }
                }
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
