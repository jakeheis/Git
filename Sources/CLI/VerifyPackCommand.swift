//
//  VerifyPackCommand.swift
//  Git
//
//  Created by Jake Heiser on 8/27/16.
//
//

import Foundation
import Core
import SwiftCLI
import FileKit

class VerifyPackCommand: RepositoryCommand {
    
    let name = "verify-pack"
    let signature = "<packPath>"
    let shortDescription = "Lists tags"
    
    var verbose = false
    
    func setupOptions(options: OptionRegistry) {
        options.add(flags: ["-v"]) {
            self.verbose = true
        }
    }
    
    func execute(arguments: CommandArguments) throws {
        guard let repository = repository else {
            throw CLIError.error("Repository index could not be read")
        }
        
        let packPath = repository.path + arguments.requiredArgument("packPath")
        guard let pack = PackfileIndex(path: packPath, repository: repository)?.packfile else {
            throw CLIError.error("Couldn't read Packfile")
        }
        
        for chunk in pack.readAll() {
            print(chunk)
        }
    }
    
}
