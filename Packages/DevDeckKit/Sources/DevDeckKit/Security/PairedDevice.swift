import Foundation

/// A device's pinned identity, as stored after a successful pairing. The
/// Mac stores one of these per paired phone; the phone stores one for its
/// paired Mac. Only the public key is kept here, never private material.
public struct PairedDevice: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public var displayName: String
    public let publicKeyData: Data
    public let pairedAt: Date

    public init(id: String, displayName: String, publicKeyData: Data, pairedAt: Date) {
        self.id = id
        self.displayName = displayName
        self.publicKeyData = publicKeyData
        self.pairedAt = pairedAt
    }
}
