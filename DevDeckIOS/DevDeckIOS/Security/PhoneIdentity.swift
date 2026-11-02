//
//  PhoneIdentity.swift
//  DevDeckIOS
//
//  Created by Harsh Upadhyay on 29/10/2026.
//

import CryptoKit
import DevDeckKit
import UIKit

/// This phone's long-term pairing identity: a Curve25519 key kept in the
/// Keychain, and a human-readable name shown to the Mac during pairing.
enum PhoneIdentity {
    static let keychainService = "com.byHarshu.DevDeckIOS.identity"
    static let pairedMacsService = "com.byHarshu.DevDeckIOS.paired-macs"

    static let privateKey: Curve25519.KeyAgreement.PrivateKey = IdentityKeyStore.loadOrCreate(service: keychainService)

    static var displayName: String {
        UIDevice.current.name
    }
}
