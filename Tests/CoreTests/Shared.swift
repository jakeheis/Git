//
//  Shared.swift
//  Git
//
//  Created by Jake Heiser on 8/31/16.
//
//

import Foundation
@testable import Core

//let testRepository = Repository(path: Path.Current + "Tests/Repositories/Basic")!
let basicRepository = Repository(path: "/Users/jakeheiser/Documents/Swift/Git/Tests/Repositories/Basic")!
let packedRepository = Repository(path: "/Users/jakeheiser/Documents/Swift/Git/Tests/Repositories/Packed")!

func executeGitCommand(with additionalArguments: [String]) {
    let arguments = ["-C", basicRepository.path.rawValue] + additionalArguments
    let process = Process.launchedProcess(launchPath: "/usr/local/bin/git", arguments: arguments)
    process.waitUntilExit()
}

extension TreeEntry {
    
    func equals(mode: FileMode, hash: String, name: String) -> Bool {
        return self.mode == mode && self.hash == hash && self.name == name
    }
    
}
