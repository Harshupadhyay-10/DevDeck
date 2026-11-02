import SwiftUI

/// Renders the deck-wide background behind the grid of tiles. Shared by
/// the iOS app and the macOS companion's live preview so both show the
/// same backdrop.
public struct DeckBackgroundView: View {
    private let background: TileStyle.Background

    public init(_ background: TileStyle.Background) {
        self.background = background
    }

    public var body: some View {
        switch background {
        case .none:
            Color.clear
        case .color(let tileColor):
            tileColor.color
        case .image(let data):
            if let image = decodedImage(data) {
                image.resizable().scaledToFill()
            } else {
                Color.clear
            }
        }
    }
}
