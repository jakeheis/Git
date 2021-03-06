//
//  WriteTreeCommand.swift
//  Git
//
//  Created by Jake Heiser on 9/5/16.
//
//

import Core
import SwiftCLI

class WriteTreeCommand: RepositoryCommand {
    
    let name = "write-tree"
    let signature = ""
    let shortDescription = "Writes the current tree"
    
    var checkMissing = true
    
    func setupOptions(options: OptionRegistry) {
        options.add(flags: ["--missing-ok"]) {
            self.checkMissing = false
        }
    }
    
    func execute(arguments: CommandArguments) throws {
        guard let repository = repository else {
            throw CLIError.error("Repository could not be read")
        }
        
        do {
            let hash = try TreeWriter.writeCurrent(in: repository, checkMissing: checkMissing)
            print(hash)
        } catch {
            throw CLIError.error("Could not write tree -- \(error)")
        }
    }
    
}
