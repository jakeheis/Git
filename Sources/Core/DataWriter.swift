//
//  DataWriter.swift
//  Git
//
//  Created by Jake Heiser on 9/5/16.
//
//

import Foundation

class DataWriter {
    
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
    
    func prepend(data newData: Data) {
        let old = data
        data = newData
        data.append(old)
    }
    
}
