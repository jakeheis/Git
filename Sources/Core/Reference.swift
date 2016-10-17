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
    
    var ref: Ref { get }
    var hash: String { get }
    var repository: Repository { get }
    
    func update(hash: String) throws
    func write() throws
    
}

enum LoggedReferenceError: Error {
    case invalidSignature
}

extension Reference {
    
    public var name: String {
        return ref.name
    }
    
    public var object: Object {
        guard let object = repository.objectStore[hash] else {
            fatalError("Broken reference: \(hash)")
        }
        return object
    }
    
    public func recordUpdate(message: String?, update: (_ reference: Reference) throws -> ()) throws {
        let before = hash
        try update(self)
        let after = hash
        
        try recordUpdate(message: message, from: before, to: after)
    }
    
    public func recordUpdate(message: String?, from old: String, to new: String) throws {
        let reflog = Reflog(ref: ref, repository: repository)
        guard let signature = Signature.currentUser() else {
            throw LoggedReferenceError.invalidSignature
        }
        let entry = ReflogEntry(oldHash: old, newHash: new, signature: signature, message: message)
        try reflog.append(entry: entry)
    }
    
    public func equals(_ rhs: Reference) -> Bool {
        return self.ref == rhs.ref && self.hash == rhs.hash
    }
    
}

extension Reference {
    
    public var description: String {
        return "\(name) (\(hash))"
    }
    
}

// MARK: - SimpleReference

public class SimpleReference: Reference {
    
    public let ref: Ref
    private(set) public var hash: String
    public let repository: Repository
    
    public init(ref: Ref, hash: String, repository: Repository) {
        self.ref = ref
        self.hash = hash
        self.repository = repository
    }
    
    public func update(hash: String) throws {
        self.hash = hash
        
        try self.write()
    }
    
    public func write() throws {
        let path = repository.subpath(with: ref.path)
        try (hash + "\n").write(to: path)
    }
    
}

// MARK: - SymbolicReference

public class SymbolicReference {
    
    static let prefix = "ref: "
    
    public let ref: Ref
    public let dereferenced: Reference
    public let repository: Repository
    
    public init?(ref: Ref, text: String, repository: Repository) {
        guard let refSpace = text.characters.index(of: " ") else {
            return nil
        }
        let startIndex = text.index(after: refSpace)
        let refText = text.substring(with: startIndex ..< text.endIndex).trimmingCharacters(in: .whitespacesAndNewlines)
        guard let reference = repository.referenceStore[Ref(refText)] else {
            return nil
        }
        self.ref = ref
        self.dereferenced = reference
        self.repository = repository
    }
    
    public init(ref: Ref, dereferenced: Reference, repository: Repository) {
        self.ref = ref
        self.dereferenced = dereferenced
        self.repository = repository
    }
    
    public func write() throws {
        let path = repository.subpath(with: ref.path)
        try "ref: \(dereferenced.ref.path)\n".write(to: path)
    }
    
    public func recordDereferencedUpdate(message: String?, update: (_ reference: Reference) throws -> ()) throws {
        let before = dereferenced.hash
        try dereferenced.recordUpdate(message: message, update: update)
        let after = dereferenced.hash
        
        let reflog = Reflog(ref: ref, repository: repository)
        guard let signature = Signature.currentUser() else {
            throw LoggedReferenceError.invalidSignature
        }
        let entry = ReflogEntry(oldHash: before, newHash: after, signature: signature, message: message)
        try reflog.append(entry: entry)
    }
    
}

// MARK: - Alternating reference

public class AlternatingReference {
    
    public enum Kind {
        case simple(SimpleReference)
        case symbolic(SymbolicReference)
        
        public var hash: String {
            switch self {
            case .simple(let simple): return simple.hash
            case .symbolic(let symbolic): return symbolic.dereferenced.hash
            }
        }
    }
    
    public let ref: Ref
    private(set) public var kind: Kind
    public let repository: Repository
    
    init?(ref: Ref, path: Path, repository: Repository) {
        guard let contents = try? String.read(from: path) else {
            return nil
        }
        
        if contents.hasPrefix(SymbolicReference.prefix) {
            guard let symbolicReference = SymbolicReference(ref: ref, text: contents, repository: repository) else {
                fatalError("Broken symbolic ref: \(contents)")
            }
            
            self.kind = .symbolic(symbolicReference)
        } else {
            let hash = contents.trimmingCharacters(in: .whitespacesAndNewlines)
            self.kind = .simple(SimpleReference(ref: ref, hash: hash, repository: repository))
        }
        self.ref = ref
        self.repository = repository
    }
    
    public func updateUnderlying(to hash: String, message: String?) throws {
        let update = { (reference: Reference) in
            try reference.update(hash: hash)
        }
        
        switch kind {
        case let .simple(simple):
            try simple.recordUpdate(message: message, update: update)
        case let .symbolic(symbolic):
            try symbolic.recordDereferencedUpdate(message: message, update: update)
        }
    }
    
    public func update(toSimple hash: String, message: String?) throws {
        try update(to: .simple(SimpleReference(ref: ref, hash: hash, repository: repository)), message: message)
    }
    
    public func update(toSymbolic reference: Reference, message: String?) throws {
        try update(to: .symbolic(SymbolicReference(ref: ref, dereferenced: reference, repository: repository)), message: message)
    }
    
    private func update(to kind: Kind, message: String?) throws {
        guard let signature = Signature.currentUser() else {
            throw LoggedReferenceError.invalidSignature
        }
        
        let reflog = Reflog(ref: ref, repository: repository)
        let entry = ReflogEntry(oldHash: self.kind.hash, newHash: kind.hash, signature: signature, message: message)
        try reflog.append(entry: entry)
        
        self.kind = kind
        
        try self.write()
    }
    
    public func write() throws {
        switch kind {
        case .simple(let simple): try simple.write()
        case .symbolic(let symbolic): try symbolic.write()
        }
    }
    
}

// MARK: - Ref

public struct Ref {
    
    static let prefix = "refs"
    static let tags = Ref.prefix + "/tags"
    static let branches = Ref.prefix + "/heads"
    
    public let path: String
    
    public var name: String {
        return path.components(separatedBy: "/").last!
    }
    
    public var isTag: Bool {
        return path.hasPrefix(Ref.tags)
    }
    
    public var isBranch: Bool {
        return path.hasPrefix(Ref.branches)
    }
    
    public init(_ text: String) {
        self.path = text
    }
    
}

extension Ref: ExpressibleByStringLiteral {
    
    public typealias StringLiteralType = String
    public typealias UnicodeScalarLiteralType = String
    public typealias ExtendedGraphemeClusterLiteralType = String
    
    public init(stringLiteral value: String) {
        path = value
    }
    
    public init(unicodeScalarLiteral value: String) {
        path = value
    }
    
    public init(extendedGraphemeClusterLiteral value: String) {
        path = value
    }
    
}

extension Ref: Hashable {
    
    public var hashValue: Int {
        return path.hashValue
    }
    
}

public func == (lhs: Ref, rhs: Ref) -> Bool {
    return lhs.path == rhs.path
}
