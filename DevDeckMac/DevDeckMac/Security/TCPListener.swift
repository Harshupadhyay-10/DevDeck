//
//  TCPListener.swift
//  DevDeckMac
//
//  Created by Harsh Upadhyay on 02/11/2026.
//

import DevDeckKit
import Foundation

/// Listens for incoming connections using raw POSIX sockets instead of
/// Network.framework's NWListener, to match the client's TCPConnection
/// and avoid whatever made NWConnection unreliable in testing.
final class TCPListener {
    enum ListenerError: Error {
        case socketCreationFailed
        case bindFailed
        case listenFailed
    }

    private(set) var port: UInt16 = 0
    private var fd: Int32 = -1
    private var acceptThread: Thread?

    func start(onAccept: @escaping (TCPConnection) -> Void) throws {
        let newFd = socket(AF_INET, SOCK_STREAM, 0)
        guard newFd >= 0 else { throw ListenerError.socketCreationFailed }

        var reuse: Int32 = 1
        setsockopt(newFd, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout<Int32>.size))

        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_addr.s_addr = INADDR_ANY
        addr.sin_port = 0

        let bindResult = withUnsafePointer(to: &addr) { ptr -> Int32 in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                bind(newFd, sockaddrPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard bindResult == 0 else {
            close(newFd)
            throw ListenerError.bindFailed
        }

        var boundAddr = sockaddr_in()
        var len = socklen_t(MemoryLayout<sockaddr_in>.size)
        let gotName = withUnsafeMutablePointer(to: &boundAddr) { ptr -> Int32 in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                getsockname(newFd, sockaddrPtr, &len)
            }
        }
        guard gotName == 0 else {
            close(newFd)
            throw ListenerError.bindFailed
        }
        port = UInt16(bigEndian: boundAddr.sin_port)

        guard listen(newFd, 8) == 0 else {
            close(newFd)
            throw ListenerError.listenFailed
        }

        fd = newFd

        let thread = Thread { [weak self] in
            self?.acceptLoop(onAccept: onAccept)
        }
        thread.name = "com.byHarshu.DevDeckMac.tcplistener"
        thread.start()
        acceptThread = thread
    }

    private func acceptLoop(onAccept: @escaping (TCPConnection) -> Void) {
        while true {
            let clientFd = accept(fd, nil, nil)
            if clientFd >= 0 {
                let connection = TCPConnection.wrapping(socketHandle: clientFd)
                onAccept(connection)
            } else if fd < 0 {
                break
            }
        }
    }

    func stop() {
        let fdToClose = fd
        fd = -1
        if fdToClose >= 0 {
            close(fdToClose)
        }
        acceptThread = nil
    }
}
