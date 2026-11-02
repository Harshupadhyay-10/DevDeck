import Foundation
import Observation

/// Keeps the list of paired devices in the Keychain, scoped by a service
/// namespace so the Mac's "paired phones" and a phone's "paired Mac" never
/// collide. Each device is one Keychain item, keyed by its id.
@Observable
public final class PairedDeviceStore {
    public private(set) var devices: [PairedDevice] = []

    private let service: String

    public init(service: String) {
        self.service = service
        reload()
    }

    public func reload() {
        let accounts = (try? KeychainStore.allAccounts(service: service)) ?? []
        devices = accounts.compactMap { account in
            guard let data = try? KeychainStore.load(service: service, account: account) else {
                return nil
            }
            return try? JSONDecoder().decode(PairedDevice.self, from: data)
        }
        .sorted { $0.pairedAt < $1.pairedAt }
    }

    public func save(_ device: PairedDevice) {
        guard let data = try? JSONEncoder().encode(device) else { return }
        try? KeychainStore.save(data, service: service, account: device.id)
        reload()
    }

    public func remove(_ device: PairedDevice) {
        try? KeychainStore.delete(service: service, account: device.id)
        reload()
    }
}
