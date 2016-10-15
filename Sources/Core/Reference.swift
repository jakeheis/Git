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
    
    public func recordUpdate(message: String?, update: () throws -> ()) throws {
        let before = hash
        try update()
        let after = hash
        
        let reflog = Reflog(ref: ref, repository: repository)
        guard let signature = Signature.currentUser() else {
            throw LoggedReferenceError.invalidSignature
        }
        let entry = ReflogEntry(oldHash: before, newHash: after, signature: signature, message: message)
        try reflog.append(entry: entry)

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
