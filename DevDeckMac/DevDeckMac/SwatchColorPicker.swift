//
//  SwatchColorPicker.swift
//  DevDeckMac
//
//  Created by Harsh Upadhyay on 02/11/2026.
//

import SwiftUI

/// A lightweight dropdown of preset color swatches, instead of macOS's
/// ColorPicker opening the full system color panel window for every
/// change. Falls back to that panel only if "Custom..." is chosen.
struct SwatchColorPicker: View {
    let title: String
    @Binding var selection: Color
    @State private var showingPopover = false

    private static let swatches: [Color] = [
        .red, .orange, .yellow, .green, .mint,
        .teal, .cyan, .blue, .indigo, .purple,
        .pink, .brown, .gray, .black, .white,
    ]

    var body: some View {
        Button {
            showingPopover = true
        } label: {
            HStack {
                Text(title)
                Spacer()
                Circle()
                    .fill(selection)
                    .frame(width: 18, height: 18)
                    .overlay(Circle().strokeBorder(.secondary.opacity(0.3)))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showingPopover) {
            VStack(spacing: 12) {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(28), spacing: 10), count: 5), spacing: 10) {
                    ForEach(Self.swatches, id: \.self) { color in
                        Button {
                            selection = color
                            showingPopover = false
                        } label: {
                            Circle()
                                .fill(color)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle().strokeBorder(.primary, lineWidth: selection == color ? 2 : 0)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Divider()

                ColorPicker("Custom...", selection: $selection, supportsOpacity: false)
            }
            .padding(16)
            .frame(width: 210)
        }
    }
}
