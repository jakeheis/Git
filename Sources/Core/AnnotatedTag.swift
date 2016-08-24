//
//  AnnotatedTag.swift
//  Git
//
//  Created by Jake Heiser on 8/21/16.
//
//

import Foundation
import FileKit

public class AnnotatedTag: Object {
    
    public let objectHash: String
    public let tagType: ObjectType
    public let name: String
    public let tagger: Signature
    public let message: String
    
    public var object: Object {
        guard let object = repository.objectStore[objectHash] else {
            fatalError("Corrupt tag pointing to hash: \(objectHash)")
        }
        return object
    }
    
    public required init(hash: String, data: Data, repository: Repository) {
        guard let contents = String(data: data, encoding: .ascii) else {
            fatalError("Couldn't read object \(hash)")
        }
        let lines = contents.components(separatedBy: "\n")
        
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
        self.tagger = Signature(signature: lineValues[3])
        self.message = lines[5 ..< lines.index(before: lines.endIndex)].joined(separator: "\n")
        
        super.init(hash: hash, type: .blob, repository: repository)
    }
    
    public func print() {
        Swift.print(objectHash, tagType, name, tagger, message)
    }
    
}
