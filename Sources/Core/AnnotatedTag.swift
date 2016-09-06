//
//  AnnotatedTag.swift
//  Git
//
//  Created by Jake Heiser on 8/21/16.
//
//

import Foundation
import FileKit

final public class AnnotatedTag: Object {
    
    public let hash: String
    public let repository: Repository
    public let type: ObjectType = .tag
    
    public let objectHash: String
    public let tagType: ObjectType
    public let name: String
    public let taggerSignature: Signature
    public let message: String
    
    public var object: Object {
        guard let object = repository.objectStore[objectHash] else {
            fatalError("Corrupt tag pointing to hash: \(objectHash)")
        }
        return object
    }
    
    public init(hash: String, data: Data, repository: Repository) {
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
        self.taggerSignature = Signature(signature: lineValues[3])
        self.message = lines[5 ..< lines.index(before: lines.endIndex)].joined(separator: "\n")
        
        self.hash = hash
        self.repository = repository
    }
    
    public func cat() -> String {
        let lines = [
            "object \(objectHash)",
            "type \(tagType.rawValue)",
            "tag \(name)",
            "tagger \(taggerSignature)",
            "",
            message
        ]
        return lines.joined(separator: "\n")
    }
    
    public func generateContentData() -> Data {
        return Data()
    }
    
}
