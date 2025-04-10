//
//  HttpResponseWriter.swift
//  WarcKit
//
//  Created by Vito Sartori on 09/04/25.
//

import Foundation

public struct HTTPResponseWriter {
    var headers: [(String, String)] = []
    var body: Data?
    var status: Int = 204
    var statusReason: String = "No Content"
    
    mutating func addHeaderNamed(_ name: String, withValue value: String) {
        headers.append((name, value))
    }
    
    mutating func setHeaderNamed(_ name: String, withValue value: String) {
        headers.removeAll { $0.0 == name }
        addHeaderNamed(name, withValue: value)
    }
    
    mutating func setBody(_ body: Data) {
        if self.status == 204 {
            self.status = 200
            self.statusReason = "OK"
        }
        self.body = body
    }
    
    mutating func setStatus(_ status: Int, reason: String? = nil) {
        self.status = status
        self.statusReason = reason ?? HTTPURLResponse.localizedString(forStatusCode: status)
    }
    
    func serialize() throws -> Data {
        var lines = [
            "HTTP/1.1 \(status) \(statusReason)"
        ]
        lines.append(contentsOf: headers.map { "\($0.0): \($0.1)" })
        lines.append("")
        
        let prelude = Data(lines.joined(separator: "\r\n").data(using: .utf8)!)
        var result = Data()
        result.append(prelude)
        if let body = body {
            result.append(body)
        }
        return result
    }
}
