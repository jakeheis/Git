//
//  CatFileCommand.swift
//  Git
//
//  Created by Jake Heiser on 8/23/16.
//
//

import Core
import SwiftCLI
import FileKit

class CatFileCommand: RepositoryCommand {
    
    enum Mode {
        case print
        case type
        case none
    }
    
    let name = "cat-file"
    let signature = "<hash>"
    let shortDescription = "Cat a file"
    
    var mode: Mode = .none
    
    func setupOptions(options: OptionRegistry) {
        options.add(flags: ["-p"], usage: "Print contents") { (flag) in
            self.mode = .print
        }
        options.add(flags: ["-t"], usage: "File type") { (flag) in
            self.mode = .type
        }
    }
    
    func execute(arguments: CommandArguments) throws {
        guard let repository = repository else {
            throw CLIError.error("Git command must be executed in git tracked directory")
        }
        
        let hash = arguments.requiredArgument("hash")
        guard let object = repository.objectStore[hash] else {
            throw CLIError.error("Object not found")
        }
        
        switch mode {
        case .print: print(object.cat())
        case .type: print(object.type)
        case .none: throw CLIError.error("A flag must be passed")
        }
    }
    
}
