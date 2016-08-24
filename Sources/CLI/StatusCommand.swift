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
        guard let staged = index.stagedChanges(),
            let unstaged = index.unstagedChanges() else {
            throw CLIError.error("Unable to resolve changes")
        }
        
        var stagedFiles = staged.deltaFiles.sorted { $0.name < $1.name }
        var unstagedFiles = unstaged.deltaFiles.sorted { $0.name < $1.name }
        
        if short {
            if showBranchInShort {
                switch head.kind {
                case .hash(_): print("## HEAD (no branch)")
                case let .reference(reference): print("## \(reference.name)")
                }
            }
            
            while !stagedFiles.isEmpty || !unstagedFiles.isEmpty {
                switch (stagedFiles.first, unstagedFiles.first) {
                case let (s?, u?) where s.name == u.name:
                    print("\(s.status.shortStatus)\(u.status.shortStatus)", s.name)
                    stagedFiles.removeFirst()
                    unstagedFiles.removeFirst()
                case let (s?, u) where u == nil, let (s?, u) where s.name < u!.name:
                    print("\(s.status.shortStatus) ", s.name)
                    stagedFiles.removeFirst()
                case let (s, u?) where s == nil, let (s, u?) where s!.name < u.name:
                    print(" \(u.status.shortStatus)", u.name)
                    unstagedFiles.removeFirst()
                default: break
                }
            }
        } else {
            switch head.kind {
            case let .hash(hash): print("HEAD detached at \(hash)")
            case let .reference(reference): print("On branch \(reference.name)")
            }
            
            if !stagedFiles.isEmpty {
                print("Changes to be committed:")
                print(" (use \"git reset HEAD <file>...\" to unstage)")
                print()
                for file in stagedFiles {
                    var status = file.status.rawValue + ":"
                    status += String(repeating: " ", count: 12 - status.characters.count)
                    print("\t\(status)\(file.name)")
                }
                print()
            }
            
            if !unstagedFiles.isEmpty {
                print("Changes not staged for commit:")
                print(" (use \"git add <file>...\" to update what will be committed)")
                print(" (use \"git checkout -- <file>...\" to discard changes in working directory)")
                print()
                for file in unstagedFiles {
                    var status = file.status.rawValue + ":"
                    status += String(repeating: " ", count: 12 - status.characters.count)
                    print("\t\(status)\(file.name)")
                }
                print()
            }
        }
    }
    
}
