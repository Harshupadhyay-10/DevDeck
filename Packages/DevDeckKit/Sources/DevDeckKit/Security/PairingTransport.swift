import Foundation

/// The Bonjour service types both apps advertise and browse for. Pairing
/// and running actions are kept as separate services: pairing only
/// advertises for as long as the Mac's pairing sheet is open, while the
/// run service advertises continuously whenever the Mac app is running.
public enum DevDeckService {
    public static let pairingType = "_devdeck._tcp."
    public static let runType = "_devdeckrun._tcp."
}

public struct PairingTimeout: Error {}

/// Races an operation against a deadline so a stalled connection fails
/// with a clear error instead of hanging indefinitely.
public func withPairingTimeout<T: Sendable>(
    seconds: Double,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask { try await operation() }
        group.addTask {
            try await Task.sleep(for: .seconds(seconds))
            throw PairingTimeout()
        }
        guard let result = try await group.next() else {
            throw PairingTimeout()
        }
        group.cancelAll()
        return result
    }
}
