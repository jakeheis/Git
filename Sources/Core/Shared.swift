//
//  Shared.swift
//  Git
//
//  Created by Jake Heiser on 9/1/16.
//
//

import Foundation

extension Data {
    
    func uncompressed() -> Data? {
        return (try? (self as NSData).gzipUncompressed()) as Data?
    }
    
}
