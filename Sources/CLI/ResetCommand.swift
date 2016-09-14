//
//  ResetCommand.swift
//  Git
//
//  Created by Jake Heiser on 9/14/16.
//
//

import Core
import SwiftCLI

class ResetCommand: RepositoryCommand {
    
    let name = "reset"
    let signature = "<file> ..." // TODO: for now, always reset to head
    let shortDescription = "Reset the given paths in the index"
    
    func setupOptions(options: OptionRegistry) {}
    
    func execute(arguments: CommandArguments) throws {
        guard let index = repository?.index else {
            throw CLIError.error("Couldn't read repository")
        }
        
        let files = arguments.requiredCollectedArgument("file")
        do {
            try index.reset(files: files)
        } catch {
            throw CLIError.error("Couldn't reset index")
        }
    }
    
}
