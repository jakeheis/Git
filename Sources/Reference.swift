//
//  Reference.swift
//  Git
//
//  Created by Jake Heiser on 8/21/16.
//
//

import Foundation
import FileKit

class Reference {
    
    let path: Path
    let hash: String
    let repository: Repository
    
    var name: String {
        return path.fileName
    }
    
    var object: Object {
        guard let object = repository.objectStore[hash] else {
            fatalError("Broken reference: \(hash)")
        }
        return object
    }
    
    init?(path: Path, repository: Repository) {
        guard let hash = try? String.readFromPath(path) else {
            return nil
        }
        
        self.path = path
        self.hash = hash.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        self.repository = repository
    }
    
}

extension Reference: CustomStringConvertible {
    
    var description: String {
        return "\(name) (\(hash))"
    }
    
}
