//
//  Reference.swift
//  Git
//
//  Created by Jake Heiser on 8/21/16.
//
//

import Foundation
import FileKit

public class Reference {
    
    public let ref: String
    public let hash: String
    let repository: Repository
    
    public var name: String {
        return ref.components(separatedBy: "/").last ?? ref
    }
    
    public var object: Object {
        guard let object = repository.objectStore[hash] else {
            fatalError("Broken reference: \(hash)")
        }
        return object
    }
    
    public init?(ref: String, repository: Repository) {
        if let hash = try? String.readFromPath(repository.subpath(with: ref)) {
            self.hash = hash.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            guard let packedRefs = try? String.readFromPath(repository.subpath(with: "packed-refs")) else {
                return nil
            }
            let lines = packedRefs.components(separatedBy: "\n")
            
            var possibleHash: String?
            for line in lines where !line.hasPrefix("#") { // No comments
                let words = line.components(separatedBy: " ")
                if let word = words.last, word == ref, let hash = words.first {
                    possibleHash = hash
                }
            }
            
            guard let hash = possibleHash else {
                return nil
            }
            self.hash = hash
        }
        
        self.ref = ref
        self.repository = repository
    }
    
}

extension Reference: CustomStringConvertible {
    
    public var description: String {
        return "\(name) (\(hash))"
    }
    
}
