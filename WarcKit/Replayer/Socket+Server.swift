//
//  Socket+Server.swift
//  WarcKit
//
//  Created by Vito Sartori on 09/04/25.
//

import Foundation

extension Socket {
    public class func createSocket(
        withMaxPendingConnections maxPendingConnection: Int32 = SOMAXCONN,
        andListenAddress listenAddress: String? = nil
    ) throws -> Socket {
        let socketFileDescriptor = socket(
            AF_INET,
            SOCK_STREAM,
            0
        )

        if socketFileDescriptor == -1 {
            throw SocketError.socketCreationFailed(Errno.description())
        }

        var value: Int32 = 1
        if setsockopt(
            socketFileDescriptor,
            SOL_SOCKET,
            SO_REUSEADDR,
            &value,
            socklen_t(MemoryLayout<Int32>.size)
        ) == -1 {
            let details = Errno.description()
            Socket.close(socketFileDescriptor)
            throw SocketError.socketSettingReUseAddrFailed(details)
        }
        Socket.setNoSigPipe(socketFileDescriptor)

        var bindResult: Int32 = -1
        var addr = sockaddr_in(
            sin_len: UInt8(MemoryLayout<sockaddr_in>.stride),
            sin_family: UInt8(AF_INET),
            sin_port: UInt16(0).bigEndian,
            sin_addr: in_addr(s_addr: in_addr_t(0)),
            sin_zero: (0, 0, 0, 0, 0, 0, 0, 0)
        )

        bindResult = withUnsafePointer(to: &addr) {
            bind(
                socketFileDescriptor,
                UnsafePointer<sockaddr>(OpaquePointer($0)),
                socklen_t(MemoryLayout<sockaddr_in>.size)
            )
        }

        if bindResult == -1 {
            let details = Errno.description()
            Socket.close(socketFileDescriptor)
            throw SocketError.bindFailed(details)
        }

        if listen(socketFileDescriptor, maxPendingConnection) == -1 {
            let details = Errno.description()
            Socket.close(socketFileDescriptor)
            throw SocketError.listenFailed(details)
        }

        return Socket(socketFileDescriptor: socketFileDescriptor)
    }

    public func acceptClientSocket() throws -> Socket {
        var addr = sockaddr()
        var len: socklen_t = 0
        let clientSocket = accept(self.socketFileDescriptor, &addr, &len)
        if clientSocket == -1 {
            throw SocketError.acceptFailed(Errno.description())
        }
        Socket.setNoSigPipe(clientSocket)
        return Socket(socketFileDescriptor: clientSocket)
    }
}
