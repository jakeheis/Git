import Foundation
import FileKit

class Object {
    
    let hash: String
    let type: ObjectType
    let repository: Repository
    
    enum ObjectType: String {
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
    
    enum Error: Swift.Error {
        case readError
        case compressionError
        case parseError
    }
    
    static func from(hash: String, in repository: Repository) throws -> Object {
        let breakIndex = hash.index(hash.startIndex, offsetBy: 2)
        let firstTwo = hash.substring(to: breakIndex)
        let hashEnd = hash.substring(from: breakIndex)
        let path = repository.subpath(with: "objects/\(firstTwo)/\(hashEnd)")
        return try from(file: path, in: repository)
    }
    
    static func from(file path: Path, in repository: Repository) throws -> Object {
        guard let data = try? NSData.readFromPath(path) else {
            throw Error.readError
        }
        guard let uncompressed = try? data.gzipUncompressed() as Data else {
            throw Error.compressionError
        }
        
        let unparsed = String(data: uncompressed, encoding: .ascii)!
        let headerIndex = unparsed.characters.index(of: "\0")!
        let header = unparsed.substring(to: headerIndex)
        
        guard let type = ObjectType(header: header) else {
            throw Error.parseError
        }
        
        let hash = path.parent.fileName + path.fileName
        let contentData = uncompressed.subdata(in: (header.characters.count + 1)..<uncompressed.count)
        
        return type.objectClass.init(hash: hash, data: contentData, repository: repository)
    }
    
    required init(hash: String, data: Data, repository: Repository) {
        fatalError("Use subclass")
    }
    
    init(hash: String, data: Data, type: ObjectType, repository: Repository) {
        self.hash = hash
        self.type = type
        self.repository = repository
    }
    
}

extension Object: CustomStringConvertible {
    
    var description: String {
        return String(describing: type(of: self)) + " (\(hash))"
    }
    
}

extension Repository {
    
    var objects: [Object] {
        let objectsDirectory = subpath(with: "objects")
        var objects: [Object] = []
        for objectFile in objectsDirectory {
            guard objectFile.isRegular && objectFile.fileName != ".DS_Store" else {
                continue
            }
            do {
                let object = try Object.from(file: objectFile, in: self)
                objects.append(object)
            } catch {
                print(error, "for", objectFile)
            }
        }
        return objects
    }
    
}
