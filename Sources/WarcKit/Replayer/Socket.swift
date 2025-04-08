//
//  Socket.swift
//  WarcKit
//
//  Created by Vito Sartori on 09/04/25.
//
// Copyright (c) 2014, Damian Kołakowski
// Copyright (c) 2025, Vito Sartori
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.
//
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
//
// * Neither the name of the {organization} nor the names of its
//   contributors may be used to endorse or promote products derived from
//   this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import Foundation

public enum SocketError: Error {
    case socketCreationFailed(String)
    case socketSettingReUseAddrFailed(String)
    case bindFailed(String)
    case listenFailed(String)
    case writeFailed(String)
    case getPeerNameFailed(String)
    case convertingPeerNameFailed
    case getNameInfoFailed(String)
    case acceptFailed(String)
    case recvFailed(String)
    case getSockNameFailed(String)
}

class Socket: Hashable, Equatable {
    let socketFileDescriptor: Int32
    private var shutdown = false

    public init(socketFileDescriptor: Int32) {
        self.socketFileDescriptor = socketFileDescriptor
    }

    deinit {
        close()
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.socketFileDescriptor)
    }

    public func close() {
        guard !shutdown else {
            return
        }

        shutdown = true
        Socket.close(self.socketFileDescriptor)
    }

    public func port() throws -> in_port_t {
        var addr = sockaddr_in()
        return try withUnsafePointer(to: &addr) { pointer in
            var len = socklen_t(MemoryLayout<sockaddr_in>.size)
            if getsockname(
                socketFileDescriptor,
                UnsafeMutablePointer(OpaquePointer(pointer)),
                &len
            ) != 0 {
                throw SocketError.getSockNameFailed(Errno.description())
            }
            let sin_port = pointer.pointee.sin_port
            return Int(OSHostByteOrder()) != OSLittleEndian
                ? sin_port.littleEndian : sin_port.bigEndian
        }
    }

    public func writeUTF8(_ string: String) throws {
        try writeData(Data(ArraySlice(string.utf8)))
    }

    public func writeData(_ data: NSData) throws {
        try writeBuffer(data.bytes, length: data.length)
    }

    public func writeData(_ data: Data) throws {
        try data.withUnsafeBytes { (body: UnsafeRawBufferPointer) -> Void in
            if let baseAddress = body.baseAddress, body.count > 0 {
                let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
                try self.writeBuffer(pointer, length: data.count)
            }
        }
    }

    private func writeBuffer(_ pointer: UnsafeRawPointer, length: Int) throws {
        var sent = 0
        while sent < length {
            let result = write(
                self.socketFileDescriptor,
                pointer + sent,
                Int(length - sent)
            )
            if result <= 0 {
                throw SocketError.writeFailed(Errno.description())
            }
            sent += result
        }
    }

    open func read() throws -> UInt8 {
        var byte: UInt8 = 0
        let count = Darwin.read(self.socketFileDescriptor as Int32, &byte, 1)

        guard count > 0 else {
            throw SocketError.recvFailed(Errno.description())
        }
        return byte
    }

    open func read(length: Int) throws -> [UInt8] {
        return try [UInt8](unsafeUninitializedCapacity: length) {
            buffer,
            bytesRead in
            bytesRead = try read(into: &buffer, length: length)
        }
    }

    static let kBufferLength = 1024

    func read(into buffer: inout UnsafeMutableBufferPointer<UInt8>, length: Int)
        throws -> Int
    {
        var offset = 0
        guard let baseAddress = buffer.baseAddress else { return 0 }

        while offset < length {
            // Compute next read length in bytes. The bytes read is never more than kBufferLength at once.
            let readLength =
                offset + Socket.kBufferLength < length
                ? Socket.kBufferLength : length - offset
            let bytesRead = Darwin.read(
                self.socketFileDescriptor as Int32,
                baseAddress + offset,
                readLength
            )

            guard bytesRead > 0 else {
                throw SocketError.recvFailed(Errno.description())
            }

            offset += bytesRead
        }

        return offset
    }

    private static let CR: UInt8 = 13
    private static let NL: UInt8 = 10

    public func readLine() throws -> String {
        var characters: String = ""
        var index: UInt8 = 0
        repeat {
            index = try self.read()
            if index > Socket.CR {
                characters.append(Character(UnicodeScalar(index)))
            }
        } while index != Socket.NL
        return characters
    }

    public func peername() throws -> String {
        var addr = sockaddr()
        var len: socklen_t = socklen_t(MemoryLayout<sockaddr>.size)
        if getpeername(self.socketFileDescriptor, &addr, &len) != 0 {
            throw SocketError.getPeerNameFailed(Errno.description())
        }
        var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        if getnameinfo(
            &addr,
            len,
            &hostBuffer,
            socklen_t(hostBuffer.count),
            nil,
            0,
            NI_NUMERICHOST
        ) != 0 {
            throw SocketError.getNameInfoFailed(Errno.description())
        }
        return String(cString: hostBuffer)
    }

    public class func setNoSigPipe(_ socket: Int32) {
        // Prevents crashes when blocking calls are pending and the app is paused ( via Home button ).
        var no_sig_pipe: Int32 = 1
        setsockopt(
            socket,
            SOL_SOCKET,
            SO_NOSIGPIPE,
            &no_sig_pipe,
            socklen_t(MemoryLayout<Int32>.size)
        )
    }

    public class func close(_ socket: Int32) {
        _ = Darwin.close(socket)
    }
}

func == (socket1: Socket, socket2: Socket) -> Bool {
    return socket1.socketFileDescriptor == socket2.socketFileDescriptor
}
