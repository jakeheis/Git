//
//  IDResolver.swift
//  Git
//
//  Created by Jake Heiser on 10/12/16.
//
//

public class IDResolver {
    
    public static func resolve(object: String, in repository: Repository) -> Object? {
        if let reference = ReferenceParser.parse(raw: object, repository: repository) {
            return reference.object
        } else if let repositoryObject = repository.objectStore[object] {
            return repositoryObject
        } else {
            return nil
        }
    }
    
    public static func resolve(treeish: String, in repository: Repository) -> Tree? {
        guard let object = resolve(object: treeish, in: repository) else {
            return nil
        }
        
        if let treeObject = object as? Tree {
            return treeObject
        } else if let commitObject = object as? Commit {
            return commitObject.tree
        } else {
            return nil
        }
    }
    
}
