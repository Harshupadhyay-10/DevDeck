import Foundation

/// A phone's screen size in points, so the Mac's live preview can show
/// the deck at the paired phone's actual proportions instead of a
/// generic guess.
public struct DeviceScreenInfo: Codable, Hashable, Sendable {
    public let widthPoints: Double
    public let heightPoints: Double

    public init(widthPoints: Double, heightPoints: Double) {
        self.widthPoints = widthPoints
        self.heightPoints = heightPoints
    }
}

/// The first message on an authenticated run connection: identity plus a
/// fresh nonce. Unlike pairing, there is no out-of-band secret here —
/// trust comes from each side's long-term key already being pinned from
/// pairing, and the nonces make every session's derived key unique.
public struct RunHello: Codable, Sendable {
    public let publicKey: Data
    public let nonce: Data
    public let deviceScreen: DeviceScreenInfo?

    public init(publicKey: Data, nonce: Data, deviceScreen: DeviceScreenInfo? = nil) {
        self.publicKey = publicKey
        self.nonce = nonce
        self.deviceScreen = deviceScreen
    }
}

/// A generic encrypted envelope for everything exchanged after the
/// session key is confirmed. The inner JSON is never sent in the clear.
public struct SecureEnvelope: Codable, Sendable {
    public let sealed: Data

    public init(sealed: Data) {
        self.sealed = sealed
    }
}

/// The Mac's current action list, sent after every successful
/// authentication so the phone never shows a stale or sample deck.
public struct DeckSyncMessage: Codable, Sendable {
    public let actions: [DeckAction]
    public let background: TileStyle.Background

    public init(actions: [DeckAction], background: TileStyle.Background = .none) {
        self.actions = actions
        self.background = background
    }
}

/// Asks the Mac to run one action, identified only by id, never a
/// command string.
public struct RunActionRequest: Codable, Sendable {
    public let actionID: String

    public init(actionID: String) {
        self.actionID = actionID
    }
}

public struct RunActionResult: Codable, Sendable {
    public let actionID: String
    public let succeeded: Bool
    public let errorMessage: String?

    public init(actionID: String, succeeded: Bool, errorMessage: String? = nil) {
        self.actionID = actionID
        self.succeeded = succeeded
        self.errorMessage = errorMessage
    }
}
