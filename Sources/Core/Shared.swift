//
//  Shared.swift
//  Git
//
//  Created by Jake Heiser on 9/1/16.
//
//

import Foundation
import FileKit

let hexCharacters: [Character] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"]
let hexCharacterSet = CharacterSet(charactersIn: "0123456789abcdef")

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
    
    static func read(from path: Path) throws -> Data {
        return try NSData.readFromPath(path) as Data
    }
    
}

extension String {
    
    var isHex: Bool {
        return self.trimmingCharacters(in: hexCharacterSet).isEmpty
    }
    
    func write(to path: Path) throws {
        try writeToPath(path)
    }
    
    public var shortHash: String {
        let length = 7
        if self.characters.count <= length {
            return self
        }
        return substring(to: index(startIndex, offsetBy: length))
    }
    
}
