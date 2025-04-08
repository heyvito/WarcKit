//
//  WarcParser.swift
//  WarcKit
//
//  Created by Vito Sartori on 08/04/25.
//

import Foundation
internal import SwiftGzip

public class WarcParser {
    public static func parse(_ data: Data, length: Int64) async throws -> WarcRecord {
        return try await WarcParser(data, length: length).decode()
    }

    static let version: String = "WARC/1.0"
    let data: Data
    var cursor: Int
    var length: Int64

    init(_ data: Data, length: Int64) {
        self.data = data
        self.length = length
        cursor = 0
    }

    func readCRLF(ptr: UnsafeRawBufferPointer) throws {
        if ptr[cursor] != 0x0D || ptr[cursor + 1] != 0x0A {
            throw WarcKitError.invalidWarc("Expected CRLF")
        }
        cursor += 2
    }

    func eof() -> Bool {
        cursor >= Int(length)
    }

    func readUntilCRLF(ptr: UnsafeRawBufferPointer) throws -> String {
        var str = ""
        var c: UInt8 = 0
        while !eof() {
            c = ptr[cursor]
            if c == 0x0D && ptr[cursor + 1] == 0x0A {
                break
            }
            str.append(String(UnicodeScalar(Int(c))!))
            cursor += 1
        }
        return str
    }

    func readUntil(chr: Character, ptr: UnsafeRawBufferPointer) throws -> String
    {
        var str = ""
        var c: UInt8 = 0
        while !eof() {
            c = ptr[cursor]
            if c == chr.asciiValue! {
                break
            }
            str.append(String(UnicodeScalar(Int(c))!))
            cursor += 1
        }
        return str
    }

    func readVersion(ptr: UnsafeRawBufferPointer) throws {
        let version = try readUntilCRLF(ptr: ptr)
        if version != WarcParser.version {
            throw WarcKitError.invalidWarc("Invalid WARC version: \(version)")
        }
        try readCRLF(ptr: ptr)
    }

    func isCRLF(ptr: UnsafeRawBufferPointer) -> Bool {
        guard cursor < ptr.count else { return false }
        return ptr[cursor] == 0x0D && ptr[cursor + 1] == 0x0A
    }

    func readHeaderField(ptr: UnsafeRawBufferPointer) throws -> (String, String)
    {
        let name = try readUntil(chr: ":", ptr: ptr).trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        cursor += 1
        let value = try readUntilCRLF(ptr: ptr).trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        return (name, value)
    }

    func decode() async throws -> WarcRecord {
        let decompressor = GzipDecompressor()
        let decoded =
            if data.isGzipped {
                try await decompressor.unzip(data: data)
            } else {
                data
            }

        return try decoded.withUnsafeBytes {
            (pointer: UnsafeRawBufferPointer) in
            var fields = [String: String]()
            try readVersion(ptr: pointer)
            while true {
                let (headerField, value) = try readHeaderField(ptr: pointer)
                fields[headerField] = value
                try readCRLF(ptr: pointer)
                if isCRLF(ptr: pointer) {
                    try readCRLF(ptr: pointer)
                    break
                }
            }

            let body: Data =
                if let lengthString = fields["Content-Length"],
                    let length = Int(lengthString)
                {
                    Data(pointer[cursor...cursor + length])
                } else {
                    Data(pointer[cursor...cursor + Int(self.length)])
                }

            var httpParser = HTTPResponseParser.init(data: body)
            let resp = try httpParser.parse()
            var cLen: Int? = nil
            if let rawLen = resp.headerByName("Content-Length") {
                cLen = Int(rawLen)
            }

            return WarcRecord(
                fields: fields,
                body: resp.bodyData,
                contentType: resp.headerByName("Content-Type"),
                contentLength: cLen,
                statusCode: resp.statusCode,
                statusReason: resp.reasonPhrase,
                contentEncoding: resp.headerByName("Content-Encoding"),
                allHeaders: resp.headers,
            )
        }
    }
}
