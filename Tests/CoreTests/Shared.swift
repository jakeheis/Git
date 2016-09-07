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

private func moveRepository(at path: Path) -> Path {
    let newPath = path.parent + "Real" + path.fileName
    if newPath.exists { // Already done
        return newPath
    }
    try! path.copyFileToPath(newPath)
    try! (newPath + "Git").moveFileToPath(newPath + ".git")
    return newPath
}

// MARK: -

private(set) var basicRepository = createBasicRepository()

private func createBasicRepository() -> Repository {
    let newPath = moveRepository(at: "/Users/jakeheiser/Documents/Swift/Git/Tests/Repositories/Basic")
    return Repository(path: newPath)!
}

func clearBasicRepository() {
    try! basicRepository.path.deleteFile()
    basicRepository = createBasicRepository()
}

// MARK: -

let packedRepository: Repository = {
    let newPath = moveRepository(at: "/Users/jakeheiser/Documents/Swift/Git/Tests/Repositories/Packed")
    return Repository(path: newPath)!
}()

// MARK: -

private(set) var writeRepository = createWriteRepository()

private func createWriteRepository() -> Repository {
    let newPath = moveRepository(at: "/Users/jakeheiser/Documents/Swift/Git/Tests/Repositories/Write")
    return Repository(path: newPath)!
}

func clearWriteRepository() {
    try! writeRepository.path.deleteFile()
    writeRepository = createWriteRepository()
}

// MARK: -

func executeGitCommand(in repository: Repository, with additionalArguments: [String]) {
    let arguments = ["-C", repository.path.rawValue] + additionalArguments
    let process = Process.launchedProcess(launchPath: "/usr/local/bin/git", arguments: arguments)
    process.waitUntilExit()
}

extension Repository {
    
    func checkout(_ co: String, block: () -> ()) {
        executeGitCommand(in: self, with: ["checkout", "-q", co])
        block()
        executeGitCommand(in: self, with: ["checkout", "-qf", "master"])
    }
    
}

extension TreeEntry {
    
    func equals(mode: FileMode, hash: String, name: String) -> Bool {
        return self.mode == mode && self.hash == hash && self.name == name
    }
    
}
