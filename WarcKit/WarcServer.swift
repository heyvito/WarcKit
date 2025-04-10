//
//  WarcServer.swift
//  WarcKit
//
//  Created by Vito Sartori on 10/04/25.
//

import Foundation

// WarcServer is a simple HTTP server that only supports GET requests
// in the following format: /<hostname>[/[path][?query]]. It then locates
// a matching index entry, and returns the archived data for it.
class WarcServer {
    private var server: HTTPServer? = nil
    private var index: CDXJItemCollection!
    private var warc: WarcIO!

    init(indexPath: URL, archivePath: URL) async throws {
        self.index = try CDXJParser.parse(data: try Data(contentsOf: indexPath))
        self.warc = try await WarcIO(data: try Data(contentsOf: archivePath))
    }

    deinit {
        stop()
    }

    func port() throws -> Int { try server?.port() ?? 0 }

    func start() throws {
        stop()

        server = HTTPServer()
        server?.requestDelegate = self
        server?.notFoundHandler = { _ in
            var resp = HTTPResponseWriter()
            resp.status = .notFound
            resp.setBody("Not Found")
            return resp
        }
        try server?.start()
    }

    func stop() {
        if let srv = server {
            srv.stop()
        }
        server = nil
    }
}

extension WarcServer: HTTPServerDelegate {
    func handleRequest(_ request: HTTPRequest, withResponse response: inout HTTPResponseWriter) async throws {
        guard let indexItem = index.byURL(String(request.rawPath.trimmingPrefix(try! Regex("^/")))) else {
            response.setStatus(.notFound)
            response.setBody("Not Found")
            return
        }
        debugPrint("Get: \(indexItem)")
        response.status = .ok
        response.setBody("OK")
    }
}
