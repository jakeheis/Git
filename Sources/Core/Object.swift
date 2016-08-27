import Foundation
import FileKit
import CryptoSwift

public class Object {
    
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
    
    public enum Error: Swift.Error {
        case readError
        case compressionError
        case parseError
    }
    
    public let hash: String
    public let type: ObjectType
    let repository: Repository
    
    public static func from(file path: Path, in repository: Repository) throws -> Object {
        guard let data = try? NSData.readFromPath(path) else {
            throw Error.readError
        }
        guard let uncompressed = try? data.gzipUncompressed() as Data,
            let unparsed = String(data: uncompressed, encoding: .ascii) else {
                throw Error.compressionError
        }
        
        guard let headerIndex = unparsed.characters.index(of: "\0") else {
            throw Error.parseError
        }
        let header = unparsed.substring(to: headerIndex)
        
        guard let type = ObjectType(header: header) else {
            throw Error.parseError
        }
        
        let hash = path.parent.fileName + path.fileName
        let contentData = uncompressed.subdata(in: (header.characters.count + 1)..<uncompressed.count)
        
        return type.objectClass.init(hash: hash, data: contentData, repository: repository)
    }
    
    public static func from(compressed data: Data, hash: String, type: ObjectType, repository: Repository) throws -> Object {
        guard let uncompressed = data.uncompressed() else {
            throw Error.compressionError
        }
        return type.objectClass.init(hash: hash, data: uncompressed, repository: repository)
    }
    
    public required init(hash: String, data: Data, repository: Repository) {
        fatalError("Use subclass")
    }
    
    init(hash: String, type: ObjectType, repository: Repository) {
        self.hash = hash
        self.type = type
        self.repository = repository
    }
    
    public init(contentData: Data, type: ObjectType, repository: Repository) {
        let header = "\(type.rawValue) \(contentData.count)\0"
        guard let headerData = header.data(using: .utf8) else {
            fatalError("Could not generate header data for blob")
        }
        guard let sha = (headerData + contentData).sha1() else {
            fatalError("Could not hash file")
        }
        self.hash = DataReader(data: sha).readHex(bytes: 20)
        self.type = type
        self.repository = repository
    }
    
    public func cat() -> String {
        return description
    }
    
}

extension Object: CustomStringConvertible {
    
    public var description: String {
        return String(describing: type(of: self)) + " (\(hash))"
    }
    
}
