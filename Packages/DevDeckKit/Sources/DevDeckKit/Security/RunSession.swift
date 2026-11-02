import CryptoKit
import Foundation

/// Establishes an authenticated, encrypted session on an already-open
/// connection between two devices that paired previously. There is no
/// out-of-band secret this time, unlike pairing: trust comes from
/// already knowing the peer's long-term public key, and a fresh nonce
/// from each side keeps every session's derived key unique.
public enum RunSession {
    public enum HandshakeError: Error {
        case unknownPeer
        case confirmationFailed
    }

    /// Phone side: send our hello, receive the Mac's, derive the shared
    /// key, exchange confirmations. Fails if the Mac's public key
    /// doesn't match the one pinned when we paired with it.
    public static func authenticateAsClient(
        connection: TCPConnection,
        ourPrivateKey: Curve25519.KeyAgreement.PrivateKey,
        expectedPeerPublicKey: Data
    ) async throws -> SymmetricKey {
        let ourNonce = Data((0..<16).map { _ in UInt8.random(in: .min ... .max) })
        try await connection.send(RunHello(publicKey: ourPrivateKey.publicKey.rawRepresentation, nonce: ourNonce))

        let theirHello = try await connection.receive(RunHello.self)
        guard expectedPeerPublicKey == theirHello.publicKey else {
            throw HandshakeError.unknownPeer
        }

        let sessionKey = try PairingCrypto.sessionKey(
            ourPrivateKey: ourPrivateKey,
            theirPublicKeyData: theirHello.publicKey,
            outOfBandSecret: ourNonce + theirHello.nonce
        )

        let sealed = try PairingCrypto.seal(PairingConfirm.clientMagic, using: sessionKey)
        try await connection.send(PairingConfirm(sealed: sealed))

        let ack = try await connection.receive(PairingConfirm.self)
        guard try PairingCrypto.open(ack.sealed, using: sessionKey) == PairingConfirm.macMagic else {
            throw HandshakeError.confirmationFailed
        }

        return sessionKey
    }

    /// Mac side: receive the phone's hello, reject anything not already
    /// in the paired device list, send ours back, exchange
    /// confirmations.
    public static func authenticateAsServer(
        connection: TCPConnection,
        ourPrivateKey: Curve25519.KeyAgreement.PrivateKey,
        isPeerPaired: (Data) -> Bool
    ) async throws -> SymmetricKey {
        let theirHello = try await connection.receive(RunHello.self)
        guard isPeerPaired(theirHello.publicKey) else {
            throw HandshakeError.unknownPeer
        }

        let ourNonce = Data((0..<16).map { _ in UInt8.random(in: .min ... .max) })
        try await connection.send(RunHello(publicKey: ourPrivateKey.publicKey.rawRepresentation, nonce: ourNonce))

        let sessionKey = try PairingCrypto.sessionKey(
            ourPrivateKey: ourPrivateKey,
            theirPublicKeyData: theirHello.publicKey,
            outOfBandSecret: theirHello.nonce + ourNonce
        )

        let confirm = try await connection.receive(PairingConfirm.self)
        guard try PairingCrypto.open(confirm.sealed, using: sessionKey) == PairingConfirm.clientMagic else {
            throw HandshakeError.confirmationFailed
        }

        let ack = try PairingCrypto.seal(PairingConfirm.macMagic, using: sessionKey)
        try await connection.send(PairingConfirm(sealed: ack))

        return sessionKey
    }

    public static func send(_ message: some Encodable, on connection: TCPConnection, using key: SymmetricKey) async throws {
        let payload = try JSONEncoder().encode(message)
        let sealed = try PairingCrypto.seal(payload, using: key)
        try await connection.send(SecureEnvelope(sealed: sealed))
    }

    public static func receive<T: Decodable>(
        _ type: T.Type,
        from connection: TCPConnection,
        using key: SymmetricKey
    ) async throws -> T {
        let envelope = try await connection.receive(SecureEnvelope.self)
        let payload = try PairingCrypto.open(envelope.sealed, using: key)
        return try JSONDecoder().decode(T.self, from: payload)
    }
}
