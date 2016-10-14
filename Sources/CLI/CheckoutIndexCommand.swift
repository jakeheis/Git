//
//  CheckoutIndexCommand.swift
//  Git
//
//  Created by Jake Heiser on 10/12/16.
//
//

import Core
import SwiftCLI

class CheckoutIndexCommand: RepositoryCommand {
    
    let name = "checkout-index"
    let signature = "[<files>] ..."
    let shortDescription = "Checks out files from index"
    
    var all = false
    var force = false
    
    func setupOptions(options: OptionRegistry) {
        options.add(flags: ["-a", "--all"]) { 
            self.all = true
        }
        options.add(flags: ["-f", "--force"]) {
            self.force = true
        }
    }
    
    func execute(arguments: CommandArguments) throws {
        guard let index = repository?.index else {
            throw CLIError.error("Repository could not be read")
        }
        
        guard let files = arguments.optionalCollectedArgument("files") else {
            throw CLIError.error("Don't support all/none yet")
        }
        
        do {
            try index.checkout(files: files, force: force)
        } catch Index.CheckoutError.fileExists(let file) {
            throw CLIError.error("File already exists: \(file)")
        } catch Index.CheckoutError.fileNotInIndex(let file) {
            throw CLIError.error("File not in index: \(file)")
        } catch {
            throw CLIError.error("An error occurred")
        }
    }
    
}
