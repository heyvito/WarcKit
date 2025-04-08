//
//  WarcRecord.swift
//  WarcKit
//
//  Created by Vito Sartori on 08/04/25.
//

import Foundation
internal import SwiftGzip

public struct WarcRecord {
    public var fields: [String: String]
    public var body: Data
    public var contentType: String?
    public var contentLength: Int?
    public var statusCode: Int?
    public var statusReason: String?
    public var contentEncoding: String?
    public var allHeaders: [(String, String)]
    
    public var isGzipped: Bool {
        contentEncoding?.contains("gzip") ?? false
    }
    
    public func getBody() async throws -> Data {
        if isGzipped {
            return try await decompress()
        } else {
            return body
        }
    }
    
    func decompress() async throws -> Data {
        let decompressor = GzipDecompressor()
        return try await decompressor.unzip(data: body)
    }
    
    func headerNamed(_ name: String) -> String? {
        allHeaders.first(where: { $0.0.lowercased() == name.lowercased() })?.1
    }
}
