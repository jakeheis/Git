//
//  UpdateRefCommand.swift
//  Git
//
//  Created by Jake Heiser on 9/10/16.
//
//

import Core
import SwiftCLI
import FileKit

class UpdateRefCommand: RepositoryCommand {
 
    let name = "update-ref"
    let signature = "<ref> <newValue> [<oldValue>]"
    let shortDescription = "Writes the current tree"
    
    func setupOptions(options: OptionRegistry) {}
    
    func execute(arguments: CommandArguments) throws {
        let ref = arguments.requiredArgument("ref")
        let newValue = arguments.requiredArgument("newValue")

        guard let repository = repository else {
            throw CLIError.error("Couldn't read repository")
        }
        
        if let existing = ReferenceParser.parse(raw: ref, repository: repository) {
            let reference: Reference
            if let symbolic = existing as? SymbolicReference {
                reference = symbolic.dereferenced
            } else {
                reference = existing
            }
            
            if let oldValue = arguments.optionalArgument("oldValue") {
                guard reference.hash == oldValue else {
                    throw CLIError.error("ref \(ref) is at \(existing.hash) but expected \(oldValue)")
                }
            }
            
            do {
                try reference.update(hash: newValue)
            } catch {
                throw CLIError.error("Couldn't update foldered ref")
            }
            
        } else {
            if let oldValue = arguments.optionalArgument("oldValue") {
                throw CLIError.error("ref \(ref) doesn't exist but expected to be at \(oldValue)!)")
            }
            let reference = FolderedRefence(ref: ref, hash: newValue, repository: repository)
            do {
                try reference.write()
            } catch {
                throw CLIError.error("Couldn't write new ref")
            }
        }
        
        
    }
    
}
