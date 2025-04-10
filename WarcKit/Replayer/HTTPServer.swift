//
//  HTTPServer.swift
//  WarcKit
//
//  Created by Vito Sartori on 09/04/25.
//

import Foundation

public protocol HTTPServerDelegate {
    func handleRequest(_ request: HttpRequest, withResponse response: HTTPResponseWriter) async throws
}

open class HttpServer: HttpServerIO {
    public var notFoundHandler: ((HttpRequest) -> HttpResponse)?
    public var requestDelegate: HTTPServerDelegate?

    open func dispatch(_ request: HttpRequest) async throws -> HTTPResponseWriter {
        let response = HTTPResponseWriter()
        if let del = requestDelegate {
            try await del.handleRequest(request, withResponse: response)
            return response
        }
        return super.dispatch(request)
    }
}
