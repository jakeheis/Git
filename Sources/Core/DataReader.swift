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
    
    func readBits(bytes: Int) -> Bits {
        let data = readData(bytes: bytes)
//        var bits: [UInt8] = []
//        for byte in Array(data) {
//            for i in UInt8(0) ..< UInt8(8) {
//                let bit = (byte >> (7 - i)) & 0b1
//                bits.append(bit)
//            }
//        }
        return Bits(bytes: Array(data))
    }
    
    func readInt(bytes: Int) -> Int {
        let raw = Array(readData(bytes: bytes))
        var int: Int = 0
        for i in 0 ..< raw.count {
            int |= Int(raw[raw.count - i - 1]) << (i * 8)
        }
        return int
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
        var currentByte: Bits
        var sum = 0
        var byteCount = 0
        repeat {
            currentByte = readBits(bytes: 1)
            sum |= (currentByte.intValue(ofBits: 1 ..< 8) << byteCount * 8)
            byteCount += 1
        } while currentByte[0] == 1
        
        return (sum, byteCount)
    }
    
}

struct Bits {
    
//    let bytes: [UInt8]
    let bits: [UInt8]
    
    init(byte: UInt8) {
        self.init(bytes: [byte])
    }
    
    init(bytes: [UInt8]) {
//        self.bytes = bytes
        
        var bits: [UInt8] = []
        for byte in bytes {
            for i in UInt8(0) ..< UInt8(8) {
                let bit = (byte >> (7 - i)) & 0b1
                bits.append(bit)
            }
        }
        self.bits = bits
    }
    
    init(bits: [UInt8]) {
        self.bits = bits
    }
    
//    var raw: [UInt8] {
//        var bits: [UInt8] = []
//        for byte in bytes {
//            for i in UInt8(0) ..< UInt8(8) {
//                let bit = (byte >> (7 - i)) & 0b1
//                bits.append(bit)
//            }
//        }
//        return bits
//    }
    
//    var intValue: Int {
//        var total = 0
//        for i in 0 ..< bytes.count {
////            let multiplier = Int(pow(Double(2), Double(i)))
////            let byte = bytes[bytes.count - i / 8 - 1]
////            let bit = 8 - i % 8
////            total += Int(byte[bit]) * multiplier
//            
//        }
//        return total
//    }
    
    func intValue(ofBits range: CountableRange<Int>) -> Int {
        var sum = 0
        for i in range {
            if bits[i] == 1 {
                sum |= 1 << (range.upperBound - i - 1)
            }
        }
        return sum
    }
    
}

extension Bits {
    
//    var startIndex: Int {
//        return bytes.startIndex
//    }
//    
//    var endIndex: Int {
//        return bytes.endIndex * 8
//    }
//    
//    subscript(index: Int) -> UInt8 {
//        let byte = bytes[index / 8]
//        let bitIndex = UInt8(7 - index % 8)
//        return byte & (1 << bitIndex)
//    }
////
//    subscript(bounds: Range<Int>) -> Bits {
//        return self
//    }
//    
//    func index(after i: Int) -> Int {
//        return i + 1
//    }
    
//    var startIndex: Int {
//        return bits.startIndex
//    }
//    
//    var endIndex: Int {
//        return bits.endIndex
//    }
//    
    subscript(index: Int) -> UInt8 {
        return bits[index]
    }
//    
//    subscript(bounds: Range<Int>) -> Bits {
//        return Bits(bits: Array(bits[bounds]))
//    }
//    
//    func index(after i: Int) -> Int {
//        return i + 1
//    }
    
}

public protocol BitToIntConvertible {}
extension UInt8: BitToIntConvertible {}

public extension Array where Element : BitToIntConvertible {
//    public func bitIntValue() -> Int {
//        var total = 0
//        for i in 0 ..< count {
//            let multiplier = Int(pow(Double(2), Double(i)))
//            total += Int(self[count - i - 1] as! UInt8) * multiplier
//        }
//        return total
//    }
}
