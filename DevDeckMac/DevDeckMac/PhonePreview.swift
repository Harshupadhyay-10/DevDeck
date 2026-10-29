//
//  PhonePreview.swift
//  DevDeckMac
//
//  Created by Harsh Upadhyay on 24/10/2026.
//

import DevDeckKit
import SwiftUI

/// A non-interactive phone-frame mockup showing exactly what the deck
/// looks like on a paired phone, using the same DeckGridView the iOS app
/// renders.
struct PhonePreview: View {
    let actions: [DeckAction]

    var body: some View {
        VStack(spacing: 12) {
            Text("Preview")
                .font(.headline)
                .foregroundStyle(.secondary)

            RoundedRectangle(cornerRadius: 44)
                .fill(.background)
                .overlay(
                    DeckGridView(actions: actions)
                        .disabled(true)
                        .clipShape(RoundedRectangle(cornerRadius: 36))
                        .padding(8)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 44)
                        .strokeBorder(.secondary.opacity(0.4), lineWidth: 8)
                )
                .aspectRatio(9.0 / 19.5, contentMode: .fit)
                .frame(maxWidth: 320)
                .shadow(radius: 12, y: 6)
        }
        .padding()
    }
}

#Preview {
    PhonePreview(actions: DeckAction.previewActions)
}
