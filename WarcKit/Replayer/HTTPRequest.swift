//
//  HttpRequest.swift
//  WarcKit
//
//  Created by Vito Sartori on 09/04/25.
//

import Foundation

public typealias HeaderSet = [(String, String)]

extension HeaderSet {
    func value(forKey key: String) -> String? {
        values(forKey: key).first
    }

    func values(forKey key: String) -> [String] {
        filter { $0.0 == key.lowercased() }.map { $0.1 }
    }

    func containsKey(_ key: String) -> Bool {
        contains { $0.0.lowercased() == key }
    }

    func keyContains(_ key: String, token: String) -> Bool {
        values(forKey: key).contains(where: { $0.lowercased().contains(token.lowercased()) })
    }
}

public class HTTPRequest {
    public var rawPath: String = ""
    public var path: String = ""
    public var queryParams: [(String, String)] = []
    public var method: String = ""
    public var headers: HeaderSet = []

    public init() {}
}
