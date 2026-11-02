//
//  BonjourAdvertiser.swift
//  DevDeckMac
//
//  Created by Harsh Upadhyay on 02/11/2026.
//

import DevDeckKit
import Foundation

/// Advertises this Mac's pairing service using the classic NetService
/// Bonjour API, not Network.framework's NWListener.service, to keep
/// discovery on a separate, independently-working code path from the
/// connection itself.
final class BonjourAdvertiser: NSObject {
    private var service: NetService?

    func publish(name: String, port: UInt16, txtRecord: Data) {
        stop()
        let newService = NetService(domain: "local.", type: DevDeckService.type, name: name, port: Int32(port))
        newService.delegate = self
        _ = newService.setTXTRecord(txtRecord)
        newService.publish()
        service = newService
    }

    func stop() {
        service?.stop()
        service = nil
    }
}

extension BonjourAdvertiser: NetServiceDelegate {}
