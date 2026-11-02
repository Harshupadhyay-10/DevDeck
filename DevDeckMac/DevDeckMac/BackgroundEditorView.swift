//
//  BackgroundEditorView.swift
//  DevDeckMac
//
//  Created by Harsh Upadhyay on 02/11/2026.
//

import AppKit
import DevDeckKit
import PhotosUI
import SwiftUI

/// Picks none/color/image for a background, reused by the per-tile
/// editor and the deck-wide background editor.
struct BackgroundEditorView: View {
    @Binding var background: TileStyle.Background
    @State private var pickedPhoto: PhotosPickerItem?

    private enum Kind: Hashable {
        case none, color, image
    }

    var body: some View {
        Group {
            Picker("Background", selection: kindBinding) {
                Text("None").tag(Kind.none)
                Text("Color").tag(Kind.color)
                Text("Image").tag(Kind.image)
            }

            switch background {
            case .none:
                EmptyView()
            case .color:
                SwatchColorPicker(title: "Background Color", selection: colorBinding)
            case .image(let data):
                HStack {
                    if !data.isEmpty, let nsImage = NSImage(data: data) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    PhotosPicker("Choose Image...", selection: $pickedPhoto, matching: .images)
                }
            }
        }
        .onChange(of: pickedPhoto) { _, newValue in
            guard let newValue else { return }
            Task {
                guard let data = try? await newValue.loadTransferable(type: Data.self),
                      let compressed = downscaledImageData(data) else { return }
                background = .image(compressed)
            }
        }
    }

    private var kindBinding: Binding<Kind> {
        Binding(
            get: {
                switch background {
                case .none: .none
                case .color: .color
                case .image: .image
                }
            },
            set: { kind in
                switch kind {
                case .none:
                    background = .none
                case .color:
                    background = .color(TileColor(.gray))
                case .image:
                    background = .image(Data())
                }
            }
        )
    }

    private var colorBinding: Binding<Color> {
        Binding(
            get: {
                if case .color(let tileColor) = background { return tileColor.color }
                return .gray
            },
            set: { background = .color(TileColor($0)) }
        )
    }
}

func downscaledImageData(_ data: Data, maxDimension: CGFloat = 300, quality: CGFloat = 0.7) -> Data? {
    guard let image = NSImage(data: data), image.size.width > 0, image.size.height > 0 else { return nil }

    let scale = maxDimension / min(image.size.width, image.size.height)
    let targetSize = NSSize(width: image.size.width * scale, height: image.size.height * scale)

    let resized = NSImage(size: targetSize)
    resized.lockFocus()
    image.draw(
        in: NSRect(origin: .zero, size: targetSize),
        from: NSRect(origin: .zero, size: image.size),
        operation: .copy,
        fraction: 1
    )
    resized.unlockFocus()

    guard let tiffData = resized.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }
    return bitmap.representation(using: .jpeg, properties: [.compressionFactor: quality])
}
