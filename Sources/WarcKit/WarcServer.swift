//
//  WarcServer.swift
//  WarcKit
//
//  Created by Vito Sartori on 10/04/25.
//

import Foundation
internal import SwiftSoup

// WarcServer is a simple HTTP server that only supports GET requests
// in the following format: /<hostname>[/[path][?query]]. It then locates
// a matching index entry, and returns the archived data for it.
open class WarcServer {
    private var server: HTTPServer? = nil
    private var index: CDXJItemCollection!
    private var warc: WarcIO!
    private var allURLS: [String]

    public convenience init(indexPath: URL, archivePath: URL) async throws {
        try await self.init(
            index: try Data(contentsOf: indexPath),
            archive: try Data(contentsOf: archivePath))
    }
    
    public init(index: Data, archive: Data) async throws {
        self.index = try CDXJParser.parse(data: index)
        self.warc = try await WarcIO(data: archive)
        self.allURLS = self.index.allURLS()
    }

    deinit {
        stop()
    }

    public func port() throws -> Int { try server?.port() ?? 0 }

    public func start() throws {
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

    public func stop() {
        if let srv = server {
            srv.stop()
        }
        server = nil
    }
}

extension WarcServer: HTTPServerDelegate {
    func handleHTMLRequest(_ data: Data, baseURL: String) throws -> Data {
        let patcher = WarcPatcher(baseURL: baseURL, allURLS: allURLS)
        return try patcher.patchHTML(data)
    }
    
    func handleCSSRequest(_ data: Data, baseURL: String) throws -> Data {
        guard let url = URL(string: baseURL) else { return Data() }
        let clearURL = url.relativePath
        let patcher = StylesheetPatcher(data, stylesheetPath: clearURL, baseURL: baseURL, allURLS: allURLS)
        return patcher.patch().data(using: .utf8)!
    }
    
    func handleRequest(_ request: HTTPRequest, withResponse response: inout HTTPResponseWriter) async throws {
        let url = String(request.rawPath.trimmingPrefix(try! Regex("^/")))
        guard let indexItem = index.byURL(url) else {
            response.setStatus(.notFound)
            response.setBody("Not Found")
            return
        }
        
        debugPrint("Request: \(url)")
        let rec = try await self.warc.readRecord(indexItem)
        var body = try await rec.getBody()
        
        if let ct = rec.contentType {
            if ct.contains("text/html") {
                body = try handleHTMLRequest(body, baseURL: url)
            } else if ct.contains("text/css") {
                body = try handleCSSRequest(body, baseURL: url)
            }
            response.addHeaderNamed("Content-Type", withValue: ct)
        }
        
        response.addHeaderNamed("Content-Length", withValue: String(body.count))
        if let statusCode = rec.statusCode, let statusReason = rec.statusReason {
            response.status = .custom(statusCode, statusReason)
        } else {
            response.status = .ok
        }
        if let location = rec.headerNamed("Location") {
            response.addHeaderNamed("Location", withValue: location)
        }
        response.setBody(body)
    }
}
