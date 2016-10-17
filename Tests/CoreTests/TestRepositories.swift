//
//  TestRepositories.swift
//  Git
//
//  Created by Jake Heiser on 9/7/16.
//
//

import Foundation
@testable import Core
import FileKit

class TestRepositories {
    
    static let repositoryLocation = "/Users/jakeheiser/Documents/Swift/Git/Tests/Repositories"
    static let realRepositoryLocation = repositoryLocation + "/Real"
    
    enum RepositoryType {
        case basic
        case packed
        case emptyObjects
        
        fileprivate var path: String {
            switch self {
            case .basic: return repositoryLocation + "/Basic"
            case .packed: return repositoryLocation + "/Packed"
            case .emptyObjects: return repositoryLocation + "/EmptyObjects"
            }
        }
    }
    
    static func repository(_ type: RepositoryType, at checkout: String? = nil) -> Repository {
        let originalPath = Path(rawValue: type.path)
        let newPath = moveRepository(at: originalPath, overwrite: true)
        let repository = Repository(path: newPath)!
        if let checkout = checkout {
            executeGitCommand(in: repository, with: ["checkout", "-q", checkout])
        }
        return repository
    }
    
    static func reset() {
        for path in Path(rawValue: realRepositoryLocation) {
            if path.isDirectory {
                try! path.deleteFile()
            }
        }
    }
    
    // MARK: -
    
    private static func moveRepository(at path: Path, overwrite: Bool = false) -> Path {
        let newPath = path.parent + "Real" + path.fileName
        if newPath.exists {
            if overwrite {
                try! newPath.deleteFile()
            } else {
                return newPath
            }
        }
        try! path.copyFile(to: newPath)
        try! (newPath + "Git").moveFile(to: newPath + ".git")
        return newPath
    }
    
}
