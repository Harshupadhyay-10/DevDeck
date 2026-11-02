//
//  ContentView.swift
//  DevDeckIOS
//
//  Created by Harsh Upadhyay on 24/10/2026.
//

import DevDeckKit
import SwiftUI

struct ContentView: View {
    let actions: [DeckAction]
    @State private var showingPairing = false

    var body: some View {
        NavigationStack {
            DeckGridView(actions: actions) { _ in
                // Wiring to the Mac companion comes later.
            }
            .navigationTitle("Dev Deck")
            .background(.background)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingPairing = true
                    } label: {
                        Label("Pair with Mac", systemImage: "wifi")
                    }
                }
            }
            .sheet(isPresented: $showingPairing) {
                PairingView()
            }
        }
    }
}

#Preview {
    ContentView(actions: DeckAction.previewActions)
}
