//
//  PhonePreview.swift
//  DevDeckMac
//
//  Created by Harsh Upadhyay on 24/10/2026.
//

import DevDeckKit
import SwiftUI

/// A non-interactive phone-frame mockup showing exactly what the deck
/// looks like on a paired phone, at the phone's actual screen
/// proportions and orientation as of the last sync (there is no
/// persistent connection, so it cannot track rotation live), using the
/// same DeckGridView and DeckBackgroundView the iOS app renders. The
/// header is hand-drawn rather than a real NavigationStack, since
/// nesting one this deeply breaks the grid's adaptive column layout.
struct PhonePreview: View {
    let actions: [DeckAction]
    var background: TileStyle.Background = .none
    var screen: DeviceScreenInfo?

    private var isLandscape: Bool {
        guard let screen else { return true }
        return screen.widthPoints > screen.heightPoints
    }

    private var aspectRatio: CGFloat {
        guard let screen, screen.heightPoints > 0 else { return 19.5 / 9.0 }
        return screen.widthPoints / screen.heightPoints
    }

    private var frameWidth: CGFloat {
        isLandscape ? 520 : 320
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Preview")
                .font(.headline)
                .foregroundStyle(.secondary)

            RoundedRectangle(cornerRadius: 44)
                .fill(.background)
                .overlay(
                    ZStack(alignment: .top) {
                        DeckBackgroundView(background)
                        VStack(spacing: 0) {
                            header
                            DeckGridView(actions: actions)
                                .allowsHitTesting(false)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 36))
                    .padding(8)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 44)
                        .strokeBorder(.secondary.opacity(0.4), lineWidth: 8)
                )
                .aspectRatio(aspectRatio, contentMode: .fit)
                .frame(maxWidth: frameWidth)
                .shadow(radius: 12, y: 6)

            Label("Shown as of the last sync. DevDeck is designed to be used in landscape.", systemImage: "rotate.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private var header: some View {
        HStack {
            Text("DevDeck")
                .font(.title.bold())
            Spacer()
            HStack(spacing: 16) {
                Image(systemName: "arrow.clockwise")
                Image(systemName: "wifi")
            }
            .font(.subheadline)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.thinMaterial, in: Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 4)
    }
}

#Preview {
    PhonePreview(actions: DeckAction.previewActions)
}
