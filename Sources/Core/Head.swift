//
//  Head.swift
//  Git
//
//  Created by Jake Heiser on 8/24/16.
//
//

import Foundation
import FileKit

final public class Head {
    
    public static let name = "HEAD"
   
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
    
    public let repository: Repository
    private(set) public var kind: Kind
    let reflog: Reflog
    
    public var commit: Commit? {
        return repository.objectStore[kind.hash] as? Commit
    }
    
    convenience init?(repository: Repository) {
        guard let contents = try? String.readFromPath(repository.subpath(with: Head.name)) else {
            return nil
        }
        self.init(text: contents, repository: repository)
    }
    
    init(text: String, repository: Repository) {
        if text.hasPrefix(SymbolicReference.prefix) {
            guard let symbolicReference = SymbolicReference(ref: Ref(Head.name), text: text, repository: repository) else {
                fatalError("Broken HEAD: \(text)")
            }
            
            self.kind = .symbolic(symbolicReference)
        } else {
            let hash = text.trimmingCharacters(in: .whitespacesAndNewlines)
            self.kind = .simple(SimpleReference(ref: Ref(Head.name), hash: hash, repository: repository))
        }
        self.repository = repository
        
        self.reflog = Reflog(ref: Ref(Head.name), repository: repository)
    }
    
    public func update(to hash: String, message: String?) throws {
        try update(to: .simple(SimpleReference(ref: Ref(Head.name), hash: hash, repository: repository)), message: message)
    }
    
    public func update(to reference: Reference, message: String?) throws {
        try update(to: .symbolic(SymbolicReference(ref: Ref(Head.name), dereferenced: reference, repository: repository)), message: message)
    }
    
    public func update(to kind: Kind, message: String?) throws {
        guard let signature = Signature.currentUser() else {
            throw LoggedReferenceError.invalidSignature
        }

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

// MARK: -

extension Repository {
    
    public var head: Head? {
        return Head(repository: self)
    }
    
}
