//
//  ObjectStore.swift
//  Git
//
//  Created by Jake Heiser on 8/22/16.
//
//

import Foundation
import FileKit

class ObjectStore {
    
    static let directory = "objects"
    
    let repository: Repository
    
    init(repository: Repository) {
        self.repository = repository
    }
    
    subscript(hash: String) -> Object? {
        get {
            return try? Object.from(file: path(for: hash), in: repository)
        }
    }
    
    subscript(reference: Reference) -> Object? {
        get {
            return try? Object.from(file: path(for: reference.hash), in: repository)
        }
    }
    
    func path(for hash: String) -> Path {
        let breakIndex = hash.index(hash.startIndex, offsetBy: 2)
        let firstTwo = hash.substring(to: breakIndex)
        let hashEnd = hash.substring(from: breakIndex)
        return repository.subpath(with: "\(ObjectStore.directory)/\(firstTwo)/\(hashEnd)")
    }
    
    func allObjects() -> [Object] {
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
    
    var objectStore: ObjectStore {
        return ObjectStore(repository: self)
    }
    
}
