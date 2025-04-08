//
//  WarcKitTests.swift
//  WarcKitTests
//
//  Created by Vito Sartori on 08/04/25.
//

import Testing
@testable import WarcKit
import Foundation

struct WarcKitTests {
    @Test func testWarcIO() async throws {
        let index = try! CDXJParser.parse(data: Data(contentsOf: URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("TestFixtures/autoindex.cdxj")))
        guard let root = index.first(where: { $0.url.absoluteString == "https://vito.io/" }) else {
            #expect(Bool(false))
            return
        }
        let warcio = try await WarcIO(data: Data(contentsOf: URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("TestFixtures/data.warc.gz")))
        let parsed = try await warcio.readRecord(root)
        let body = String(data: try await parsed.getBody(), encoding: .utf8)
        #expect(body?.contains("Vito Sartori") ?? false)
    }
    
    @Test func testWarcIOFile2() async throws {
        let index = try! CDXJParser.parse(data: Data(contentsOf: URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("TestFixtures/autoindex.cdxj")))
        guard let root = index.first(where: { $0.url.absoluteString == "https://vito.io/assets/css/main.css?cache=20250130T095925" }) else {
            #expect(Bool(false))
            return
        }
        let warcio = try await WarcIO(data: Data(contentsOf: URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("TestFixtures/data.warc.gz")))
        let parsed = try await warcio.readRecord(root)
        #expect(parsed.contentType?.contains("text/css") ?? false)
        let body = String(data: try await parsed.getBody(), encoding: .utf8)
        #expect(body?.contains("*, *::before, *::after") ?? false)
    }
}
