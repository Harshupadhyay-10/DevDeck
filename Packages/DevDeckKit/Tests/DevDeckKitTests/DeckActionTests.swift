import Foundation
import Testing
@testable import DevDeckKit

@Test func deckActionRoundTripsThroughJSON() throws {
    let action = DeckAction(id: "build", title: "Build", systemImage: "hammer", isDestructive: true)
    let data = try JSONEncoder().encode(action)
    let decoded = try JSONDecoder().decode(DeckAction.self, from: data)
    #expect(decoded == action)
}

@Test func deckActionDefaultsToNonDestructive() {
    let action = DeckAction(id: "pull", title: "Pull", systemImage: "arrow.down")
    #expect(action.isDestructive == false)
}
