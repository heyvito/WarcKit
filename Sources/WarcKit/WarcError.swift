//
//  WarcError.swift
//  WarcKit
//
//  Created by Vito Sartori on 08/04/25.
//


enum WarcKitError: Error {
    case invalidCDXJItem
    case invalidCDXJJSON
    case invalidCDXJFile
    
    case shortWarcData
    case badWarcArchive
    
    case compressionInitError
    case compressionProcessingError
    
    case invalidWarc(String)
    
    case unsupportedHTTPResponse
    case unsupportedHTTPEncoding
    case corruptHTTPResponse(String)
    
    case readPastEnd
}
