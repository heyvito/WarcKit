//
//  WarcRecord.swift
//  WarcKit
//
//  Created by Vito Sartori on 08/04/25.
//

import Foundation
internal import SwiftGzip

struct WarcRecord {
    var fields: [String: String]
    var body: Data
    var contentType: String?
    var contentLength: Int?
    var statusCode: Int?
    var contentEncoding: String?
    
    func decompress() async throws -> Data {
        let decompressor = GzipDecompressor()
        return try await decompressor.unzip(data: body)
    }
}
