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
    
    public var object: GitObject {
        guard let object = repository.objectStore[hash] else {
            fatalError("Broken reference: \(hash)")
        }
        return object
    }
    
    static func packedRefs(in repository: Repository) -> [Reference] {
        guard let packedRefsText = try? String.readFromPath(repository.subpath(with: "packed-refs")) else {
            return []
        }
        
        let lines = packedRefsText.components(separatedBy: "\n")
        var refs: [Reference] = []
        
        for line in lines where !line.hasPrefix("#") { // No comments
            let words = line.components(separatedBy: " ")
            if let ref = words.last, let hash = words.first {
                if ref.hasPrefix(Tag.directory) {
                    refs.append(Tag(ref: ref, hash: hash, repository: repository))
                } else if ref.hasPrefix(Branch.directory) {
                    refs.append(Branch(ref: ref, hash: hash, repository: repository))
                }
            }
        }
        
        return refs
    }
    
    public convenience init?(ref: String, repository: Repository) {
        let potentialPath = repository.subpath(with: ref)
        if potentialPath.exists {
            self.init(path: potentialPath, repository: repository)
        } else {
            var potentialHash: String? = nil
            for reference in Reference.packedRefs(in: repository) {
                if reference.ref == ref {
                    potentialHash = reference.hash
                }
            }
            guard let hash = potentialHash else {
                return nil
            }
            self.init(ref: ref, hash: hash, repository: repository)
        }
    }
    
    public init?(path: Path, repository: Repository) {
        guard let hash = try? String.readFromPath(path) else {
            return nil
        }
        
        self.ref = (path[(path.endIndex - 3) ..< (path.endIndex - 1)] + path.fileName).rawValue
        self.hash = hash.trimmingCharacters(in: .whitespacesAndNewlines)
        self.repository = repository
    }
    
    public init(ref: String, hash: String, repository: Repository) {
        self.ref = ref
        self.hash = hash
        self.repository = repository
    }
    
}

extension Reference: CustomStringConvertible {
    
    public var description: String {
        return "\(name) (\(hash))"
    }
    
}
