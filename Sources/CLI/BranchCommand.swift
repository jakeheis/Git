//
//  BranchCommand.swift
//  Git
//
//  Created by Jake Heiser on 8/23/16.
//
//

import Core
import SwiftCLI

class BranchCommand: RepositoryCommand {
    
    let name = "branch"
    let signature = ""
    let shortDescription = "Lists branches"
    
    func setupOptions(options: OptionRegistry) {
        
    }
    
    func execute(arguments: CommandArguments) throws {
        guard let repository = repository, let head = repository.head else {
            throw CLIError.error("Repository could not be read")
        }
        
        let matchingName: String?
        switch head.kind {
        case let .hash(hash):
            print("* (HEAD detached at \(hash))")
            matchingName = nil
        case let .reference(reference):
            matchingName = reference.name
        }
        
        for branch in repository.branches {
            let prefix = branch.name == matchingName ? "*" : " "
            print("\(prefix) \(branch.name)")
        }
    }
    
}
