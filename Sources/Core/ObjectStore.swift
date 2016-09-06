//
//  ObjectStore.swift
//  Git
//
//  Created by Jake Heiser on 8/22/16.
//
//

import Foundation
import FileKit

public class ObjectStore {
    
    public enum Error: Swift.Error {
        case readError
        case compressionError
        case parseError
        case incorrectLengthError
        
        case dataError
        case writeError
    }
    
    static let directory = "objects"
    
    let repository: Repository
    
    init(repository: Repository) {
        self.repository = repository
    }
    
    // MARK: - Reading
    
    public subscript(hash: String) -> Object? {
        if let fromFile = objectFromFile(hash: hash) {
            return fromFile
        }
        
        return objectFromPackfile(hash: hash)
    }
    
    public func objectFromFile(hash: String) -> Object? {
        if hash.characters.count < 4 {
            return nil
        }
        
        let breakIndex = hash.index(hash.startIndex, offsetBy: 2)
        let firstTwo = hash.substring(to: breakIndex)
        let parentDirectory = repository.subpath(with: "\(ObjectStore.directory)/\(firstTwo)")
        
        let hashEnd = hash.substring(from: breakIndex)
        
        var path: Path?
        if hashEnd.characters.count < 38 {
            for child in parentDirectory.children() {
                if child.fileName.hasPrefix(hashEnd) {
                    if path != nil { // Ambiguous hash -- multiple matching objects
                        return nil
                    }
                    path = child
                } else {
                    if path != nil { // Already found our object
                        break
                    }
                }
            }
        } else {
            path = parentDirectory + hashEnd
        }
        
        guard let objectPath = path else {
            return nil
        }
        
        return try? readObject(from: objectPath)
    }
    
    public func objectFromPackfile(hash: String) -> Object? {
        for packfileIndex in repository.packfileIndices {
            if let (offset, fullHash) = packfileIndex.offset(for: hash) {
                return packfileIndex.packfile?.readObject(at: offset, hash: fullHash)
            }
        }
        return nil
    }
    
    public func allObjects() -> [Object] {
        let objectsDirectory = repository.subpath(with: ObjectStore.directory)
        var objects: [Object] = []
        for objectFile in objectsDirectory {
            guard objectFile.isRegular && objectFile.fileName.characters.count == 38 else {
                continue
            }
            guard let object = try? readObject(from: objectFile) else {
                fatalError("Corrupt object: \(objectFile)")
            }
            objects.append(object)
        }
        for pack in repository.packfiles {
            objects += pack.readAll().flatMap { $0.object(in: repository) }
        }
        return objects
    }
    
    // MARK: - Basic read
    
    func readObject(from file: Path, hash givenHash: String? = nil) throws -> Object {
        guard let data = try? NSData.readFromPath(file) as Data else {
            throw Error.readError
        }
        guard let uncompressed = data.uncompressed() else {
            throw Error.compressionError
        }
        
        let dataReader = DataReader(data: uncompressed)
        
        guard let header = String(data: dataReader.readUntil(byte: 0), encoding: .ascii) else {
            throw Error.parseError
        }
        
        let headerWords = header.components(separatedBy: " ")
        
        guard let typeWord = headerWords.first,
            let type = ObjectType(rawValue: typeWord) else {
                throw Error.parseError
        }
        
        let hash = givenHash ?? (file.parent.fileName + file.fileName)
        let contentData = dataReader.readData(bytes: dataReader.remainingBytes)
        
        guard let lengthWord = headerWords.last,
            let length = Int(lengthWord),
            contentData.count == length else {
                throw Error.incorrectLengthError
        }
        
        return type.objectClass.init(hash: hash, data: contentData, repository: repository)
    }
    
    // MARK: - Basic write
    
    func write(object: Object) throws {
        let breakIndex = object.hash.index(object.hash.startIndex, offsetBy: 2)
        let firstTwo = object.hash.substring(to: breakIndex)
        let hashEnd = object.hash.substring(from: breakIndex)
        
        let parentDirectory = repository.subpath(with: "\(ObjectStore.directory)/\(firstTwo)")
        
        let file = parentDirectory + hashEnd
        
        let data = object.generateWriteData()
        
        guard let compressed = data.compressed() else {
            throw Error.compressionError
        }
        
        do {
            if !parentDirectory.isAny {
                try parentDirectory.createDirectory()
            }
            try compressed.write(to: file)
        } catch {
            throw Error.writeError
        }
    }
    
}

// MARK: -

extension Repository {
    
    public var objectStore: ObjectStore {
        return ObjectStore(repository: self)
    }
    
}
