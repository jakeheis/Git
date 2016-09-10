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
        guard let repository = repository else {
                throw CLIError.error("Couldn't read repository")
        }
        
        let newValue = arguments.requiredArgument("newValue")
        
        if let existing = ReferenceParser.parse(ref, repository: repository) {
            if let oldValue = arguments.optionalArgument("oldValue") {
                guard existing.hash == oldValue else {
                    throw CLIError.error("ref \(ref) is at \(existing.hash) but expected \(oldValue)")
                }
            }
            
            let folderedReference: FolderedRefence
            if let fr = existing as? FolderedRefence {
                folderedReference = fr
            } else if let head = existing as? Head,
                case let .reference(headReference) = head.kind,
                let fr = headReference as? FolderedRefence {
                    folderedReference = fr
            } else {
                throw CLIError.error("Can't update this kind of ref")
            }
            
            do {
                try folderedReference.update(hash: newValue)
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
