//
//  Reference.swift
//  Git
//
//  Created by Jake Heiser on 8/21/16.
//
//

import Foundation
import FileKit

public protocol Reference: CustomStringConvertible {
    
    var ref: String { get }
    var hash: String { get }
    var repository: Repository { get }
    
}

extension Reference {
    
    public var name: String {
        return ref.components(separatedBy: "/").last ?? ref
    }
    
    public var object: Object {
        guard let object = repository.objectStore[hash] else {
            fatalError("Broken reference: \(hash)")
        }
        return object
    }
    
}

extension Reference {
    
    public var description: String {
        return "\(name) (\(hash))"
    }
    
}

// MARK: - FolderedRefence

public class FolderedRefence: Reference {
    
    public let ref: String
    public let hash: String
    public let repository: Repository
    
    public convenience init?(path: Path, repository: Repository) {
        guard let hash = try? String.readFromPath(path) else {
            return nil
        }
        
        let ref = (path[(path.endIndex - 3) ..< (path.endIndex - 1)] + path.fileName).rawValue
        let trimmedHash = hash.trimmingCharacters(in: .whitespacesAndNewlines)
        self.init(ref: ref, hash: trimmedHash, repository: repository)
    }
    
    public init(ref: String, hash: String, repository: Repository) {
        self.ref = ref
        self.hash = hash
        self.repository = repository
    }
    
}

// MARK: - ReferenceParser


public class ReferenceParser {
    
    public static func from(name: String, repository: Repository) -> Reference? {
        if let head = repository.head, name == head.name {
            return head
        }
        if let tag = from(ref: "\(Tag.directory)/\(name)", repository: repository) {
            return tag
        }
        if let branch = from(ref: "\(Branch.directory)/\(name)", repository: repository) {
            return branch
        }
        
        return nil
    }
    
    public static func from(ref: String, repository: Repository) -> Reference? {
        let isTag = ref.hasPrefix(Tag.directory)
        
        let potentialPath = repository.subpath(with: ref)
        if potentialPath.exists {
            if isTag {
                return Tag(path: potentialPath, repository: repository)
            }
            return Branch(path: potentialPath, repository: repository)
        }
        
        guard let packedReferences = repository.packedReferences else {
            return nil
        }
        
        let searchRefs: [Reference] = isTag ? packedReferences.tags : packedReferences.branches
        
        var matchingReference: Reference?
        for reference in searchRefs {
            if reference.ref == ref {
                matchingReference = reference
            }
        }
        return matchingReference
    }
    
}
