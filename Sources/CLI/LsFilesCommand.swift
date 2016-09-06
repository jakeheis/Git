//
//  LsFilesCommand.swift
//  Git
//
//  Created by Jake Heiser on 8/23/16.
//
//

import Core
import SwiftCLI

class LsFilesCommand: RepositoryCommand {
 
    let name = "ls-files"
    let signature = ""
    let shortDescription = "Lists files tracked by this repo"
    
    func setupOptions(options: OptionRegistry) {
        
    }
    
    func execute(arguments: CommandArguments) throws {
        guard let index = repository?.index else {
            throw CLIError.error("Repository index could not be read")
        }
        
        for entry in index.entries {
            print(entry.name)
        }
    }
    
}
