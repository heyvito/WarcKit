//
//  Errno.swift
//  WarcKit
//
//  Created by Vito Sartori on 09/04/25.
//


import Foundation

class Errno {

    public class func description() -> String {
        // https://forums.developer.apple.com/thread/113919
        return String(cString: strerror(errno))
    }
}
