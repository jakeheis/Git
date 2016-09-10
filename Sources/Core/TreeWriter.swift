//
//  TreeWriter.swift
//  Git
//
//  Created by Jake Heiser on 9/5/16.
//
//

import Foundation

final public class TreeWriter: ObjectWriter {
    
    enum Error: Swift.Error {
        case missingObject
    }
    
    let treeEntries: [TreeEntry]
    let repository: Repository
    
    public static func write(index: Index, checkMissing: Bool) throws -> String {
        let indexEntryStack = IndexEntryStack(index: index)
        return try recursiveWrite(indexEntryStack: indexEntryStack, parentComponents: [], repository: index.repository, checkMissing: checkMissing)
    }
    
    private static func recursiveWrite(indexEntryStack: IndexEntryStack, parentComponents: [String], repository: Repository, checkMissing: Bool) throws -> String {
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
                let subtreeHash = try recursiveWrite(indexEntryStack: indexEntryStack, parentComponents: subParentComponents, repository: repository, checkMissing: checkMissing)
                let directoryEntry = TreeEntry(mode: .directory, hash: subtreeHash, name: directoryName, repository: repository)
                treeEntries.append(directoryEntry)
            } else if let fileName = components.first {
                if checkMissing && repository.objectStore[entry.hash] == nil {
                    throw Error.missingObject
                }
                let blobEntry = TreeEntry(mode: entry.stat.mode, hash: entry.hash, name: fileName, repository: repository)
                treeEntries.append(blobEntry)
                indexEntryStack.advance()
            }
        }
        
        return try TreeWriter(treeEntries: treeEntries, repository: repository).write()
    }
    
    init(treeEntries: [TreeEntry], repository: Repository) {
        self.treeEntries = treeEntries
        self.repository = repository
    }
    
    init(object: Tree) {
        self.treeEntries = object.treeEntries
        self.repository = object.repository
    }
    
    func generateContentData() throws -> Data {
        let dataWriter = DataWriter()
        
        for entry in treeEntries {
            guard let modeData = entry.mode.rawValue.data(using: .ascii),
                let nameData = entry.name.data(using: .ascii) else {
                    continue
            }
            dataWriter.write(data: modeData)
            dataWriter.write(byte: 32) // Space
            dataWriter.write(data: nameData)
            dataWriter.write(byte: 0) // Null byte
            dataWriter.write(hex: entry.hash)
        }
        
        return dataWriter.data
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
