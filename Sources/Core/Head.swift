//
//  Head.swift
//  Git
//
//  Created by Jake Heiser on 8/24/16.
//
//

import Foundation
import FileKit

public class Head {
   
    public enum Kind {
        case hash(String)
        case reference(Reference)
    }
    
    public let kind: Kind
    let repository: Repository
    
    public var commit: Commit? {
        switch kind {
        case let .hash(hash): return repository.objectStore[hash] as? Commit
        case let .reference(reference): return reference.object as? Commit
        }
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
            
            guard let reference = Reference(ref: refText, repository: repository) else {
                fatalError("Broken HEAD: \(refText)")
            }
            self.kind = .reference(reference)
        } else {
            self.kind = .hash(text.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        self.repository = repository
    }
    
}

extension Head: CustomStringConvertible {
    
    public var description: String {
        return "HEAD: \(commit?.hash ?? "(none)")"
    }
    
}

extension Repository {
    
    public var head: Head? {
        get {
            return Head(repository: self)
        }
    }
    
}
