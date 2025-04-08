//
//  HttpResponseWriter.swift
//  WarcKit
//
//  Created by Vito Sartori on 09/04/25.
//

import Foundation

struct HTTPResponseWriter {
    public enum HTTPStatus: Equatable {
        case ok
        case created
        case accepted
        case noContent
        case movedPermanently
        case movedTemporarily
        case badRequest
        case unauthorized
        case forbidden
        case notFound
        case notAcceptable
        case tooManyRequests
        case internalServerError
        case custom(Int, String)

        var code: Int {
            switch self {
            case .ok:
                return 200
            case .created:
                return 201
            case .accepted:
                return 202
            case .noContent:
                return 204
            case .movedPermanently:
                return 301
            case .movedTemporarily:
                return 302
            case .badRequest:
                return 400
            case .unauthorized:
                return 401
            case .forbidden:
                return 403
            case .notFound:
                return 404
            case .notAcceptable:
                return 406
            case .tooManyRequests:
                return 429
            case .internalServerError:
                return 500
            case .custom(let code, _):
                return code
            }
        }

        var reasonPhrase: String {
            switch self {
            case .ok:
                return "OK"
            case .created:
                return "Created"
            case .accepted:
                return "Accepted"
            case .noContent:
                return "No Content"
            case .movedPermanently:
                return "Moved Permanently"
            case .movedTemporarily:
                return "Moved Temporarily"
            case .badRequest:
                return "Bad Request"
            case .unauthorized:
                return "Unauthorized"
            case .forbidden:
                return "Forbidden"
            case .notFound:
                return "Not Found"
            case .notAcceptable:
                return "Not Acceptable"
            case .tooManyRequests:
                return "Too Many Requests"
            case .internalServerError:
                return "Internal Server Error"
            case .custom(_, let reasonPhrase):
                return reasonPhrase
            }
        }

        var statusLine: String {
            return "HTTP/1.1 \(code) \(reasonPhrase)"
        }
    }

    var headers: [(String, String)] = []
    var body: Data?
    var status: HTTPStatus = .noContent

    mutating func addHeaderNamed(_ name: String, withValue value: String) {
        headers.append((name, value))
    }

    mutating func setHeaderNamed(_ name: String, withValue value: String) {
        headers.removeAll { $0.0 == name }
        addHeaderNamed(name, withValue: value)
    }

    mutating func setBody(_ body: Data) {
        if self.status == .noContent {
            self.status = .ok
        }
        self.body = body
    }

    mutating func setBody(_ body: String) {
        setBody(body.data(using: .utf8)!)
    }

    mutating func setStatus(_ status: HTTPStatus) {
        self.status = status
    }

    mutating func setStatus(_ status: Int, withReason reason: String) {
        self.status = .custom(status, reason)
    }

    func serialize() -> Data {
        var lines = [
            status.statusLine
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
