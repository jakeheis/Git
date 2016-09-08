//
//  Shared.swift
//  Git
//
//  Created by Jake Heiser on 8/31/16.
//
//

import Foundation
@testable import Core
import FileKit

// MARK: -

func executeGitCommand(in repository: Repository, with additionalArguments: [String]) {
    let arguments = ["-C", repository.path.rawValue] + additionalArguments
    let process = Process.launchedProcess(launchPath: "/usr/local/bin/git", arguments: arguments)
    process.waitUntilExit()
}

//extension Repository {
//    
//    func checkout(_ co: String, block: () -> ()) {
//        executeGitCommand(in: self, with: ["checkout", "-q", co])
//        block()
//        executeGitCommand(in: self, with: ["checkout", "-qf", "master"])
//    }
//    
//}

extension TreeEntry {
    
    func equals(mode: FileMode, hash: String, name: String) -> Bool {
        return self.mode == mode && self.hash == hash && self.name == name
    }
    
}
