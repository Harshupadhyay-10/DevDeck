import Foundation

/// What the Mac's QR code encodes: enough for the phone to find and
/// connect to the right Mac and to complete the key exchange, without
/// anything secret going over the network. Carries the Mac's own
/// host/port directly rather than relying on the phone resolving the
/// Bonjour service itself, which has proven unreliable on some networks.
public struct PairingQRPayload: Codable, Sendable {
    public let macPublicKey: Data
    public let token: Data
    public let serviceName: String
    public let macDisplayName: String
    public let host: String
    public let port: UInt16

    public init(
        macPublicKey: Data,
        token: Data,
        serviceName: String,
        macDisplayName: String,
        host: String,
        port: UInt16
    ) {
        self.macPublicKey = macPublicKey
        self.token = token
        self.serviceName = serviceName
        self.macDisplayName = macDisplayName
        self.host = host
        self.port = port
    }
}

/// The first plaintext message sent by either side: identity only, never
/// secret. Trust comes from the confirmation that follows, not from this.
public struct PairingHello: Codable, Sendable {
    public let publicKey: Data
    public let displayName: String

    public init(publicKey: Data, displayName: String) {
        self.publicKey = publicKey
        self.displayName = displayName
    }
}

/// Proves the sender derived the same session key, which only happens if
/// it knew the out-of-band secret (QR token or PIN). AES-GCM's built-in
/// authentication does the proving; there is no separate MAC step.
public struct PairingConfirm: Codable, Sendable {
    public let sealed: Data

    public init(sealed: Data) {
        self.sealed = sealed
    }

    public static let clientMagic = Data("devdeck-pairing-confirm-v1".utf8)
    public static let macMagic = Data("devdeck-pairing-ack-v1".utf8)
}
