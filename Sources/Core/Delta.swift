//
//  Delta.swift
//  Git
//
//  Created by Jake Heiser on 8/27/16.
//
//

import Foundation

class Delta {
    
    let data: Data
    
    static func readBaseOffset(using dataReader: DataReader) -> (value: Int, byteCount: Int) {
        var currentByte = dataReader.readByte()
        var offset = currentByte.intValue(ofBits: 1 ..< 8)
        var byteCount = 1
        
        while currentByte[0] == 1 {
            currentByte = dataReader.readByte()
            offset += 1
            offset <<= 7
            offset += currentByte.intValue(ofBits: 1 ..< 8)
            byteCount += 1
        }
        
        return (offset, byteCount)
    }
    
    init(data: Data) {
        self.data = data
    }
    
    func apply(to base: Data) -> Data {
        let deltaReader = DataReader(data: data)
        _ = readVariableLengthInt(using: deltaReader) // Source length
        _ = readVariableLengthInt(using: deltaReader) // Target length
        
        var builtData = Data()
        
        while deltaReader.canRead {
            let instructionByte = deltaReader.readByte()
            
            if instructionByte[0] == 0 { // Insertion
                let insertionByteCount = instructionByte.intValue(ofBits: 1 ..< 8)
                builtData.append(deltaReader.readData(bytes: insertionByteCount))
            } else { // Copy
                var offset = 0
                for bitIndex in 0 ..< 4 {
                    if instructionByte[7 - bitIndex] == 1 {
                        let byte = deltaReader.readInt(bytes: 1)
                        offset |= byte << (bitIndex * 8)
                    }
                }
                
                var size = 0
                for bitIndex in 0 ..< 3 {
                    if instructionByte[3 - bitIndex] == 1 {
                        let byte = deltaReader.readInt(bytes: 1)
                        size |= byte << (bitIndex * 8)
                    }
                }
                if size == 0 {
                    size = 0x10000
                }
                
                builtData.append(base.subdata(in: offset ..< (offset + size)))
            }
        }
        
        return builtData
    }
    
    // MARK: - Helpers
    
    private func readVariableLengthInt(using dataReader: DataReader) -> Int {
        var currentByte: Byte
        var sum = 0
        var byteCount = 0
        repeat {
            currentByte = dataReader.readByte()
            sum |= (currentByte.intValue(ofBits: 1 ..< 8) << byteCount * 8)
            byteCount += 1
        } while currentByte[0] == 1
        
        return sum
    }
    
}
