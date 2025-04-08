//
//  CDXJItem.swift
//  WarcKit
//
//  Created by Vito Sartori on 08/04/25.
//


import Foundation

struct CDXJItem: Decodable {
    private(set) var surt: String
    private(set) var timestamp: String
    let url: URL
    let mime: String
    let status: Int
    let digest: String
    let length: Int64
    let offset: Int64
    let filename: String

    enum CodingKeys: String, CodingKey {
        case surt = "surt"
        case timestamp = "timestamp"
        case url = "url"
        case mime = "mime"
        case status = "status"
        case digest = "digest"
        case length = "length"
        case offset = "offset"
        case filename = "filename"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        surt = ""
        timestamp = ""
        let rawUrl = try container.decode(String.self, forKey: .url)
        url = URL(string: rawUrl)!

        mime = try container.decode(String.self, forKey: .mime)
        let rawStatus = try container.decode(String.self, forKey: .status)
        guard let intStatus = Int(rawStatus) else {
            throw WarcKitError.invalidCDXJJSON
        }
        status = intStatus

        digest = try container.decode(String.self, forKey: .digest)

        let rawLength = try container.decode(String.self, forKey: .length)
        guard let intLength = Int64(rawLength) else {
            throw WarcKitError.invalidCDXJJSON
        }
        length = intLength

        let rawOffset = try container.decode(String.self, forKey: .offset)
        guard let intOffset = Int64(rawOffset) else {
            throw WarcKitError.invalidCDXJJSON
        }
        offset = intOffset
        filename = try container.decode(String.self, forKey: .filename)
    }

    init(_ line: String) throws {
        let components = line
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: " ")
        guard components.count == 3 else {
            throw WarcKitError.invalidCDXJItem
        }

        let (surt, timestamp, metadata) = (components[0], components[1], components[2])
        let decoded = try JSONDecoder().decode(CDXJItem.self, from: metadata.data(using: .utf8)!)
        self = decoded
        self.surt = surt
        self.timestamp = timestamp
    }
}
