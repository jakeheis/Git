//
//  Head.swift
//  Git
//
//  Created by Jake Heiser on 8/24/16.
//
//

import Foundation
import FileKit

final public class Head: Reference {
   
    public enum Kind {
        case hash(String)
        case reference(Reference)
    }
    
    public let ref = "HEAD"
    public var hash: String {
        switch kind {
        case let .hash(hash): return hash
        case let .reference(reference): return reference.hash
        }
    }
    public let repository: Repository
    
    public let kind: Kind
    
    public var commit: Commit? {
        return object as? Commit
    }
    
    convenience init?(repository: Repository) {
        guard let contents = try? String.readFromPath(repository.subpath(with: "HEAD")) else {
            return nil
        }
        self.init(text: contents, repository: repository)
    }
    
    init(text: String, repository: Repository) {
        if text.hasPrefix("ref: "), let refSpace = text.characters.index(of: " ") {
            let startIndex = text.index(after: refSpace)
            let refText = text.substring(with: startIndex ..< text.endIndex).trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard let reference = ReferenceParser.from(ref: refText, repository: repository) else {
                fatalError("Broken HEAD: \(refText)")
            }
            self.kind = .reference(reference)
        } else {
            self.kind = .hash(text.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        self.repository = repository
    }
    
}

// MARK: -

extension Repository {
    
    public var head: Head? {
        return Head(repository: self)
    }
    
}
