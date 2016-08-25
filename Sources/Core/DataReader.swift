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
    
    func readNumberAsString(bytes: Int, radix: Int) -> String {
        let binary = readBits(bytes: bytes).map({ String($0) }).joined()
        let rawValue = Int(binary, radix: 2)! // Will only fail if overflow
        return String(rawValue, radix: radix)
    }
    
    func readOctal(bytes: Int) -> String {
        return readNumberAsString(bytes: bytes, radix: 8)
    }
    
    func readDecimal(bytes: Int) -> String {
        return readNumberAsString(bytes: bytes, radix: 10)
    }
    
    func readHex(bytes: Int) -> String {
        let hexData = readData(bytes: bytes)
        var hexString = ""
        for byte in hexData {
            hexString += String(format: "%02x", byte)
        }
        return hexString
    }
    
    func readInt(bytes: Int) -> Int? {
        return Int(readDecimal(bytes: bytes))
    }
    
}

/*class BitReader {
    
    let bytes: [UInt8]
    var bitCounter = 0
    
    var bitCount: Int {
        return bytes.count * 8
    }
    
    var remainingBitCount: Int {
        return bitCount - bitCounter
    }
    
    init(byte: UInt8) {
        self.bytes = [byte]
    }
    
    init(bytes: [UInt8]) {
        self.bytes = bytes
    }
    
    func readBits(count: Int) -> [UInt8] {
        var bits: [UInt8] = []
        for i in UInt8(bitCounter) ..< UInt8(bitCounter + count) {
            let byte = bytes[Int(i / 8)]
            let bit = (byte >> (7 - (i % 8))) & 0b1
            bits.append(bit)
        }
        return bits
    }
    
    func readChunks(bitCount: Int, chunkSize: Int) -> [[UInt8]] {
        let bits = readBits(count: bitCount)
        let padding = Array(repeating: UInt8(0), count: (chunkSize - bits.count % chunkSize))
        let chunkBits = padding + bits
        print(chunkBits)
        var chunks: [[UInt8]] = []
        for i in stride(from: 0, to: chunkBits.count, by: chunkSize) {
            chunks.append(Array(chunkBits[i ..< (i + chunkSize)]))
        }
        return chunks
    }
    
    func readNumber(bitCount: Int, radix: Int) -> String {
        let chunkSize = Int(log(Double(radix)) / log(2))
        let chunks = readChunks(bitCount: bitCount, chunkSize: chunkSize)
        
        print(chunks)
        
        var string = ""
        for chunk in chunks {
            var number = 0
            for (index, bit) in chunk.reversed().enumerated() {
                print(index, bit, Int(pow(Double(2), Double(index))))
                number += Int(bit) * Int(pow(Double(2), Double(index)))
            }
            string += String(number)
        }
        return string
    }
    
    func readBinary() -> String {
        return readNumber(bitCount: bitCount, radix: 2)
    }
    
}*/
