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
import Cncurses
import Rainbow

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
        
        var currentCommit: Commit? = headCommit
        let less = Less { () -> [String]? in
            guard let commit = currentCommit else {
                return nil
            }
            currentCommit = commit.parent
            return self.log(of: commit)
        }
        less.lineColor = { (line) in
            if line.hasPrefix("commit") {
                return COLOR_YELLOW
            }
            return 0
        }
        less.go()
    }
    
    func log(of commit: Commit) -> [String] {
        var lines = [
            "commit \(commit.hash)",
            "Author: \(commit.authorSignature.name) (<\(commit.authorSignature.email)>)"
        ]
    
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        dateFormatter.timeZone = commit.authorSignature.timeZone
        lines.append("Date: " + dateFormatter.string(from: commit.authorSignature.time))
        
        lines.append("")
        
        let message = commit.message.components(separatedBy: "\n").map({ "\t\($0)" }).joined(separator: "\n")
        lines.append(message)
        
        lines.append("")
        
        return lines
    }
    
}
