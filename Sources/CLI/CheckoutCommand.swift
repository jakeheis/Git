//
//  CheckoutCommand.swift
//  Git
//
//  Created by Jake Heiser on 10/12/16.
//
//

import Foundation

import Core
import SwiftCLI

class CheckoutCommand: RepositoryCommand {
    
    let name = "checkout"
    let signature = "<commitish>"
    let shortDescription = "Checks out the given commit"
    
    func setupOptions(options: OptionRegistry) {
        
    }
    
    func execute(arguments: CommandArguments) throws {
        guard let repository = repository,
            let index = repository.index,
            let head = repository.head else {
            throw CLIError.error("Repository could not be read")
        }
        
        guard index.unstagedChanges().isEmpty && (index.stagedChanges()?.isEmpty ?? false) else {
            throw CLIError.error("Right now you can only checkout if no changes are present")
        }
        
        let commitish = arguments.requiredArgument("commitish")
        guard let commit = IDResolver.resolve(commitish: commitish, in: repository) else {
            throw CLIError.error("Couldn't resolve commitish")
        }
        
        do {
            try index.read(tree: commit.tree)
        } catch {
            throw CLIError.error("Couldn't read tree of commit \(commitish)")
        }
        
        do {
            try index.checkoutAll(force: true)
        } catch {
            throw CLIError.error("Couldn't checkout")
        }
        
        do {
            let old = head.kind.hash
            let message = "checkout: moving from \(old) to \(commitish)"
            if let ref = repository.referenceStore[commitish] {
                try head.update(to: ref, message: message)
            } else {
                try head.update(to: commit.hash, message: message)
            }
        } catch {
            throw CLIError.error("Couldn't update HEAD")
        }
    }
    
}

