//
//  BonjourBrowser.swift
//  DevDeckIOS
//
//  Created by Harsh Upadhyay on 02/11/2026.
//

import DevDeckKit
import Foundation

/// Finds nearby Macs using the classic NetServiceBrowser Bonjour API,
/// not Network.framework's NWBrowser, to keep discovery on a separate,
/// independently-working code path from the connection itself. Reads
/// each Mac's host/port from its TXT record via monitoring, which does
/// not require a full connection-based resolve.
final class BonjourBrowser: NSObject {
    private let browser = NetServiceBrowser()
    private var services: [String: NetService] = [:]
    private var hostPorts: [String: (host: String, port: UInt16)] = [:]

    var onUpdate: (([String: (host: String, port: UInt16)]) -> Void)?

    func start() {
        stop()
        browser.delegate = self
        browser.searchForServices(ofType: DevDeckService.type, inDomain: "local.")
    }

    func stop() {
        browser.stop()
        for service in services.values {
            service.stop()
        }
        services.removeAll()
        hostPorts.removeAll()
    }
}

extension BonjourBrowser: NetServiceBrowserDelegate {
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        services[service.name] = service
        service.delegate = self
        service.startMonitoring()
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        services.removeValue(forKey: service.name)
        hostPorts.removeValue(forKey: service.name)
        onUpdate?(hostPorts)
    }
}

extension BonjourBrowser: NetServiceDelegate {
    func netService(_ sender: NetService, didUpdateTXTRecord data: Data) {
        guard let hostPort = PairingTXTRecord.decode(data) else { return }
        hostPorts[sender.name] = hostPort
        onUpdate?(hostPorts)
    }
}
