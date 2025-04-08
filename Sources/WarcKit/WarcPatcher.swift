//
//  WarcPatcher.swift
//  WarcKit
//
//  Created by Vito Sartori on 15/04/25.
//

import Foundation
internal import SwiftSoup

class WarcPatcher {
    private let baseURL: String
    private let allURLS: [String]
    
    init(baseURL: String, allURLS: [String]) {
        self.baseURL = baseURL
        self.allURLS = allURLS
    }
    static let httpSchemeRegexp = try! NSRegularExpression(
        pattern: "^(https?://)"
    )
    
    static func cleanURL(_ url: String) -> String {
        WarcPatcher.httpSchemeRegexp.stringByReplacingMatches(
            in: url,
            range: NSRange(location: 0, length: url.count),
            withTemplate: ""
        ).replacingOccurrences(of: "/https://", with: "/https:/")
            .replacingOccurrences(of: "/http://", with: "/http:/")
            .replacingOccurrences(of: "/https%3A%2F%2F", with: "/https%3A%2F")
            .replacingOccurrences(of: "/http%3A%2F%2F", with: "/http%3A%2F")
    }
    
    static func cleanPath(_ path: String, withBase base: String) -> String {
        if path.hasPrefix(".") {
            let baseDirectory = URL(fileURLWithPath: base).deletingLastPathComponent()
            let resolved = URL(fileURLWithPath: path, relativeTo: baseDirectory).standardized
            return resolved.absoluteString
        } else if path.hasPrefix("/") {
            if let baseURL = base.split(separator: "/").first {
                return "/\(baseURL)\(path)"
            } else {
                return path
            }
        } else if path.matches(WarcPatcher.httpSchemeRegexp) {
            return "/\(WarcPatcher.cleanURL(path))"
        } else {
            return path
        }
    }
    
    private func patchElementWithSelector(_ sel: String, inDocument document: inout Document, withAttributeName attributeName: String) throws {
        try document.select(sel).forEach { element in
            guard let href = try? element.attr(attributeName) else { return }
            var cleanHref = WarcPatcher.cleanURL(href)
            if cleanHref.hasPrefix("/") {
                cleanHref = String(WarcPatcher.cleanPath(cleanHref, withBase: baseURL).trimmingPrefix("/"))
            }
            guard allURLS.contains(cleanHref) else {
                if href.hasPrefix("/") {
                    try element.attr(attributeName, "https://\(baseURL)\(href)")
                }
                return
            }
            try element.attr(attributeName, "/\(cleanHref)")
        }
    }
    
    func patchHTML(_ data: Data) throws -> Data {
        guard let body = String(data: data, encoding: .utf8) else {
            throw WarcKitError.unsupportedHTTPEncoding
        }
        var document: Document = try SwiftSoup.parse(body)
        try patchElementWithSelector("link[rel=\"stylesheet\"]", inDocument: &document, withAttributeName: "href")
        try patchElementWithSelector("img[src]", inDocument: &document, withAttributeName: "src")
        try patchElementWithSelector("script[src]", inDocument: &document, withAttributeName: "src")
        try patchElementWithSelector("a[href]", inDocument: &document, withAttributeName: "href")
        
        return try document.html().data(using: .utf8)!
    }
}
