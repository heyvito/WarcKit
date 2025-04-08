//
//  Data.swift
//  WarcKit
//
//  Created by Vito Sartori on 16/04/25.
//

import Foundation
internal import SwiftGzip

extension Data {
    func inflateGzip() async throws -> Data {
        let decompressor = GzipDecompressor()
        return try await decompressor.unzip(data: self)
    }
}
