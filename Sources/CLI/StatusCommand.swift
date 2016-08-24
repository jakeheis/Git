//
//  StatusCommand.swift
//  Git
//
//  Created by Jake Heiser on 8/23/16.
//
//

import Core
import SwiftCLI

class StatusCommand: RepositoryCommand {
    
    let name = "status"
    let signature = ""
    let shortDescription = "Prints current status of repository"
    
    var short = false
    var showBranchInShort = false
    
    func setupOptions(options: OptionRegistry) {
        options.add(flags: ["-s", "--short"]) { (flag) in
            self.short = true
        }
        options.add(flags: ["-b", "--branch"]) { (flag) in
            self.showBranchInShort = true
        }
    }
    
    func execute(arguments: CommandArguments) throws {
        guard let head = repository?.head else {
            throw CLIError.error("Repository HEAD could not be read")
        }
        guard let index = repository?.index else {
            throw CLIError.error("Repository index could not be read")
        }
        guard let delta = index.changedFiles() else {
            throw CLIError.error("Unable to compare index with most recent commit")
        }
        
        let sortedFiles = delta.deltaFiles.sorted { $0.name < $1.name }
        
        if short {
            if showBranchInShort {
                switch head.kind {
                case .hash(_): print("## HEAD (no branch)")
                case let .reference(reference): print("## \(reference.name)")
                }
            }
            for file in sortedFiles {
                let status = String(file.status.rawValue.characters.first!).capitalized
                print(status, file.name)
            }
        } else {
            switch head.kind {
            case let .hash(hash): print("HEAD detached at \(hash)")
            case let .reference(reference): print("On branch \(reference.name)")
            }
            if !sortedFiles.isEmpty {
                print("Changes to be committed:")
                print(" (use \"git reset HEAD <file>...\" to unstage)")
                print()
                for file in sortedFiles {
                    var status = file.status.rawValue + ":"
                    status += String(repeating: " ", count: 12 - status.characters.count)
                    print("\t\(status)\(file.name)")
                }
                print()
            }
        }
    }
    
}
