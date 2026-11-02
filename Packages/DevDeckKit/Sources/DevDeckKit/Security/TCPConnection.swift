import Foundation

/// A minimal TCP connection built on classic Stream/CFStream sockets
/// instead of Network.framework's NWConnection. NWConnection proved
/// unreliable for local-network connections in testing (hanging even on
/// a direct IP, with no resolution involved) while plain BSD sockets to
/// the same host and port worked every time, so the whole pairing
/// transport goes through this instead.
public final class TCPConnection: @unchecked Sendable {
    public enum ConnectionError: Error {
        case connectFailed
        case readFailed
        case writeFailed
        case shortRead
        case messageTooLarge
    }

    private let input: InputStream
    private let output: OutputStream
    private let queue = DispatchQueue(label: "com.byHarshu.DevDeckKit.tcpconnection")
    private static let maxMessageLength = 64 * 1024

    private init(input: InputStream, output: OutputStream) {
        self.input = input
        self.output = output
    }

    /// Opens a connection to a concrete host and port. Never resolves a
    /// service name itself; callers already have a concrete address.
    public static func connect(host: String, port: UInt16, timeoutSeconds: Double = 10) async throws -> TCPConnection {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var inputStream: InputStream?
                var outputStream: OutputStream?
                Stream.getStreamsToHost(withName: host, port: Int(port), inputStream: &inputStream, outputStream: &outputStream)

                guard let input = inputStream, let output = outputStream else {
                    continuation.resume(throwing: ConnectionError.connectFailed)
                    return
                }

                input.open()
                output.open()

                let deadline = Date().addingTimeInterval(timeoutSeconds)
                while output.streamStatus == .opening && Date() < deadline {
                    Thread.sleep(forTimeInterval: 0.05)
                }

                guard output.streamStatus == .open else {
                    input.close()
                    output.close()
                    continuation.resume(throwing: ConnectionError.connectFailed)
                    return
                }

                continuation.resume(returning: TCPConnection(input: input, output: output))
            }
        }
    }

    /// Wraps an already-accepted server-side socket file descriptor.
    public static func wrapping(socketHandle: Int32) -> TCPConnection {
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        CFStreamCreatePairWithSocket(kCFAllocatorDefault, socketHandle, &readStream, &writeStream)

        let input = readStream!.takeRetainedValue() as InputStream
        let output = writeStream!.takeRetainedValue() as OutputStream
        CFReadStreamSetProperty(readStream!.takeUnretainedValue(), CFStreamPropertyKey(kCFStreamPropertyShouldCloseNativeSocket), kCFBooleanTrue)
        CFWriteStreamSetProperty(writeStream!.takeUnretainedValue(), CFStreamPropertyKey(kCFStreamPropertyShouldCloseNativeSocket), kCFBooleanTrue)

        input.open()
        output.open()
        return TCPConnection(input: input, output: output)
    }

    public func close() {
        input.close()
        output.close()
    }

    public func send(_ message: some Encodable) async throws {
        let payload = try JSONEncoder().encode(message)
        guard payload.count <= Self.maxMessageLength else { throw ConnectionError.messageTooLarge }

        let length = UInt32(payload.count)
        var framed = Data([
            UInt8((length >> 24) & 0xFF),
            UInt8((length >> 16) & 0xFF),
            UInt8((length >> 8) & 0xFF),
            UInt8(length & 0xFF),
        ])
        framed.append(payload)

        try await writeAll(framed)
    }

    public func receive<T: Decodable>(_ type: T.Type) async throws -> T {
        let header = try await readExact(4)
        let length = header.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
        guard length > 0, length <= Self.maxMessageLength else { throw ConnectionError.messageTooLarge }
        let payload = try await readExact(Int(length))
        return try JSONDecoder().decode(T.self, from: payload)
    }

    private func writeAll(_ data: Data) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async { [output] in
                var remaining = data
                while !remaining.isEmpty {
                    let bytesWritten = remaining.withUnsafeBytes { raw -> Int in
                        guard let base = raw.bindMemory(to: UInt8.self).baseAddress else { return -1 }
                        return output.write(base, maxLength: remaining.count)
                    }
                    guard bytesWritten > 0 else {
                        continuation.resume(throwing: ConnectionError.writeFailed)
                        return
                    }
                    remaining.removeFirst(bytesWritten)
                }
                continuation.resume()
            }
        }
    }

    private func readExact(_ count: Int) async throws -> Data {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
            queue.async { [input] in
                var buffer = Data()
                var temp = [UInt8](repeating: 0, count: count)
                while buffer.count < count {
                    let bytesRead = temp.withUnsafeMutableBytes { raw -> Int in
                        guard let base = raw.bindMemory(to: UInt8.self).baseAddress else { return -1 }
                        return input.read(base, maxLength: count - buffer.count)
                    }
                    guard bytesRead > 0 else {
                        continuation.resume(throwing: ConnectionError.readFailed)
                        return
                    }
                    buffer.append(contentsOf: temp.prefix(bytesRead))
                }
                continuation.resume(returning: buffer)
            }
        }
    }
}
