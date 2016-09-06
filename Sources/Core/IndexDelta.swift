//
//  IndexDelta.swift
//  Git
//
//  Created by Jake Heiser on 9/1/16.
//
//

import Foundation
import FileKit

public struct IndexDelta {
    
    public enum FileStatus: String {
        case added
        case modified
        case deleted
        case untracked
        
        public var shortStatus: String {
            return rawValue.substring(to: rawValue.index(after: rawValue.startIndex)).capitalized
        }
    }
    
    public typealias DeltaFile = (name: String, status: FileStatus)
    
    public let deltaFiles: [DeltaFile]
    
    let index: Index
    
    init(index: Index, tree: Tree) {
        var indexNames = Set(index.entries.map { $0.name })
        
        var deltaFiles: [DeltaFile] = []
        
        let recursiveTreeIterator = RecursiveTreeIterator(tree: tree)
        while let treeEntry = recursiveTreeIterator.next() {
            if let indexEntry = index[treeEntry.name] {
                indexNames.remove(treeEntry.name)
                if treeEntry.hash != indexEntry.hash || treeEntry.mode != indexEntry.mode {
                    deltaFiles.append((treeEntry.name, .modified))
                }
            } else {
                deltaFiles.append((treeEntry.name, .deleted))
            }
        }
        
        for remainingName in indexNames {
            deltaFiles.append((remainingName, .added))
        }
        
        self.deltaFiles = deltaFiles
        self.index = index
    }
    
    init(index: Index, repository: Repository) {
        var indexNames = Set(index.entries.map { $0.name })
        
        var deltaFiles: [DeltaFile] = []
        let gitIgnore = repository.gitIgnore
        
        guard let fileIterator = FileManager.default.enumerator(atPath: repository.path.rawValue) else {
            fatalError("Couldn't iterate the files of the working directory")
        }
        for file in fileIterator {
            guard let file = file as? String else {
                continue
            }
            
            if (repository.path + file).isDirectory {
                if gitIgnore.ignoreDirectory(file) {
                    fileIterator.skipDescendants()
                }
                continue
            }
            if let indexEntry = index[file] {
                indexNames.remove(file)
                
                guard let blob = Blob.formBlob(from: repository.path + file, in: repository) else {
                    fatalError("Blob could not be created for file: \(file)")
                }
                
                if indexEntry.hash != blob.hash {
                    deltaFiles.append((file, .modified))
                }
            } else {
                if !gitIgnore.ignoreFile(file) {
                    deltaFiles.append((file, .untracked))
                }
            }
        }
        
        for remainingName in indexNames {
            deltaFiles.append((remainingName, .deleted))
        }
        
        self.deltaFiles = deltaFiles
        self.index = index
    }
    
}
