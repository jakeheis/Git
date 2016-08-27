//
//  DataReader.swift
//  Git
//
//  Created by Jake Heiser on 8/22/16.
//
//

import Foundation
import FileKit

class DataReader {
    
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
    func readData(bytes: Int) -> Data {
        let subdata = data.subdata(in: byteCounter ..< (byteCounter + bytes))
        // Can't just use substring (like other read methods use) because String considers \r\n one character and messes up the offset
        let remainingData = data.subdata(in: (byteCounter + bytes) ..< data.count)
        unread = String(data: remainingData, encoding: .ascii)! // ! allowed 
        byteCounter += bytes
        return subdata
    }
    
    func readBits(bytes: Int) -> [UInt8] {
        let data = readData(bytes: bytes)
        var bits: [UInt8] = []
        for byte in Array(data) {
            for i in UInt8(0) ..< UInt8(8) {
                let bit = (byte >> (7 - i)) & 0b1
                bits.append(bit)
            }
        }
        return bits
    }
    
    func readInt(bytes: Int) -> Int {
        return readBits(bytes: bytes).bitIntValue()
    }
    
    func readOctal(bytes: Int) -> String {
        return String(readInt(bytes: bytes), radix: 8)
    }
    
    func readHex(bytes: Int) -> String {
        // Can't use same line as readOctal becuase of Int overflow issues
        let hexData = readData(bytes: bytes)
        var hexString = ""
        for byte in hexData {
            hexString += String(format: "%02x", byte)
        }
        return hexString
    }
    
    func readVariableLengthInt() -> (value: Int, bytes: Int) {
        var allBits: [UInt8] = []
        var byteCount = 0
        var currentBits: [UInt8]
        repeat {
            currentBits = readBits(bytes: 1)
            allBits = currentBits[1 ..< 8] + allBits
            byteCount += 1
        } while currentBits[0] == 1
        
        return (allBits.bitIntValue(), byteCount)
    }
    
}

protocol BitToIntConvertible {}
extension UInt8: BitToIntConvertible {}

extension Array where Element : BitToIntConvertible {
    func bitIntValue() -> Int {
        var total = 0
        for i in 0 ..< count {
            let multiplier = Int(pow(Double(2), Double(i)))
            total += Int(self[count - i - 1] as! UInt8) * multiplier
        }
        return total
    }
}
