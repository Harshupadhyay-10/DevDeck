import Foundation

/// A minimal DNS-SD TXT record carrying the Mac's host and port, so the
/// phone can connect directly to a concrete address from a Bonjour browse
/// result instead of letting NWConnection resolve the service itself,
/// which has proven unreliable on some networks.
public enum PairingTXTRecord {
    public static func encode(host: String, port: UInt16) -> Data {
        var data = Data()
        for entry in ["host=\(host)", "port=\(port)"] {
            let bytes = Array(entry.utf8)
            data.append(UInt8(min(bytes.count, 255)))
            data.append(contentsOf: bytes.prefix(255))
        }
        return data
    }

    public static func decode(_ data: Data) -> (host: String, port: UInt16)? {
        var entries: [String: String] = [:]
        var index = data.startIndex
        while index < data.endIndex {
            let length = Int(data[index])
            index = data.index(after: index)
            guard length > 0, let end = data.index(index, offsetBy: length, limitedBy: data.endIndex) else { break }
            if let entry = String(bytes: data[index..<end], encoding: .utf8) {
                let parts = entry.split(separator: "=", maxSplits: 1)
                if parts.count == 2 {
                    entries[String(parts[0])] = String(parts[1])
                }
            }
            index = end
        }
        guard let host = entries["host"], let portString = entries["port"], let port = UInt16(portString) else {
            return nil
        }
        return (host, port)
    }
}
