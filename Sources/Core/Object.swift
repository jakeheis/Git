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
    func generateContentData() -> Data
    
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
    
    public func write() throws {
        try repository.objectStore.write(object: self)
    }
    
    public static func header(for contentData: Data, type: ObjectType) -> Data {
         let header = "\(type.rawValue) \(contentData.count)\0"
        guard let headerData = header.data(using: .ascii) else {
            fatalError("Something went very wrong")
        }
        return headerData
    }
    
    public func header(for contentData: Data) -> Data {
        return Self.header(for: contentData, type: type)
    }
    
    func generateWriteData() -> Data {
        let content = generateContentData()
        var data = header(for: content)
        data.append(content)
        return data
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
}
