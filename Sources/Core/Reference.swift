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
    
    public let path: Path
    public let hash: String
    let repository: Repository
    
    public var name: String {
        return path.fileName
    }
    
    public var object: Object {
        guard let object = repository.objectStore[hash] else {
            fatalError("Broken reference: \(hash)")
        }
        return object
    }
    
    public init?(path: Path, repository: Repository) {
        guard let hash = try? String.readFromPath(path) else {
            return nil
        }
        
        self.path = path
        self.hash = hash.trimmingCharacters(in: .whitespacesAndNewlines)
        self.repository = repository
    }
    
}

extension Reference: CustomStringConvertible {
    
    public var description: String {
        return "\(name) (\(hash))"
    }
    
}
