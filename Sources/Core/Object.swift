import Foundation
import FileKit

public protocol Object: CustomStringConvertible {
    
    var hash: String { get }
    var type: ObjectType { get }
    var repository: Repository { get }
    
    init(hash: String, data: Data, repository: Repository)
    
    func cat() -> String
    
}

// MARK: - ObjectType

public enum ObjectType: String {
    case blob
    case commit
    case tree
    case tag
    
    init?(header: String) {
        guard let firstWord = header.components(separatedBy: " ").first else {
            return nil
        }
        self.init(rawValue: firstWord)
    }
    
    var objectClass: Object.Type {
        switch self {
        case .blob: return Blob.self
        case .commit: return Commit.self
        case .tree: return Tree.self
        case .tag: return AnnotatedTag.self
        }
    }
}

// MARK: - Additional functionality

extension Object {
    
    public static func parse(from file: Path, in repository: Repository) throws -> Self {
        let object = try repository.objectStore.parseObject(from: file, in: repository)
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
