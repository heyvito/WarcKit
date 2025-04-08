//
//  HTTPResponseParser.swift
//  WarcKit
//
//  Created by Vito Sartori on 09/04/25.
//

import Foundation
internal import SwiftGzip

struct HTTPResponseParser {
    let data: Data
    var cursor = 0

    init(data: Data) {
        self.data = data
    }

    mutating func parse() throws -> HTTPResponse {
        try data.withUnsafeBytes { ptr in
            let (version, status, reason) = try parseHTTPVersionAndStatus(ptr)
            let headers = try parseHTTPHeaders(ptr)
            let bodySlice = UnsafeRawBufferPointer(rebasing: ptr[cursor...])
            return HTTPResponse(
                httpVersion: version,
                statusCode: status,
                reasonPhrase: reason,
                headers: headers,
                bodyData: Data(bodySlice)
            )
        }
    }

    mutating func parseHTTPVersionAndStatus(_ ptr: UnsafeRawBufferPointer)
        throws -> (httpVersion: String, statusCode: Int, reasonPhrase: String)
    {
        var mark = cursor
        guard match("HTTP/1.") else {
            throw WarcKitError.unsupportedHTTPResponse
        }

        while try peekChar() != " " {
            advance()
        }

        let versionBytes = Data(ptr[mark..<cursor])
        guard let httpVersion = String(data: versionBytes, encoding: .ascii)
        else {
            throw WarcKitError.corruptHTTPResponse(
                "Could not read HTTP version"
            )
        }
        advance()

        mark = cursor
        while try peekChar() != " " {
            advance()
        }

        let statusBytes = Data(ptr[mark..<cursor])
        guard let rawHttpStatus = String(data: statusBytes, encoding: .ascii)
        else {
            throw WarcKitError.corruptHTTPResponse("Could not read HTTP status")
        }
        guard let httpStatus = Int(rawHttpStatus) else {
            throw WarcKitError.corruptHTTPResponse("Invalid HTTP status value")
        }
        advance()

        mark = cursor
        advanceToCRLF()
        let reason = String(data: Data(ptr[mark..<cursor]), encoding: .utf8)!
        try consumeCRLF()
        return (httpVersion, httpStatus, reason)
    }

    mutating func parseHTTPHeader(_ ptr: UnsafeRawBufferPointer) throws -> (
        String, String
    ) {
        var mark = cursor
        try advanceUntil(":")
        let key = String(data: Data(ptr[mark..<cursor]), encoding: .utf8)!
        guard match(":") else {
            throw WarcKitError.corruptHTTPResponse(
                "Expected a colon after header key"
            )
        }
        mark = cursor
        advanceToCRLF()
        let value = String(data: Data(ptr[mark..<cursor]), encoding: .utf8)!
        try consumeCRLF()
        return (key, value.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    mutating func parseHTTPHeaders(_ ptr: UnsafeRawBufferPointer) throws -> [(
        String, String
    )] {
        var headers: [(String, String)] = []
        while true {
            let (key, value) = try parseHTTPHeader(ptr)
            headers.append((key, value))
            if isCRLF() {
                try consumeCRLF()
                break
            }
        }
        return headers
    }
}

// Parser Infrastructure
extension HTTPResponseParser {
    func peek(_ n: Int = 0) throws -> UInt8 {
        guard cursor + n < data.count else {
            throw WarcKitError.readPastEnd
        }
        return data[data.index(data.startIndex, offsetBy: cursor + n)]
    }

    func peekChar(_ n: Int = 0) throws -> Character {
        if let c = String(data: Data([try peek(n)]), encoding: .utf8)?.first {
            return c
        } else {
            throw WarcKitError.readPastEnd
        }
    }

    mutating func match(_ str: String) -> Bool {
        var matched = true
        for idx in str.indices {
            let i = str.distance(from: str.startIndex, to: idx)
            let c = str[idx]
            if data[data.index(cursor, offsetBy: i)] != UInt8(c.asciiValue!) {
                matched = false
                break
            }
        }
        if matched {
            advance(str.count)
        }
        return matched
    }

    mutating func advance(_ n: Int = 1) {
        self.cursor += n
    }

    mutating func advanceUntil(_ c: Character) throws {
        while try peekChar() != c { advance() }
    }

    mutating func advanceToCRLF() {
        while true {
            if isCRLF() { break }
            advance()
        }
    }

    mutating func consumeCRLF() throws {
        if isCRLF() {
            advance(2)
            return
        }
        throw WarcKitError.corruptHTTPResponse("Expected CRLF")
    }

    func isDoubleCRLF() -> Bool {
        guard let p1 = try? peek(),
            let p2 = try? peek(1),
            let p3 = try? peek(2),
            let p4 = try? peek(3)
        else {
            return false
        }
        return p1 == 13 && p2 == 10 && p3 == 13 && p4 == 10
    }

    func isCRLF() -> Bool {
        guard let p1 = try? peek(),
            let p2 = try? peek(1)
        else {
            return false
        }
        return p1 == 13 && p2 == 10
    }
}
