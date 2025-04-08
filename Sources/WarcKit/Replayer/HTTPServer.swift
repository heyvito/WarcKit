//
//  HTTPServer.swift
//  WarcKit
//
//  Created by Vito Sartori on 09/04/25.
//

import Foundation

protocol HTTPServerDelegate {
    func handleRequest(_ request: HTTPRequest, withResponse response: inout HTTPResponseWriter) async throws
}

class HTTPServer: HttpServerIO {
    var notFoundHandler: ((HTTPRequest) -> HTTPResponseWriter)?
    var requestDelegate: HTTPServerDelegate?

    override func dispatch(_ request: HTTPRequest) async throws -> HTTPResponseWriter {
        var response = HTTPResponseWriter()
        if let del = requestDelegate {
            try await del.handleRequest(request, withResponse: &response)
            return response
        }
        return try await super.dispatch(request)
    }
}
