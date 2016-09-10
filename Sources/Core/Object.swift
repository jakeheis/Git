//
//  Object.swift
//  Git
//
//  Created by Jake Heiser on 9/1/16.
//
//

import Foundation
import FileKit

public protocol Object: CustomStringConvertible {
    
    var hash: String { get }
    var type: ObjectType { get }
    var repository: Repository { get }
    
    init(hash: String, data: Data, repository: Repository)
    
    func cat() -> String
    
}


// MARK: - Additional functionality

extension Object {
    
    public static func read(from file: Path, in repository: Repository) throws -> Self {
        let object = try repository.objectStore.readObject(from: file)
        guard let typedObject = object as? Self else {
            throw ObjectStore.Error.parseError
        }
        return typedObject
    }
    
}

// MARK: - Defaults

extension Object {
    
    public var description: String {
        return String(describing: type(of: self)) + " (\(hash))"
    }
    
}

// MARK: - ObjectType

public enum ObjectType: String {
    
    case blob
    case commit
    case tree
    case tag
    
    var objectClass: Object.Type {
        switch self {
        case .blob: return Blob.self
        case .commit: return Commit.self
        case .tree: return Tree.self
        case .tag: return AnnotatedTag.self
        }
    }
    
    init<T: Object>(objectClass: T.Type) {
        if objectClass == Blob.self {
            self = .blob
        } else if objectClass == Commit.self {
            self = .commit
        } else if objectClass == Tree.self {
            self = .tree
        } else {
            self = .tag
        }
    }
    
}
