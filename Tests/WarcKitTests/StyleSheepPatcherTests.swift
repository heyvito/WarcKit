//
//  StyleSheepPatcherTests.swift
//  WarcKit
//
//  Created by Vito Sartori on 16/04/25.
//

import Testing
@testable import WarcKit

struct StyleSheepPatcherTests {
    @Test func testUpdateURLDoubleQuote() async throws {
        let file = """
            main {
                background-image: url("/foo/baz");
            }
            """
        let patch = StylesheetPatcher(file.data(using: .utf8)!, stylesheetPath: "/foo/style.css", baseURL: "example.org", allURLS: [])
        let r = patch.patch()
        #expect(r.contains("/example.org/foo/baz"))
    }
    
    @Test func testUpdateURLSingleQuote() async throws {
        let file = """
            main {
                background-image: url('/foo/baz');
            }
            """
        let patch = StylesheetPatcher(file.data(using: .utf8)!, stylesheetPath: "/foo/style.css", baseURL: "example.org", allURLS: [])
        let r = patch.patch()
        #expect(r.contains("/example.org/foo/baz"))
    }
    
    @Test func testUpdateURLUnquoted() async throws {
        let file = """
            main {
                background-image: url(/foo/baz);
            }
            """
        let patch = StylesheetPatcher(file.data(using: .utf8)!, stylesheetPath: "/foo/style.css", baseURL: "example.org", allURLS: [])
        let r = patch.patch()
        #expect(r.contains("/example.org/foo/baz"))
    }
}
