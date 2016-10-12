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
        
        guard let tree = IDResolver.resolve(treeish: id, in: repository) else {
            throw CLIError.error("\(id) must be a tree or a commit")
        }
        
        let iterator = recursive ? RecursiveTreeIterator(tree: tree) : FlatTreeIterator(tree: tree)
        while let entry = iterator.next() {
            print(entry)
        }
    }
    
}
