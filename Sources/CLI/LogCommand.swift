//
//  LogCommand.swift
//  Git
//
//  Created by Jake Heiser on 8/23/16.
//
//

import Foundation
import Core
import SwiftCLI

class LogCommand: RepositoryCommand {
    
    let name = "log"
    let signature = ""
    let shortDescription = "Show log of commits"
    
    func setupOptions(options: OptionRegistry) {
        // TODO: Many options
    }
    
    func execute(arguments: CommandArguments) throws {
        guard let headCommit = repository?.head?.commit else {
            throw CLIError.error("HEAD does not point to a valid commit")
        }
        printCommit(headCommit)
        
        var lastCommit = headCommit
        for _ in 0..<5 { // Arbitrary for now
            guard let commit = lastCommit.parent else {
                break
            }
            printCommit(commit)
            lastCommit = commit
        }
    }
    
    func printCommit(_ commit: Commit) {
        print("commit", commit.hash)
        print("Author:", commit.authorSignature.name, "<\(commit.authorSignature.email)>")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        dateFormatter.timeZone = commit.authorSignature.timeZone
        print("Date:", dateFormatter.string(from: commit.authorSignature.time))
        
        print()
        
        let message = commit.message.components(separatedBy: "\n").map({ "\t\($0)" }).joined(separator: "\n")
        print(message)
        
        print()
    }
    
}
