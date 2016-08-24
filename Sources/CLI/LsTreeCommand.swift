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
    let signature = "<hash>"
    let shortDescription = "Lists files tracked by this repo"
    
    var recursive = false
    
    func setupOptions(options: OptionRegistry) {
        options.add(flags: ["-r"]) { (flag) in
            self.recursive = true
        }
    }
    
    func execute(arguments: CommandArguments) throws {
        let hash = arguments.requiredArgument("hash")
        guard let tree = repository?.objectStore[hash] as? Tree else {
            throw CLIError.error("Repository index could not be read")
        }
        
        let iterator = recursive ? RecursiveTreeIterator(tree: tree) : FlatTreeIterator(tree: tree)
        while let entry = iterator.next() {
            print(entry)
        }
    }
    
}
