//
//  AnnotatedTag.swift
//  Git
//
//  Created by Jake Heiser on 8/21/16.
//
//

import Foundation
import FileKit

class AnnotatedTag: Object {
    
    let objectHash: String
    let tagType: ObjectType
    let name: String
    let taggerString: String
    let message: String
    
    var object: Object {
        guard let object = try? Object.from(hash: objectHash, in: repository) else {
            fatalError("Corrupt tag pointing to hash: \(objectHash)")
        }
        return object
    }
    
    required init(hash: String, data: Data, repository: Repository) {        
        let lines = String(data: data, encoding: .ascii)!.components(separatedBy: "\n")
        
        let infoLines = lines[0 ..< 4]
        let lineValues: [String] = infoLines.map { (line) in
            var words = line.components(separatedBy: " ")
            _ = words.removeFirst()
            return words.joined(separator: " ")
        }

        objectHash = lineValues[0]
        guard let tagType = ObjectType(rawValue: lineValues[1]) else {
            fatalError("Unrecognized tag type: \(lineValues[1])")
        }
        self.tagType = tagType
        self.name = lineValues[2]
        self.taggerString = lineValues[3]
        self.message = lines[5 ..< lines.index(before: lines.endIndex)].joined(separator: "\n")
        
        super.init(hash: hash, data: data, type: .blob, repository: repository)
    }
    
    func print() {
        Swift.print(objectHash, tagType, name, taggerString, message)
    }
    
}
