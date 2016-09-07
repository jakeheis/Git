//
//  DataWriter.swift
//  Git
//
//  Created by Jake Heiser on 9/5/16.
//
//

import Foundation

class DataWriter {
    
    enum Error: Swift.Error {
        case intConversionError
    }
    
    var data = Data()
    
    var length: Int {
        return data.count
    }
    
    func write(data newData: Data) {
        data.append(newData)
    }
    
    func write(byte: UInt8) {
        data.append(byte)
    }
    
    func write(bytes: [UInt8]) {
        data.append(Data(bytes))
    }
    
    func write(int: Int, overBytes bytes: Int) {
        var readingInt = int
        
        var byteArray: [UInt8] = []
        for _ in 0 ..< bytes {
            let byte = UInt8(readingInt & 0xFF)
            byteArray.insert(byte, at: 0) // Big endian
            readingInt >>= 8
        }
        
        write(bytes: byteArray)
    }
    
    func write(octal: String, overBytes bytes: Int) throws {
        guard let octalInt = Int(octal, radix: 8) else {
            throw Error.intConversionError
        }
        write(int: octalInt, overBytes: bytes)
    }
    
    func write(hex: String) {
        let characters = Array(hex.characters)
        for i in stride(from: 0, to: characters.count, by: 2) {
            guard let first = hexCharacters.index(of: characters[i]),
                let second = hexCharacters.index(of: characters[i + 1]) else {
                    fatalError("Corrupt hex: \(hex)")
            }
            
            let byte = second + (first << 4)
            write(byte: UInt8(byte))
        }
    }
    
    func write(byte: Byte) {
        write(byte: UInt8(byte.intValue(ofBits: 0 ..< 8)))
    }
    
    func prepend(data newData: Data) {
        let old = data
        data = newData
        data.append(old)
    }
    
}
