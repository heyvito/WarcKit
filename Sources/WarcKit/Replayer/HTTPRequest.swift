//
//  HttpRequest.swift
//  WarcKit
//
//  Created by Vito Sartori on 09/04/25.
//

import Foundation

typealias HeaderSet = [(String, String)]

extension HeaderSet {
    func value(forKey key: String) -> String? {
        values(forKey: key).first
    }

    func values(forKey key: String) -> [String] {
        filter { $0.0 == key.lowercased() }.map { $0.1 }
    }

    func containsKey(_ key: String) -> Bool {
        contains { $0.0.lowercased() == key.lowercased() }
    }

    func keyContains(_ key: String, token: String) -> Bool {
        values(forKey: key).contains(where: { $0.lowercased().contains(token.lowercased()) })
    }
}

class HTTPRequest {
    var rawPath: String = ""
    var path: String = ""
    var queryParams: [(String, String)] = []
    var method: String = ""
    var headers: HeaderSet = []

    init() {}
}
