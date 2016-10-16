//
//  Head.swift
//  Git
//
//  Created by Jake Heiser on 8/24/16.
//
//

import Foundation
import FileKit

public class Head: AlternatingReference {
    
    public static let name = "HEAD"
    
    public var commit: Commit? {
        return repository.objectStore[kind.hash] as? Commit
    }
    
    init?(repository: Repository) {
        super.init(ref: Ref(Head.name), path: repository.subpath(with: Head.name), repository: repository)
    }
    
}

// MARK: -

extension Repository {
    
    public var head: Head? {
        return Head(repository: self)
    }
    
}
