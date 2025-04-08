//
//  CDXJParser.swift
//  WarcKit
//
//  Created by Vito Sartori on 08/04/25.
//


import Foundation

struct CDXJParser {
    static func parse(data: Data) throws -> [CDXJItem] {
        guard let lines = String(data: data, encoding: .utf8)?
            .split(separator: "\n")
            .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) }) else {
            throw WarcKitError.invalidCDXJFile
        }
        var items: [CDXJItem] = []
        lines.forEach { line in
            guard !line.hasPrefix("#") else { return }
            items.append(try! CDXJItem(line))
        }

        return items
    }
}
