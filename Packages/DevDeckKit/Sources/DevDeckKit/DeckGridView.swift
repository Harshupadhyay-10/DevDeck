import SwiftUI

/// The grid of deck buttons, shared between the iOS app and the macOS
/// companion's live preview so both render the deck identically.
public struct DeckGridView: View {
    private let actions: [DeckAction]
    private let onTap: (DeckAction) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 220), spacing: 16)
    ]

    public init(actions: [DeckAction], onTap: @escaping (DeckAction) -> Void = { _ in }) {
        self.actions = actions
        self.onTap = onTap
    }

    public var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(actions) { action in
                    DeckButton(action: action) {
                        onTap(action)
                    }
                }
            }
            .padding(16)
        }
    }
}

private struct DeckButton: View {
    let action: DeckAction
    let onTap: () -> Void

    private var tint: Color {
        action.style.tintColor?.color ?? (action.isDestructive ? .red : .accentColor)
    }

    var body: some View {
        switch action.style.material {
        case .glass:
            glassButton
        case .solid:
            solidButton
        }
    }

    @ViewBuilder
    private var glassButton: some View {
        if action.isDestructive {
            Button(action: onTap) { label }
                .buttonStyle(.glassProminent)
                .tint(tint)
        } else {
            Button(action: onTap) { label }
                .buttonStyle(.glass)
                .tint(tint)
        }
    }

    private var solidButton: some View {
        Button(action: onTap) {
            label.foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .background(solidBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    @ViewBuilder
    private var solidBackground: some View {
        switch action.style.background {
        case .none:
            tint
        case .color(let tileColor):
            tileColor.color
        case .image(let data):
            if let image = decodedImage(data) {
                image.resizable().scaledToFill()
            } else {
                tint
            }
        }
    }

    private var label: some View {
        VStack(spacing: 12) {
            Image(systemName: action.systemImage)
                .font(.system(size: 32, weight: .medium))
                .frame(height: 36)
            Text(action.title)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    DeckGridView(actions: DeckAction.previewActions)
}
