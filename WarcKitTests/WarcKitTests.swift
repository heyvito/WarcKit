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
        debugPrint(root)
        let warcio = try await WarcIO(data: Data(contentsOf: URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("TestFixtures/data.warc.gz")))
        let parsed = try warcio.readRecord(root)
        var httpParser = HTTPResponseParser(data: parsed.body)
        let httpResponse = try! httpParser.parse()
        if httpResponse.isGzipEncoded() {
            let decomp = try await httpResponse.decompress()
            debugPrint(String(data: decomp, encoding: .utf8)!)
        }
    }
}
