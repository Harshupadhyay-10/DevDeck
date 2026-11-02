//
//  MacIdentity.swift
//  DevDeckMac
//
//  Created by Harsh Upadhyay on 29/10/2026.
//

import CryptoKit
import DevDeckKit
import Foundation

/// This Mac's long-term pairing identity: a Curve25519 key kept in the
/// Keychain, and a human-readable name shown to phones during pairing.
enum MacIdentity {
    static let keychainService = "com.byHarshu.DevDeckMac.identity"
    static let pairedDevicesService = "com.byHarshu.DevDeckMac.paired-devices"

    static let privateKey: Curve25519.KeyAgreement.PrivateKey = IdentityKeyStore.loadOrCreate(service: keychainService)

    static var displayName: String {
        Host.current().localizedName ?? "My Mac"
    }
}
