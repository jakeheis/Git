//
//  DiffCommand.swift
//  Git
//
//  Created by Jake Heiser on 9/12/16.
//
//

import Core
import SwiftCLI

class DiffCommand: RepositoryCommand {
    
    let name = "diff"
    let signature = ""
    let shortDescription = "Diffs working directory and index"
    
    func setupOptions(options: OptionRegistry) {
        
    }
    
    func execute(arguments: CommandArguments) throws {
        guard let repository = repository else {
            throw CLIError.error("Couldn't read repository")
        }
        
        do {
            let diff = try Diff.diffWorkingDirectoryAndIndex(in: repository)
            var fileDiffs = diff.fileDiffs
            let less = Less { () -> [String]? in
                if fileDiffs.isEmpty {
                    return nil
                }
                return fileDiffs.removeFirst().generate()
            }
            less.go()
        } catch {
            throw CLIError.error("Diff failed")
        }
    }
    
}
