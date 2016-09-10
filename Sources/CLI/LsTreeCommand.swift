//
//  LsTreeCommand.swift
//  Git
//
//  Created by Jake Heiser on 8/23/16.
//
//

import Core
import SwiftCLI

class LsTreeCommand: RepositoryCommand {
    
    let name = "ls-tree"
    let signature = "<id>"
    let shortDescription = "Lists files tracked by this repo"
    
    var recursive = false
    
    func setupOptions(options: OptionRegistry) {
        options.add(flags: ["-r"]) {
            self.recursive = true
        }
    }
    
    func execute(arguments: CommandArguments) throws {
        guard let repository = repository else {
            throw CLIError.error("Couldn't read repository")
        }
        
        let id = arguments.requiredArgument("id")
        
        let object: Object
        if let reference = ReferenceParser.parse(raw: id, repository: repository) {
            object = reference.object
        } else if let repositoryObject = repository.objectStore[id] {
            object = repositoryObject
        } else {
            throw CLIError.error("\(id) must point to a tree or a commit")
        }
        
        let tree: Tree
        if let treeObject = object as? Tree {
            tree = treeObject
        } else if let commitObject = object as? Commit {
            tree = commitObject.tree
        } else {
            throw CLIError.error("\(id) must be a tree or a commit")
        }
        
        let iterator = recursive ? RecursiveTreeIterator(tree: tree) : FlatTreeIterator(tree: tree)
        while let entry = iterator.next() {
            print(entry)
        }
    }
    
}
