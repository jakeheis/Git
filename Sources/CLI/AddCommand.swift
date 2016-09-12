//
//  AddCommand.swift
//  Git
//
//  Created by Jake Heiser on 9/11/16.
//
//

import Core
import SwiftCLI
import FileKit

class AddCommand: RepositoryCommand {
    
    let name = "add"
    let signature = "<file> ..."
    let shortDescription = "Lists tags"
    
    func setupOptions(options: OptionRegistry) {
       
    }
    
    func execute(arguments: CommandArguments) throws {
        guard let index = repository?.index else {
            throw CLIError.error("Repository index could not be read")
        }
        
        let files = arguments.requiredCollectedArgument("file")
        do {
            try index.modify(with: files)
        } catch {
            throw CLIError.error("Couldn't update index")
        }
    }
    
}
