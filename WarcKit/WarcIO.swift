//
//  WarcIO.swift
//  WarcKit
//
//  Created by Vito Sartori on 08/04/25.
//

import Compression
import Foundation
internal import SwiftGzip

class WarcIO {
    enum GzipMode {
        case single
        case multiple
    }

    let data: Data
    let mode: GzipMode
    let decompressed: Data

    init(data: Data) async throws {
        self.data = data
        guard data.count > 2 else {
            throw WarcKitError.shortWarcData
        }
        let count = WarcIO.countGzipMembers(in: data)
        mode = count > 1 ? .multiple : .single
        let decompressor = GzipDecompressor()
        decompressed = try await decompressor.unzip(data: data)
    }

    func readRecordAtOffset(_ offset: Int64, withLength length: Int64) throws
        -> WarcRecord
    {
        return try WarcParser.parse(decompressed, offset: offset, length: length)
    }

    func readRecord(_ rec: CDXJItem) throws -> WarcRecord {
        return try readRecordAtOffset(rec.offset, withLength: rec.length)
    }

    fileprivate static func countGzipMembers(in data: Data) -> Int {
        let magic: [UInt8] = [0x1f, 0x8b]
        var count = 0
        let bytes = [UInt8](data)

        for i in 0..<bytes.count - 1 {
            if bytes[i] == magic[0], bytes[i + 1] == magic[1] {
                count += 1
            }
        }

        return count
    }
}
