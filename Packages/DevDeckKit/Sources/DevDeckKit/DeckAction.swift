import Foundation

/// A single button on the deck. This is a display-only description of an
/// action, defined on the Mac, that the phone shows and asks to run by
/// `id`. It never carries a command to execute.
public struct DeckAction: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public var title: String
    public var systemImage: String
    public var isDestructive: Bool

    public init(id: String, title: String, systemImage: String, isDestructive: Bool = false) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.isDestructive = isDestructive
    }
}

extension DeckAction {
    /// Sample actions for previews and early UI work, before the Mac side
    /// has real action storage.
    public static let previewActions: [DeckAction] = [
        DeckAction(id: "build", title: "Build", systemImage: "hammer"),
        DeckAction(id: "test", title: "Test", systemImage: "checkmark.circle"),
        DeckAction(id: "git-pull", title: "Pull", systemImage: "arrow.down.circle"),
        DeckAction(id: "git-push", title: "Push", systemImage: "arrow.up.circle"),
        DeckAction(id: "lock", title: "Lock Mac", systemImage: "lock"),
        DeckAction(id: "clean", title: "Clean", systemImage: "trash", isDestructive: true),
    ]
}
