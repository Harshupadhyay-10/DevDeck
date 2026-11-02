//
//  LocalNetwork.swift
//  DevDeckMac
//
//  Created by Harsh Upadhyay on 29/10/2026.
//

import Foundation

/// Finds this Mac's own LAN IPv4 address so pairing can hand it to the
/// phone directly instead of relying on the phone resolving it itself,
/// which has proven unreliable on some networks.
enum LocalNetwork {
    static func primaryIPv4Address() -> String? {
        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrPtr) == 0, let firstAddr = ifaddrPtr else { return nil }
        defer { freeifaddrs(ifaddrPtr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            guard interface.ifa_addr.pointee.sa_family == UInt8(AF_INET) else { continue }

            let name = String(cString: interface.ifa_name)
            guard name.hasPrefix("en") else { continue }

            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let status = getnameinfo(
                interface.ifa_addr,
                socklen_t(interface.ifa_addr.pointee.sa_len),
                &hostname,
                socklen_t(hostname.count),
                nil,
                0,
                NI_NUMERICHOST
            )
            guard status == 0 else { continue }

            let address = String(cString: hostname)
            if address != "127.0.0.1" {
                return address
            }
        }
        return nil
    }
}
