//
//  HttpParser.swift
//  WarcKit
//
//  Created by Vito Sartori on 09/04/25.
//

import Foundation

enum HttpParserError: Error, Equatable {
    case invalidStatusLine(String)
}

class HTTPParser {

    public init() {}

    public func readHttpRequest(_ socket: Socket) throws -> HTTPRequest {
        let statusLine = try socket.readLine()
        let statusLineTokens = statusLine.components(separatedBy: " ")
        if statusLineTokens.count < 3 {
            throw HttpParserError.invalidStatusLine(statusLine)
        }
        let request = HTTPRequest()
        request.method = statusLineTokens[0]
        let encodedPath =
            statusLineTokens[1].addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed
            ) ?? statusLineTokens[1]
        request.rawPath = encodedPath
        let urlComponents = URLComponents(string: encodedPath)
        request.path = urlComponents?.path ?? ""
        request.queryParams =
            urlComponents?.queryItems?.map { ($0.name, $0.value ?? "") } ?? []
        request.headers = try readHeaders(socket)
        return request
    }

    private func readHeaders(_ socket: Socket) throws -> [(String, String)] {
        var headers = HeaderSet()
        while case let headerLine = try socket.readLine(), !headerLine.isEmpty {
            let headerTokens = headerLine.split(
                separator: ":",
                maxSplits: 1,
                omittingEmptySubsequences: true
            ).map(String.init)
            if let name = headerTokens.first, let value = headerTokens.last {
                headers.append((name.lowercased(), value.trimmingCharacters(in: .whitespacesAndNewlines)))
            }
        }
        return headers
    }

    func supportsKeepAlive(_ headers: HeaderSet) -> Bool {
        headers.keyContains("connection", token: "keep-alive")
    }
}
