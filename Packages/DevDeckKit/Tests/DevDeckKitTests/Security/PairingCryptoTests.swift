import CryptoKit
import Foundation
import Testing
@testable import DevDeckKit

@Test func matchingSecretsDeriveTheSameSessionKey() throws {
    let alice = Curve25519.KeyAgreement.PrivateKey()
    let bob = Curve25519.KeyAgreement.PrivateKey()
    let secret = Data("shared-secret".utf8)

    let aliceKey = try PairingCrypto.sessionKey(
        ourPrivateKey: alice,
        theirPublicKeyData: bob.publicKey.rawRepresentation,
        outOfBandSecret: secret
    )
    let bobKey = try PairingCrypto.sessionKey(
        ourPrivateKey: bob,
        theirPublicKeyData: alice.publicKey.rawRepresentation,
        outOfBandSecret: secret
    )

    #expect(aliceKey == bobKey)
}

@Test func differentSecretsDeriveDifferentSessionKeys() throws {
    let alice = Curve25519.KeyAgreement.PrivateKey()
    let bob = Curve25519.KeyAgreement.PrivateKey()

    let aliceKey = try PairingCrypto.sessionKey(
        ourPrivateKey: alice,
        theirPublicKeyData: bob.publicKey.rawRepresentation,
        outOfBandSecret: Data("correct-secret".utf8)
    )
    let bobKey = try PairingCrypto.sessionKey(
        ourPrivateKey: bob,
        theirPublicKeyData: alice.publicKey.rawRepresentation,
        outOfBandSecret: Data("wrong-secret".utf8)
    )

    #expect(aliceKey != bobKey)
}

@Test func sealedMessageOpensWithTheSameKey() throws {
    let key = SymmetricKey(size: .bits256)
    let message = Data("devdeck-pairing-confirm-v1".utf8)

    let sealed = try PairingCrypto.seal(message, using: key)
    let opened = try PairingCrypto.open(sealed, using: key)

    #expect(opened == message)
}

@Test func sealedMessageFailsToOpenWithAWrongKey() throws {
    let message = Data("devdeck-pairing-confirm-v1".utf8)
    let sealed = try PairingCrypto.seal(message, using: SymmetricKey(size: .bits256))

    #expect(throws: (any Error).self) {
        try PairingCrypto.open(sealed, using: SymmetricKey(size: .bits256))
    }
}
