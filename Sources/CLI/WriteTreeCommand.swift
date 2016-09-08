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
        guard let index = repository?.index else {
            throw CLIError.error("Repository index could not be read")
        }
        
        let treeWriter = TreeWriter(index: index)
        let tree: Tree
        do {
            tree = try treeWriter.write(checkMissing: checkMissing)
        } catch {
            throw CLIError.error("Could not write tree -- \(error)")
        }
        
        print(tree.hash)
    }
    
}
