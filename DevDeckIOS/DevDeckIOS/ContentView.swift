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

    var body: some View {
        NavigationStack {
            DeckGridView(actions: actions) { _ in
                // Wiring to the Mac companion comes later.
            }
            .navigationTitle("Dev Deck")
            .background(.background)
        }
    }
}

#Preview {
    ContentView(actions: DeckAction.previewActions)
}
