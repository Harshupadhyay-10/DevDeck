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

    var body: some View {
        if action.isDestructive {
            button.buttonStyle(.glassProminent).tint(.red)
        } else {
            button.buttonStyle(.glass).tint(.accentColor)
        }
    }

    private var button: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: action.systemImage)
                    .font(.system(size: 32, weight: .medium))
                    .frame(height: 36)
                Text(action.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
        }
    }
}

#Preview {
    DeckGridView(actions: DeckAction.previewActions)
}
