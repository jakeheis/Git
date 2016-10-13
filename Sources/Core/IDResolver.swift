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
    
    public static func resolve(commitish: String, in repository: Repository) -> Commit? {
        let object: String
        let offset: Int
        if let offsetCharacter = commitish.characters.index(of: "~"),
            let offsetInt = Int(commitish.substring(from: commitish.index(after: offsetCharacter))) {
            object = commitish.substring(to: offsetCharacter)
            offset = offsetInt
        } else {
            object = commitish
            offset = 0
        }
        
        guard let commit = resolve(object: object, in: repository) as? Commit else {
            return nil
        }
        
        var offsetCommit: Commit? = commit
        for _ in 0 ..< offset {
            offsetCommit = offsetCommit?.parent
        }
        return offsetCommit
    }
    
    public static func resolve(treeish: String, in repository: Repository) -> Tree? {
        if treeish.contains("~") { // Offset commit (e.g. HEAD~2)
            return resolve(commitish: treeish, in: repository)?.tree
        }
        
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
