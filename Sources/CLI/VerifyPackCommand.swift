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
        options.add(flags: ["-v"]) { (flag) in
            self.verbose = true
        }
    }
    
    func execute(arguments: CommandArguments) throws {
        guard let repository = repository else {
            throw CLIError.error("Repository index could not be read")
        }
        
        var packPath = repository.path + arguments.requiredArgument("packPath")
        packPath.pathExtension = "pack"
        guard let pack = Packfile(path: packPath, repository: repository) else {
            throw CLIError.error("Couldn't read Packfile")
        }
        
        for object in pack.readAll() {
            print(object.hash, object.type)
        }
    }
    
}


