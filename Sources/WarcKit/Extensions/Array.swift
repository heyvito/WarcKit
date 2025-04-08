//
//  Array.swift
//  WarcKit
//
//  Created by Vito Sartori on 14/04/25.
//

import Foundation

extension Array where Element: Equatable {
    public func uniq() -> [Element] {
        let uniqueItems = NSOrderedSet(array: self)
        return (uniqueItems.array as? [Element]) ?? []
    }
}
