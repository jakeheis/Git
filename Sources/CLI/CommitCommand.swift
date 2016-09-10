//
//  CommitCommand.swift
//  Git
//
//  Created by Jake Heiser on 9/10/16.
//
//

import Core
import SwiftCLI

class CommitCommand: RepositoryCommand {
    
    let name = "commit"
    let signature = ""
    let shortDescription = "Commits the current index"
    
    var message: String? = nil
    
    func setupOptions(options: OptionRegistry) {
        options.add(keys: ["-m"], valueSignature: "message") { (message) in
            self.message = message
        }
    }
    
    func execute(arguments: CommandArguments) throws {
        guard let repository = repository, let head = repository.head?.dereferenced else {
            throw CLIError.error("Repository could not be read")
        }
        guard let message = message else {
            throw CLIError.error("For now, -m is required")
        }
        
        do {
            let hash = try CommitWriter.commitCurrent(in: repository, message: message)
            
            print("[\(head.name) \(hash)] \(message)")
        } catch {
            throw CLIError.error("Couldn't commit")
        }
    }
    
}
