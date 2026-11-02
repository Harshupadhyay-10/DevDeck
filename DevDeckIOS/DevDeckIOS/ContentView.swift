//
//  ContentView.swift
//  DevDeckIOS
//
//  Created by Harsh Upadhyay on 24/10/2026.
//

import DevDeckKit
import SwiftUI

struct ContentView: View {
    @State private var macStore: PairedDeviceStore
    @State private var runner: ActionRunner
    @State private var showingPairing = false
    @State private var pendingDestructiveAction: DeckAction?
    @AppStorage("hasShownLandscapeHint") private var hasShownLandscapeHint = false
    @State private var showingLandscapeHint = false

    init() {
        let macStore = PairedDeviceStore(service: PhoneIdentity.pairedMacsService)
        _macStore = State(initialValue: macStore)
        _runner = State(initialValue: ActionRunner(macStore: macStore))
    }

    var body: some View {
        NavigationStack {
            Group {
                if runner.actions.isEmpty {
                    ContentUnavailableView(
                        "No Deck Yet",
                        systemImage: "square.grid.2x2",
                        description: Text("Pair with your Mac to load its actions.")
                    )
                } else {
                    DeckGridView(actions: runner.actions) { action in
                        if action.isDestructive {
                            pendingDestructiveAction = action
                        } else {
                            Task { await runner.run(action) }
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                statusBanner
            }
            .navigationTitle("DevDeck")
            .background {
                ZStack {
                    Color(.systemBackground)
                    DeckBackgroundView(runner.background)
                }
                .ignoresSafeArea()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await runner.refreshDeck() }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingPairing = true
                    } label: {
                        Label("Pair with Mac", systemImage: "wifi")
                    }
                }
            }
            .sheet(isPresented: $showingPairing, onDismiss: {
                Task { await runner.refreshDeck() }
            }) {
                PairingView(macStore: macStore)
            }
            .task {
                await runner.refreshDeck()
                if !hasShownLandscapeHint {
                    hasShownLandscapeHint = true
                    showingLandscapeHint = true
                }
            }
            .alert("Best in Landscape", isPresented: $showingLandscapeHint) {
                Button("Got It") {}
            } message: {
                Text("DevDeck is designed to be used in landscape, with more of the deck visible at once.")
            }
            .confirmationDialog(
                "Run \(pendingDestructiveAction?.title ?? "")?",
                isPresented: Binding(
                    get: { pendingDestructiveAction != nil },
                    set: { if !$0 { pendingDestructiveAction = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Run", role: .destructive) {
                    if let action = pendingDestructiveAction {
                        Task { await runner.run(action) }
                    }
                    pendingDestructiveAction = nil
                }
                Button("Cancel", role: .cancel) {
                    pendingDestructiveAction = nil
                }
            }
        }
    }

    @ViewBuilder
    private var statusBanner: some View {
        switch runner.runStatus {
        case .running(let id):
            if let title = runner.actions.first(where: { $0.id == id })?.title {
                Label("Running \(title)...", systemImage: "ellipsis.circle")
                    .padding(8)
                    .background(.thinMaterial, in: Capsule())
                    .padding(.bottom, 8)
            }
        case .failed(let message):
            Label(message, systemImage: "xmark.octagon.fill")
                .foregroundStyle(.red)
                .padding(8)
                .background(.thinMaterial, in: Capsule())
                .padding(.bottom, 8)
        case .idle:
            EmptyView()
        }
    }
}

#Preview {
    ContentView()
}
