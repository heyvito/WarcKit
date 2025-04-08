//
//  WarcIO.swift
//  WarcKit
//
//  Created by Vito Sartori on 08/04/25.
//

import Foundation
internal import SwiftGzip

public class WarcIO {
    let data: Data

    public init(data: Data) async throws {
        self.data = data
        guard data.count > 2 else {
            throw WarcKitError.shortWarcData
        }
    }

    public func readRecordAtOffset(_ offset: Int64, withLength length: Int64) async throws -> WarcRecord {
        let dataSlice = data.subdata(
            in: data.index(
                data.startIndex,
                offsetBy: Int(offset)
            )..<data.index(data.startIndex, offsetBy: Int(offset) + Int(length))
        )
        return try await WarcParser.parse(dataSlice, length: length)
    }

    public func readRecord(_ rec: CDXJItem) async throws -> WarcRecord {
        return try await readRecordAtOffset(rec.offset, withLength: rec.length)
    }
}
