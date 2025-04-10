//
//  WarcParser.swift
//  WarcKit
//
//  Created by Vito Sartori on 08/04/25.
//

import Foundation

class WarcParser {
    static func parse(_ data: Data, offset: Int64, length: Int64) throws -> WarcRecord {
        try WarcParser(data, offset: offset, length: length).decode()
    }

    let version: String = "WARC/1.0"
    let data: Data
    var cursor: Int
    var offset: Int64
    var length: Int64

    init(_ data: Data, offset: Int64, length: Int64) {
        self.data = data
        self.offset = offset
        self.length = length
        cursor = Int(offset)
    }
    
    func readCRLF(ptr: UnsafeRawBufferPointer) throws {
        if ptr[cursor] != 0x0D || ptr[cursor + 1] != 0x0A {
            throw WarcKitError.invalidWarc("Expected CRLF")
        }
        cursor += 2
    }
    
    func readUntilCRLF(ptr: UnsafeRawBufferPointer) throws -> String {
        var str = ""
        var c: UInt8 = 0
        while true {
            c = ptr[cursor]
            if c == 0x0D && ptr[cursor + 1] == 0x0A {
                break
            }
            str.append(String(UnicodeScalar(Int(c))!))
            cursor += 1
        }
        return str
    }
    
    func readUntil(chr: Character, ptr: UnsafeRawBufferPointer) throws -> String {
        var str = ""
        var c: UInt8 = 0
        while true {
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
        if version != self.version {
            throw WarcKitError.invalidWarc("Invalid WARC version: \(version)")
        }
        try readCRLF(ptr: ptr)
    }
    
    func isCRLF(ptr: UnsafeRawBufferPointer) -> Bool {
        guard cursor < ptr.count else { return false }
        return ptr[cursor] == 0x0D && ptr[cursor + 1] == 0x0A
    }
    
    func readHeaderField(ptr: UnsafeRawBufferPointer) throws -> (String, String) {
        let name = try readUntil(chr: ":", ptr: ptr).trimmingCharacters(in: .whitespacesAndNewlines)
        cursor += 1
        let value = try readUntilCRLF(ptr: ptr).trimmingCharacters(in: .whitespacesAndNewlines)
        return (name, value)
    }

    func decode() throws -> WarcRecord {
        try data.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) in
            var fields = [String: String]()
            try readVersion(ptr: pointer)
            while(true) {
                let (headerField, value) = try readHeaderField(ptr: pointer)
                fields[headerField] = value
                try readCRLF(ptr: pointer)
                if isCRLF(ptr: pointer) {
                    try readCRLF(ptr: pointer)
                    break
                }
            }
            
            let body: Data = if let lengthString = fields["Content-Length"], let length = Int(lengthString) {
                Data(pointer[cursor...cursor + length])
            } else {
                Data(pointer[cursor...cursor + Int(self.length)])
            }
            
            return WarcRecord(fields: fields, body: body)
        }
    }
}
