import CryptoKit
import Foundation

/// Loads this device's long-term Curve25519 identity key from the
/// Keychain, generating and persisting one on first use. Used by both the
/// Mac and the phone; each keeps its own under its own service namespace.
public enum IdentityKeyStore {
    private static let account = "identity-key"

    public static func loadOrCreate(service: String) -> Curve25519.KeyAgreement.PrivateKey {
        if let data = try? KeychainStore.load(service: service, account: account),
           let key = try? Curve25519.KeyAgreement.PrivateKey(rawRepresentation: data) {
            return key
        }

        let key = Curve25519.KeyAgreement.PrivateKey()
        try? KeychainStore.save(key.rawRepresentation, service: service, account: account)
        return key
    }
}
