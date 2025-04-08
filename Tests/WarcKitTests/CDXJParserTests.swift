//
//  CDXJParserTests.swift
//  WarcKitTests
//
//  Created by Vito Sartori on 08/04/25.
//

import Testing
@testable import WarcKit

struct CDXJParserTests {
    @Test func testParseLine() async throws {
        let line = """
            io,vito)/assets/css/main.css?cache=20250130t095925 20250402021331 {"url":"https://vito.io/assets/css/main.css?cache=20250130T095925","mime":"text/css","status":"200","digest":"OLQHSNRAKBAHCDGUFOWPKV5EPFFJLVVL","length":"4726","offset":"10229","filename":"data.warc.gz"}
            """
        let item = try CDXJItem(line)
        #expect(item.url.absoluteString == "https://vito.io/assets/css/main.css?cache=20250130T095925")
        #expect(item.mime == "text/css")
        #expect(item.status == 200)
        #expect(item.digest == "OLQHSNRAKBAHCDGUFOWPKV5EPFFJLVVL")
        #expect(item.length == 4726)
        #expect(item.offset == 10229)
        #expect(item.filename == "data.warc.gz")
        #expect(item.timestamp == "20250402021331")
        #expect(item.surt == "io,vito)/assets/css/main.css?cache=20250130t095925")
    }
    
    @Test func testParseAppleDevStreaming() async throws {
        let line =
        "com,apple,devstreaming-cdn)/videos/wwdc/2021/10061/4/d12f25a4-d409-4dda-9dcf-72c97e9875c3/cmaf.m3u8 20250407234442 {\"metadata\":\"{\\\"adaptive_max_resolution\\\": 921600, \\\"adaptive_max_bandwidth\\\": 2000000}\",\"url\":\"https://devstreaming-cdn.apple.com/videos/wwdc/2021/10061/4/D12F25A4-D409-4DDA-9DCF-72C97E9875C3/cmaf.m3u8\",\"mime\":\"application/vnd.apple.mpegurl\",\"status\":\"200\",\"digest\":\"GZDM6NSUOPMUZ4PG5AVNFFWG5NHFIEFO\",\"length\":\"1859\",\"offset\":\"1277614\",\"filename\":\"data.warc.gz\"}"
        let item = try CDXJItem(line)
        #expect(item.url.absoluteString == "https://devstreaming-cdn.apple.com/videos/wwdc/2021/10061/4/D12F25A4-D409-4DDA-9DCF-72C97E9875C3/cmaf.m3u8")
        #expect(item.mime == "application/vnd.apple.mpegurl")
        #expect(item.status == 200)
        #expect(item.digest == "GZDM6NSUOPMUZ4PG5AVNFFWG5NHFIEFO")
        #expect(item.length == 1859)
        #expect(item.offset == 1277614)
        #expect(item.filename == "data.warc.gz")
        #expect(item.timestamp == "20250407234442")
        #expect(item.surt == "com,apple,devstreaming-cdn)/videos/wwdc/2021/10061/4/d12f25a4-d409-4dda-9dcf-72c97e9875c3/cmaf.m3u8")
    }
    @Test func testParseFile() async throws {
        let file = """
            com,googleapis,fonts)/css2?display=swap&family=ibm+plex+mono:wght@300;400;500&family=ibm+plex+sans:wght@300;400;500&family=ibm+plex+serif:ital@1 20250402021331 {"url":"https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@300;400;500&family=IBM+Plex+Sans:wght@300;400;500&family=IBM+Plex+Serif:ital@1&display=swap","mime":"text/css","status":"200","digest":"37JSLPXFZW5SNCOL7ZTGPDE5IPF52KEV","length":"1887","offset":"15496","filename":"data.warc.gz"}
            io,vito)/ 20250402021330 {"url":"https://vito.io/","mime":"text/html","status":"200","digest":"OKGL3SLUJF57NYK3EKDPQVCLXY47BZLP","length":"3468","offset":"0","filename":"data.warc.gz"}
            io,vito)/ 20250402021331 {"url":"https://vito.io/","mime":"text/html","status":"200","digest":"EFDFEF7CBW2RAYDKTLHJJDZWON2UWQR3","length":"3463","offset":"4040","filename":"data.warc.gz"}
            io,vito)/assets/css/main.css?cache=20250130t095925 20250402021331 {"url":"https://vito.io/assets/css/main.css?cache=20250130T095925","mime":"text/css","status":"200","digest":"OLQHSNRAKBAHCDGUFOWPKV5EPFFJLVVL","length":"4726","offset":"10229","filename":"data.warc.gz"}
            io,vito)/assets/font/itc-garamond-narrow-book.woff2 20250402021331 {"url":"https://vito.io/assets/font/itc-garamond-narrow-book.woff2","mime":"font/woff2","status":"200","digest":"K3NJRUF3V4OQWU6AVHWYIDFWK2NAJ2QL","length":"25940","offset":"17976","filename":"data.warc.gz"}
            io,vito)/cdn-cgi/scripts/5c5dd728/cloudflare-static/email-decode.min.js 20250402021331 {"url":"https://vito.io/cdn-cgi/scripts/5c5dd728/cloudflare-static/email-decode.min.js","mime":"application/javascript","status":"200","digest":"RBECGBXMZESY2XU4XON2KMKNVMRDUXNU","length":"1593","offset":"8086","filename":"data.warc.gz"}
            io,vito)/favicon.ico 20250402021331 {"url":"https://vito.io/favicon.ico","mime":"text/html","status":"404","digest":"Z7SGSKE24NOZZO4CVENK7RYXA5VCAV2O","length":"1132","offset":"44484","filename":"data.warc.gz"}
            """

        let items = try CDXJParser.parse(data: file.data(using: .utf8)!)
        #expect(items.count == 7)
    }
}
