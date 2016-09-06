//
//  TreeWriter.swift
//  Git
//
//  Created by Jake Heiser on 9/5/16.
//
//

import Foundation

public class TreeWriter {
    
    enum Error: Swift.Error {
        case missingObject
    }
    
    private let indexEntryStack: IndexEntryStack
    private let repository: Repository
    
    public init(index: Index) {
        self.indexEntryStack = IndexEntryStack(index: index)
        self.repository = index.repository
    }
    
    @discardableResult
    public func write(checkMissing: Bool = true) throws -> Tree {
        return try recursiveWrite(parentComponents: [], checkMissing: checkMissing)
    }
    
    private func recursiveWrite(parentComponents: [String] = [], checkMissing: Bool) throws -> Tree {
        var treeEntries: [TreeEntry] = []
        
        while !indexEntryStack.isEmpty {
            let entry = indexEntryStack.peek()
            if !entry.name.hasPrefix(parentComponents.joined(separator: "/")) { // Done with subdirectory
                break
            }
            
            var components = entry.name.components(separatedBy: "/")
            components = Array(components[parentComponents.count ..< components.count])
            
            if components.count > 1, let directoryName = components.first {
                let subParentComponents = parentComponents + [directoryName]
                let subtree = try recursiveWrite(parentComponents: subParentComponents, checkMissing: checkMissing)
                let directoryEntry = TreeEntry(mode: .directory, hash: subtree.hash, name: directoryName, repository: repository)
                treeEntries.append(directoryEntry)
            } else if let fileName = components.first {
                if checkMissing && repository.objectStore[entry.hash] == nil {
                    throw Error.missingObject
                }
                let blobEntry = TreeEntry(mode: entry.mode, hash: entry.hash, name: fileName, repository: repository)
                treeEntries.append(blobEntry)
                indexEntryStack.advance()
            }
        }
        
        let tree = Tree(entries: treeEntries, repository: repository)
        try tree.write()
        return tree
    }
    
}

fileprivate class IndexEntryStack {
    
    var entries: [IndexEntry]
    
    var isEmpty: Bool {
        return entries.isEmpty
    }
    
    init(index: Index) {
        self.entries = index.entries
    }
    
    func peek() -> IndexEntry {
        return entries.first!
    }
    
    func advance() {
        entries.removeFirst()
    }
    
}
