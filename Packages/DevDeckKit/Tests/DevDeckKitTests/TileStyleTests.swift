import Foundation
import Testing
@testable import DevDeckKit

@Test func deckActionDefaultsToGlassWithNoBackground() {
    let action = DeckAction(id: "pull", title: "Pull", systemImage: "arrow.down")
    #expect(action.style.material == .glass)
    #expect(action.style.background == .none)
    #expect(action.style.tintColor == nil)
}

@Test func tileStyleRoundTripsThroughJSONWithImageBackground() throws {
    let style = TileStyle(
        material: .solid,
        tintColor: TileColor(red: 0.2, green: 0.4, blue: 0.6, opacity: 1),
        background: .image(Data([0x01, 0x02, 0x03]))
    )
    let action = DeckAction(id: "build", title: "Build", systemImage: "hammer", style: style)

    let data = try JSONEncoder().encode(action)
    let decoded = try JSONDecoder().decode(DeckAction.self, from: data)

    #expect(decoded == action)
    #expect(decoded.style.material == .solid)
    #expect(decoded.style.background == .image(Data([0x01, 0x02, 0x03])))
}

@Test func tileColorRoundTripsThroughJSON() throws {
    let color = TileColor(red: 0.1, green: 0.2, blue: 0.3, opacity: 0.9)
    let data = try JSONEncoder().encode(color)
    let decoded = try JSONDecoder().decode(TileColor.self, from: data)
    #expect(decoded == color)
}
