//
//  StylesheetPatcher.swift
//  WarcKit
//
//  Created by Vito Sartori on 15/04/25.
//

import Foundation

class StylesheetPatcher {
    private let data: [Character]
    private var newData: [Character] = []
    private var cursor: Int = 0
    private let allURLS: [String]
    private let baseURL: String
    private let stylesheetPath: String

    init(_ data: Data, stylesheetPath: String, baseURL: String, allURLS: [String]) {
        self.data = Array(String(data: data, encoding: .utf8)!)
        self.baseURL = baseURL
        self.allURLS = allURLS
        self.stylesheetPath = stylesheetPath
    }

    func peek(_ n: Int = 0) -> Character? {
        if cursor + n >= data.count {
            return nil
        }
        return data[cursor + n]
    }

    func isURLFunction() -> Bool {
        let p1 = peek(), p2 = peek(1), p3 = peek(2), p4 = peek(3)
        return p1 == "u" && p2 == "r" && p3 == "l" && p4 == "("
    }
    
    func advance(_ n: Int = 1) {
        cursor += n
    }
    
    func consume() {
        guard let p = peek() else { return }
        newData.append(p)
        advance()
    }
    
    func eof() -> Bool { cursor >= data.count }
    
    func processURL() {
        guard let p = peek() else { return }
        let url: String?
        
        switch p {
        case "'", "\"":
            advance()
            url = parseURL(quoted: p)
        default:
            url = parseURL()
        }
        
        guard var newURL = url else { return }
        
        newURL = WarcPatcher.cleanPath(newURL, withBase: baseURL)
        
        newData.append(contentsOf: "url(\"")
        newData.append(contentsOf: newURL.replacingOccurrences(of: "\"", with: "\\\""))
        newData.append(contentsOf: "\")")
    }
    
    // HACK: This is a reaaaaally naive implementation
    // which absolutely does not conform to the CSS spec.
    // It will positively break if any shenanigans is done
    // in the URL function.
    
    func parseURL(quoted: Character) -> String? {
        var data = [Character]()
        var escaping = false
        while !eof() {
            guard let p = peek() else { return nil }
            if p == "\\" && !escaping {
                escaping = true
                advance()
            } else if escaping && p == quoted {
                escaping = false
            } else if escaping {
                data.append("\\")
                escaping = false
            } else if !escaping && p == quoted {
                advance()
                break
            }
            data.append(p)
            advance()
        }
        
        return String(data)
    }
    
    func parseURL() -> String? {
        var data = [Character]()
        var escaping = false
        while !eof() {
            guard let p = peek() else { return nil }
            if p == "\\" && !escaping {
                escaping = true
                advance()
            } else if escaping && (p == "(" || p == ")") {
                escaping = false
            } else if escaping {
                escaping = false
            } else if !escaping && p == ")" {
                advance()
                break
            }
            data.append(p)
            advance()
        }
        return String(data).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func patch() -> String {
        while cursor < data.count {
            if isURLFunction() {
                advance(4)
                while let p = peek(), p == " " || p == "\t" {
                    advance()
                }
                processURL()
                continue
            }
            consume()
        }
        
        return String(newData)
    }
}
