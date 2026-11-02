import CryptoKit
import Foundation

/// Cryptographic primitives for pairing: Curve25519 key agreement, HKDF to
/// derive a session key, AES-GCM to encrypt the handshake confirmation.
/// Standard, well-known constructions built only from CryptoKit; nothing
/// here is an invented protocol.
public enum PairingCrypto {
    public enum CryptoError: Error {
        case sealFailed
        case invalidPublicKey
    }

    /// Derives a session key from a completed ECDH exchange, bound to a
    /// secret shared out of band (the QR token or the manual PIN). A wrong
    /// secret yields a different key, so messages sealed with it will fail
    /// to open rather than silently succeeding.
    public static func sessionKey(
        ourPrivateKey: Curve25519.KeyAgreement.PrivateKey,
        theirPublicKeyData: Data,
        outOfBandSecret: Data
    ) throws -> SymmetricKey {
        let theirPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: theirPublicKeyData)
        let shared = try ourPrivateKey.sharedSecretFromKeyAgreement(with: theirPublicKey)
        return shared.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: outOfBandSecret,
            sharedInfo: Data("DevDeck-pairing-v1".utf8),
            outputByteCount: 32
        )
    }

    public static func seal(_ data: Data, using key: SymmetricKey) throws -> Data {
        let sealed = try AES.GCM.seal(data, using: key)
        guard let combined = sealed.combined else {
            throw CryptoError.sealFailed
        }
        return combined
    }

    public static func open(_ data: Data, using key: SymmetricKey) throws -> Data {
        let box = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(box, using: key)
    }
}
