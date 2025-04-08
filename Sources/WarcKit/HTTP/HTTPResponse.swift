//
//  HTTPResponse.swift
//  WarcKit
//
//  Created by Vito Sartori on 16/04/25.
//

import Foundation
internal import SwiftGzip

struct HTTPResponse {
    var httpVersion: String
    var statusCode: Int
    var reasonPhrase: String
    var headers: [(String, String)]
    var bodyData: Data

    func headerByName(_ name: String) -> String? {
        headers.first { $0.0.lowercased() == name.lowercased() }?.1
    }

    func headersByName(_ name: String) -> [String] {
        headers.filter { $0.0.lowercased() == name.lowercased() }.map(\.1)
    }

    func isGzipEncoded() -> Bool {
        headersByName("Content-Encoding").contains("gzip")
    }

    func decompress() async throws -> Data {
        return try await bodyData.inflateGzip()
    }
}
