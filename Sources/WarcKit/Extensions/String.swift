//
//  String.swift
//  WarcKit
//
//  Created by Vito Sartori on 15/04/25.
//

import Foundation

extension String {
    func matches(_ regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
    }
    
    func matches(_ regex: NSRegularExpression) -> Bool {
        return regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) != nil
    }
}
