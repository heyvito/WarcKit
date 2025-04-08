//
//  HTTPServerIO.swift
//  WarcKit
//
//  Created by Vito Sartori on 09/04/25.
//

import Foundation
import Dispatch

protocol HttpServerIODelegate: AnyObject {
    func socketConnectionReceived(_ socket: Socket)
}

open class HttpServerIO {

    weak var delegate: HttpServerIODelegate?

    private var socket = Socket(socketFileDescriptor: -1)
    private var sockets = Set<Socket>()

    public enum HttpServerIOState: Int32 {
        case starting
        case running
        case stopping
        case stopped
    }

    private var stateValue: Int32 = HttpServerIOState.stopped.rawValue

    public private(set) var state: HttpServerIOState {
        get {
            return HttpServerIOState(rawValue: stateValue)!
        }
        set(state) {
            self.stateValue = state.rawValue
        }
    }

    public var operating: Bool { return self.state == .running }

    public var listenAddressIPv4: String?

    private let queue = DispatchQueue(label: "io.vito.warckit.replayer.httpServerIO")

    public func port() throws -> Int {
        return Int(try socket.port())
    }

    deinit {
        stop()
    }

    public func start(priority: DispatchQoS.QoSClass = DispatchQoS.QoSClass.userInitiated) throws {
        guard !self.operating else { return }
        stop()
        self.state = .starting
        self.socket = try Socket.createSocket(withMaxPendingConnections: SOMAXCONN)
        self.state = .running
        DispatchQueue.global(qos: priority).async { [weak self] in
            guard let strongSelf = self else { return }
            guard strongSelf.operating else { return }
            while let socket = try? strongSelf.socket.acceptClientSocket() {
                DispatchQueue.global(qos: priority).async { [weak self] in
                    guard let strongSelf = self else { return }
                    guard strongSelf.operating else { return }
                    strongSelf.queue.async {
                        strongSelf.sockets.insert(socket)
                    }

                    strongSelf.handleConnection(socket)

                    strongSelf.queue.async {
                        strongSelf.sockets.remove(socket)
                    }
                }
            }
            strongSelf.stop()
        }
    }

    public func stop() {
        guard self.operating else { return }
        self.state = .stopping

        self.sockets.forEach { $0.close() }

        self.queue.sync {
            self.sockets.removeAll(keepingCapacity: true)
        }

        socket.close()
        self.state = .stopped
    }

    func dispatch(_ request: HTTPRequest) async throws -> HTTPResponseWriter {
        return HTTPResponseWriter(headers: [], body: nil, status: .notFound)
    }

    private func handleConnection(_ socket: Socket) {
        let semaphore = DispatchSemaphore(value: 0)

        Task {
            defer { semaphore.signal() }
            let parser = HTTPParser()
            while self.operating, let request = try? parser.readHttpRequest(socket) {
                let request = request
                let resp = try await self.dispatch(request)
                var keepConnection = parser.supportsKeepAlive(request.headers)
                do {
                    if self.operating {
                        keepConnection = try self.respond(socket, response: resp, keepAlive: keepConnection)
                    }
                } catch {
                    print("Failed to send response: \(error)")
                }
                if !keepConnection { break }
            }
        }
        semaphore.wait()
        socket.close()
    }

    private func respond(_ socket: Socket, response: HTTPResponseWriter, keepAlive: Bool) throws -> Bool {
        guard self.operating else { return false }

        var responseHeader = [response.status.statusLine]

        for header in response.headers {
            responseHeader.append("\(header.0): \(header.1)")
        }

        if let body = response.body {
            if !response.headers.containsKey("Content-Length") {
                responseHeader.append("Content-Length: \(body.count)")
            }
            if keepAlive {
                responseHeader.append("Connection: keep-alive")
            }
        }

        try socket.writeUTF8(responseHeader.joined(separator: "\r\n") + "\r\n\r\n")

        if let body = response.body {
            try socket.writeData(body)
        }

        return keepAlive && response.body != nil
    }
}
