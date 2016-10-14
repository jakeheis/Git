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
    
    func update(hash: String) throws
    func write() throws
    
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

// MARK: - SymbolicReference

public protocol SymbolicReference: Reference {
    var dereferenced: Reference { get }
}

// MARK: - LoggedReference

public protocol LoggedReference: Reference {
    var reflog: Reflog { get }
}

public extension LoggedReference {
    
    func update(hash: String, message: String) throws {
        guard let signature = Signature.currentUser() else {
            throw LoggedReferenceError.invalidSignature
        }
        let entry = ReflogEntry(oldHash: self.hash, newHash: hash, signature: signature, message: message)
        try update(hash: hash)
        try reflog.append(entry: entry)
    }
    
}

enum LoggedReferenceError: Error {
    case invalidSignature
}

// MARK: - FolderedRefence

public class FolderedRefence: Reference {
    
    public let ref: String
    private(set) public var hash: String
    public let repository: Repository
    
    public init(ref: String, hash: String, repository: Repository) {
        self.ref = ref
        self.hash = hash
        self.repository = repository
    }
    
    public func update(hash: String) throws {
        self.hash = hash
        try write()
    }
    
    public func write() throws {
        let path = repository.subpath(with: ref)
        try (hash + "\n").write(to: path)
    }
    
}

// MARK: - ReferenceParser


public class ReferenceParser {
    
    public static func parse(raw: String, repository: Repository) -> Reference? {
        if raw.hasPrefix("refs") {
            return from(ref: raw, repository: repository)
        }
        
        if let head = repository.head, raw == head.name {
            return head
        }
        if let tag = from(ref: "\(Tag.directory)/\(raw)", repository: repository) {
            return tag
        }
        if let branch = from(ref: "\(Branch.directory)/\(raw)", repository: repository) {
            return branch
        }
        
        return nil
    }
    
    public static func from(ref: String, repository: Repository) -> Reference? {
        if let reference = from(file: repository.subpath(with: ref), repository: repository) {
            return reference
        }
        
        return unpack(ref: ref, repository: repository)
    }
    
    public static func from(file: Path, repository: Repository) -> Reference? {
        guard file.exists, let hash = try? String.readFromPath(file) else {
            return nil
        }
        
        let ref = (file[(file.endIndex - 3) ..< (file.endIndex - 1)] + file.fileName).rawValue
        let trimmedHash = hash.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if ref.hasPrefix(Tag.directory) {
            return Tag(ref: ref, hash: trimmedHash, repository: repository)
        }
        return Branch(ref: ref, hash: trimmedHash, repository: repository)
    }
    
    public static func unpack(ref: String, repository: Repository) -> Reference? {
        guard let packedReferences = repository.packedReferences else {
            return nil
        }
        
        let searchRefs: [Reference] = ref.hasPrefix(Tag.directory) ? packedReferences.tags : packedReferences.branches
        
        var matchingReference: Reference?
        for reference in searchRefs {
            if reference.ref == ref {
                matchingReference = reference
            }
        }
        return matchingReference
    }
    
}
