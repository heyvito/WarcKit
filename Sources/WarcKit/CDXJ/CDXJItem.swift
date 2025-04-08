//
//  CDXJItem.swift
//  WarcKit
//
//  Created by Vito Sartori on 08/04/25.
//


import Foundation

public struct CDXJItem: Decodable {
    public private(set) var surt: String
    public private(set) var timestamp: String
    public let url: URL
    public let mime: String
    public let status: Int
    public let digest: String
    public let length: Int64
    public let offset: Int64
    public let filename: String
    public var symbolicURL: String

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

    private static let httpSchemeRegex = try! Regex("https?://")

    public init(from decoder: Decoder) throws {
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
        symbolicURL = rawUrl.replacing(CDXJItem.httpSchemeRegex, with: "")
    }

    public init(_ line: String) throws {
        let components = line
            .split(separator: " ", maxSplits: 2)
        guard components.count == 3 else {
            throw WarcKitError.invalidCDXJItem
        }

        let (surt, timestamp, metadata) = (components[0], components[1], components[2])
        let decoded = try JSONDecoder().decode(CDXJItem.self, from: metadata.data(using: .utf8)!)
        self = decoded
        self.surt = String(surt)
        self.timestamp = String(timestamp)
    }
}
