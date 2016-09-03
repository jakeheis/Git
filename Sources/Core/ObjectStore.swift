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
    
    static let directory = "objects"
    
    let repository: Repository
    
    init(repository: Repository) {
        self.repository = repository
    }
    
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
        
        return try? Object.from(file: objectPath, in: repository)
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
            guard let object = try? Object.from(file: objectFile, in: repository) else {
                fatalError("Corrupt object: \(objectFile)")
            }
            objects.append(object)
        }
        for pack in repository.packfiles {
            objects += pack.readAll().flatMap { $0.object(in: repository) }
        }
        return objects
    }
    
}

// MARK: -

extension Repository {
    
    public var objectStore: ObjectStore {
        return ObjectStore(repository: self)
    }
    
}
