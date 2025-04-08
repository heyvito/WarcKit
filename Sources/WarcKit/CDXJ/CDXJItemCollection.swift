//
//  CDXJItemCollection.swift
//  WarcKit
//
//  Created by Vito Sartori on 10/04/25.
//

import Foundation

class CDXJItemCollection {
    var items: [CDXJItem]

    init(items: [CDXJItem] = []) {
        self.items = items
    }

    var count: Int { items.count }

    var first: CDXJItem? { items.first }

    func first(where predicate: (CDXJItem) throws -> Bool) rethrows -> CDXJItem? { try items.first(where: predicate) }

    func append(_ item: CDXJItem) { items.append(item) }

    func byURL(_ url: String) -> CDXJItem? { items.first { $0.symbolicURL == url } }

    func allByURL(_ url: String) -> [CDXJItem] { items.filter { $0.symbolicURL == url } }
    
    func allURLS() -> [String] {
        items.map { $0.symbolicURL }.uniq()
    }
}
