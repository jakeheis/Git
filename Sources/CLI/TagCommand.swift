//
//  TagCommand.swift
//  Git
//
//  Created by Jake Heiser on 8/23/16.
//
//

import Core
import SwiftCLI

class TagCommand: RepositoryCommand {
    
    let name = "tag"
    let signature = ""
    let shortDescription = "Lists tags"
    
    func setupOptions(options: OptionRegistry) {
        
    }
    
    func execute(arguments: CommandArguments) throws {
        guard let repository = repository else {
            throw CLIError.error("Repository index could not be read")
        }
        
        for tag in repository.tags {
            print(tag.name)
        }
    }
    
}
