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
    var byteCounter = 0
    
    var remainingBytes: Int {
        return data.count - byteCounter
    }
    
    var canRead: Bool {
        return byteCounter != data.count
    }
    
    convenience init?(path: Path) {
        guard let data = try? NSData.readFromPath(path) as Data else {
            return nil
        }
        self.init(data: data)
    }
    
    init(data: Data) {
        self.data = data
    }
    
    @discardableResult
    func readData(bytes: Int) -> Data {
        let subdata = data.subdata(in: byteCounter ..< (byteCounter + bytes))
        byteCounter += bytes
        return subdata
    }
    
    func readByte() -> Byte {
        let data = readData(bytes: 1)
        return Byte(byte: data[0])
    }
    
    func readInt(bytes: Int) -> Int {
        let raw = readData(bytes: bytes)
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
        var currentByte: Byte
        var sum = 0
        var byteCount = 0
        repeat {
            currentByte = readByte()
            sum |= (currentByte.intValue(ofBits: 1 ..< 8) << byteCount * 8)
            byteCount += 1
        } while currentByte[0] == 1
        
        return (sum, byteCount)
    }
    
    func readUntil(byte stopByte: UInt8, skipByte: Bool = true) -> Data {
        var subdata: Data = Data()
        for i in byteCounter ..< data.count {
            let byte = data[i]
            if byte == stopByte {
                break
            }
            subdata.append(byte)
        }
        byteCounter += subdata.count + (skipByte ? 1 : 0)
        return subdata
    }
    
}

struct Byte {
    
    let bits: [UInt8]
    
    init(byte: UInt8) {
        var bits: [UInt8] = []
        for i in UInt8(0) ..< UInt8(8) {
            let bit = (byte >> (7 - i)) & 0b1
            bits.append(bit)
        }
        self.bits = bits
    }
    
    init(bits: [UInt8]) {
        self.bits = bits
    }
    
    subscript(index: Int) -> UInt8 {
        return bits[index]
    }
    
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
