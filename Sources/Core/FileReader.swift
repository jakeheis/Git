//
//  FileReader.swift
//  Git
//
//  Created by Jake Heiser on 8/22/16.
//
//

import Foundation
import FileKit

class FileReader {
    
    let data: Data
    
    var unread: String
    var byteCounter = 0
    
    var canRead: Bool {
        return !unread.isEmpty
    }
    
    convenience init?(path: Path) {
        guard let data = try? NSData.readFromPath(path) as Data else {
            return nil
        }
        self.init(data: data)
    }
    
    init?(data: Data) {
        guard let contents = String(data: data, encoding: .ascii) else {
            return nil
        }
        
        self.data = data
        self.unread = contents
    }
    
    @discardableResult
    func readCharacter() -> String {
        return read(next: 1)
    }
    
    @discardableResult
    func read(next count: Int) -> String {
        let toIndex = unread.index(unread.startIndex, offsetBy: count)
        return read(to: toIndex)
    }
    
    func read(until character: Character, skipCharacter: Bool = true) -> String {
        let characterIndex = unread.characters.index(of: character) ?? unread.endIndex
        let retVal = read(to: characterIndex)
        if skipCharacter && canRead {
            readCharacter()
        }
        return retVal
    }
    
    func read(to index: String.Index) -> String {
        byteCounter += unread.distance(from: unread.startIndex, to: index)
        let retVal = unread.substring(to: index)
        unread = unread.substring(from: index)
        return retVal
    }
    
    @discardableResult
    func readData(length: Int) -> Data {
        let subdata = data.subdata(in: byteCounter ..< (byteCounter + length))
        // Can't just use substring (like other read methods use) because String considers \r\n one character and messes up the offset
        let remainingData = data.subdata(in: (byteCounter + length) ..< data.count)
        unread = String(data: remainingData, encoding: .ascii)! // ! allowed 
        byteCounter += length
        return subdata
    }
    
    func readBinary(length: Int) -> String? {
        guard let hex = readHexInt(length: length) else {
            return nil
        }
        return String(hex, radix: 2)
    }
    
    func readHex(length: Int) -> String {
        let hexData = readData(length: length)
        var hexString = ""
        for byte in hexData {
            hexString += String(format: "%02x", byte)
        }
        return hexString
    }
    
    func readHexInt(length: Int) -> Int? {
        let hex = readHex(length: length)
        return Int(hex, radix: 16)
    }
    
}
