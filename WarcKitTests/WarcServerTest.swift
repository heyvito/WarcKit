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
        debugPrint("Server running at \(try server.port())")
        sleep(120)
    }
}
