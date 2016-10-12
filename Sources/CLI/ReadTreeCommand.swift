//
//  ReadTreeCommand.swift
//  Git
//
//  Created by Jake Heiser on 10/12/16.
//
//

import Core
import SwiftCLI

class ReadTreeCommand: RepositoryCommand {
    
    let name = "read-tree"
    let signature = "<id>"
    let shortDescription = "Reset the given paths in the index"
    
    func setupOptions(options: OptionRegistry) {}
    
    func execute(arguments: CommandArguments) throws {
        guard let repository = repository,
            let index = repository.index else {
            throw CLIError.error("Couldn't read repository")
        }
        
        let id = arguments.requiredArgument("id")
        guard let tree = IDResolver.resolve(treeish: id, in: repository) else {
            throw CLIError.error("Couldn't resolve tree-ish")
        }
        
        do {
            try index.read(tree: tree)
        } catch {
            throw CLIError.error("Couldn't read tree into index")
        }
    }
    
}
