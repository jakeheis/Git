//
//  UpdateIndexCommand.swift
//  Git
//
//  Created by Jake Heiser on 9/7/16.
//
//

import Core
import SwiftCLI
import FileKit

class UpdateIndexCommand: RepositoryCommand {
    
    let name = "update-index"
    let signature = "<path> ..."
    let shortDescription = "Updates the index with the given files"
    
    var add = false
    var remove = false
    
    func setupOptions(options: OptionRegistry) {
        options.add(flags: ["--add"]) {
            self.add = true
        }
        options.add(flags: ["--remove"]) {
            self.remove = true
        }
    }
    
    func execute(arguments: CommandArguments) throws {
        guard let repository = repository, let index = repository.index else {
            throw CLIError.error("Repository index could not be read")
        }
        
        let files = arguments.requiredCollectedArgument("path")
        for file in files {
            if !(repository.path + file).exists {
                if remove {
                    try index.remove(file: file)
                } else {
                    throw CLIError.error("\(file): does not exist and --remove not passed")
                }
                continue
            }
            
            if !index.isTracking(file) {
                if add {
                    try index.add(file: file)
                } else {
                    throw CLIError.error("\(file): cannot add to the index - missing --add option?")
                }
                continue
            }
            
            try index.update(file: file)
        }
    }
    
}
