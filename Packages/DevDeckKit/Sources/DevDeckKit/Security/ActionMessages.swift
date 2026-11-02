import Foundation

/// The first message on an authenticated run connection: identity plus a
/// fresh nonce. Unlike pairing, there is no out-of-band secret here —
/// trust comes from each side's long-term key already being pinned from
/// pairing, and the nonces make every session's derived key unique.
public struct RunHello: Codable, Sendable {
    public let publicKey: Data
    public let nonce: Data

    public init(publicKey: Data, nonce: Data) {
        self.publicKey = publicKey
        self.nonce = nonce
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

    public init(actions: [DeckAction]) {
        self.actions = actions
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
