import Foundation

/// The Bonjour service type both apps advertise and browse for.
public enum DevDeckService {
    public static let type = "_devdeck._tcp."
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
