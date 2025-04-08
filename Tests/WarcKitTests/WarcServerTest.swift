//
//  WarcServerTest.swift
//  WarcKit
//
//  Created by Vito Sartori on 10/04/25.
//

import Testing
@testable import WarcKit
import Foundation

struct WarcServerTests {
    @Test func testWarcServer() async throws {
        let indexPath = URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("TestFixtures/autoindex.cdxj")
        let archivePath = URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("TestFixtures/data.warc.gz")
        let server = try await WarcServer(indexPath: indexPath, archivePath: archivePath)
        try server.start()
        defer { server.stop() }
        debugPrint("Server running at \(try server.port())")
        let htmlReq = URLRequest(url: URL(string: "http://127.0.0.1:\(try server.port())/vito.io/")!)
        let htmlResp = try String(contentsOf: htmlReq.url!, encoding: .utf8)
        #expect(htmlResp.contains("Vito Sartori"))
        #expect(htmlResp.contains("href=\"/vito.io/assets/css/main.css?cache=20250130T095925\""))
        
        let cssReq = URLRequest(url: URL(string: "http://127.0.0.1:\(try server.port())/vito.io/assets/css/main.css?cache=20250130T095925")!)
        let cssResp = try String(contentsOf: cssReq.url!, encoding: .utf8)
        #expect(cssResp.contains("*, *::before, *::after"))
    }
}
