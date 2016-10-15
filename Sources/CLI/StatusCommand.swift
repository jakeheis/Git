//
//  StatusCommand.swift
//  Git
//
//  Created by Jake Heiser on 8/23/16.
//
//

import Core
import SwiftCLI
import Rainbow

class StatusCommand: RepositoryCommand {
    
    let name = "status"
    let signature = ""
    let shortDescription = "Prints current status of repository"
    
    var short = false
    var showBranchInShort = false
    
    func setupOptions(options: OptionRegistry) {
        options.add(flags: ["-s", "--short"]) {
            self.short = true
        }
        options.add(flags: ["-b", "--branch"]) {
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
        guard let staged = index.stagedChanges() else {
            throw CLIError.error("Unable to resolve changes")
        }
        let unstaged = index.unstagedChanges()
        
        var stagedFiles = staged.deltaFiles.sorted { $0.name < $1.name }
        let allUnstagedFiles = unstaged.deltaFiles.sorted { $0.name < $1.name }
        var unstagedFiles: [IndexDelta.DeltaFile] = []
        var untrackedFiles: [IndexDelta.DeltaFile] = []
        for file in allUnstagedFiles {
            if file.status == .untracked {
                untrackedFiles.append(file)
            } else {
                unstagedFiles.append(file)
            }
        }
        
        if short {
            if showBranchInShort {
                switch head.kind {
                case .simple(_): print("## HEAD (no branch)")
                case let .symbolic(symbolic): print("## \(symbolic.dereferenced.ref.name.green)")
                }
            }
            
            while !stagedFiles.isEmpty || !unstagedFiles.isEmpty {
                switch (stagedFiles.first, unstagedFiles.first) {
                case let (s?, u?) where s.name == u.name:
                    print("\(s.status.shortStatus.yellow)\(u.status.shortStatus.green)", s.name)
                    stagedFiles.removeFirst()
                    unstagedFiles.removeFirst()
                case let (s?, u) where u == nil, let (s?, u) where s.name < u!.name:
                    print("\(s.status.shortStatus.yellow) ", s.name)
                    stagedFiles.removeFirst()
                case let (s, u?) where s == nil, let (s, u?) where u.name < s!.name:
                    print(" \(u.status.shortStatus.green)", u.name)
                    unstagedFiles.removeFirst()
                default: break
                }
            }
            
            for untracked in untrackedFiles {
                print("\("??".cyan)", untracked.name)
            }
        } else {
            switch head.kind {
            case let .simple(simple): print("HEAD detached at \(simple.hash)")
            case let .symbolic(symbolic): print("On branch \(symbolic.dereferenced.ref.name)")
            }
            
            if !stagedFiles.isEmpty {
                print("Changes to be committed:")
                print(" (use \"git reset HEAD <file>...\" to unstage)")
                print()
                for file in stagedFiles {
                    var status = file.status.rawValue + ":"
                    status += String(repeating: " ", count: 12 - status.characters.count)
                    print("\t\(status)\(file.name)".yellow)
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
                    print("\t\(status)\(file.name)".green)
                }
                print()
            }
            
            if !untrackedFiles.isEmpty {
                print("Untracked files:")
                print(" (use \"git add <file>...\" to include in what will be committed)")
                print()
                for file in untrackedFiles {
                    var status = file.status.rawValue + ":"
                    status += String(repeating: " ", count: 12 - status.characters.count)
                    print("\t\(file.name.cyan)")
                }
                print()
            }
            
            if stagedFiles.isEmpty && unstagedFiles.isEmpty && untrackedFiles.isEmpty {
                print("nothing to commit, working directory clean")
            }
        }
    }
    
}
