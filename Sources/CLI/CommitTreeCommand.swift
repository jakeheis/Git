//
//  CommitTreeCommand.swift
//  Git
//
//  Created by Jake Heiser on 9/10/16.
//
//

import Core
import SwiftCLI

class CommitTreeCommand: RepositoryCommand {
    
    let name = "commit-tree"
    let signature = "<tree>"
    let shortDescription = "Commits the given tree"
    
    var parent: String? = nil
    var message: String? = nil
    
    func setupOptions(options: OptionRegistry) {
        options.add(keys: ["-p"], valueSignature: "parent") { (parent) in
            self.parent = parent
        }
        options.add(keys: ["-m"], valueSignature: "message") { (message) in
            self.message = message
        }
    }
    
    func execute(arguments: CommandArguments) throws {
        guard let repository = repository else {
            throw CLIError.error("Couldn't read repository")
        }
        guard let message = message else {
            throw CLIError.error("For now, -m is required")
        }
        
        let treeHash = arguments.requiredArgument("tree")
        
        do {
            let hash = try CommitWriter(treeHash: treeHash, parentHash: parent, message: message, repository: repository).write()
            print(hash)
        } catch {
            throw CLIError.error("Failed to write commit")
        }
    }
    
}
