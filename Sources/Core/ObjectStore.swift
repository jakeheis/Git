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
        let breakIndex = hash.index(hash.startIndex, offsetBy: 2)
        let firstTwo = hash.substring(to: breakIndex)
        let hashEnd = hash.substring(from: breakIndex)
        let path = repository.subpath(with: "\(ObjectStore.directory)/\(firstTwo)/\(hashEnd)")
        
        return try? Object.from(file: path, in: repository)
    }
    
    public func objectFromPackfile(hash: String) -> Object? {
        for packfileIndex in repository.packfileIndices {
            if let offset = packfileIndex.offset(for: hash) {
                return packfileIndex.packfile?.readObject(at: offset, hash: hash)
            }
        }
        return nil
    }
    
    public func allObjects() -> [Object] {
        let objectsDirectory = repository.subpath(with: ObjectStore.directory)
        var objects: [Object] = []
        for objectFile in objectsDirectory {
            guard objectFile.isRegular && objectFile.fileName != ".DS_Store" else {
                continue
            }
            do {
                let object = try Object.from(file: objectFile, in: repository)
                objects.append(object)
            } catch {
                print(error, "for", objectFile)
            }
        }
        return objects
    }
    
}

extension Repository {
    
    public var objectStore: ObjectStore {
        return ObjectStore(repository: self)
    }
    
}
