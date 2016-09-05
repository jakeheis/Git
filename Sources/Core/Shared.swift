//
//  Shared.swift
//  Git
//
//  Created by Jake Heiser on 9/1/16.
//
//

import Foundation
import FileKit

extension Data {
    
    func uncompressed() -> Data? {
        return (try? (self as NSData).gzipUncompressed())?.data as Data?
    }
    
    func uncompressedWithInfo() -> (data: Data, bytesProcessed: Int)? {
        guard let processed = try? (self as NSData).gzipUncompressed() else {
            return nil
        }
        return (processed.data as Data, processed.bytesProcessed)
    }
    
    func compressed() -> Data? {
        return (try? (self as NSData).gzipCompressed())?.data as Data?
    }
    
    func write(to path: Path) throws {
        try (self as NSData).writeToPath(path)
    }
    
}
