//
//  Tree.swift
//  Git
//
//  Created by Jake Heiser on 8/30/16.
//
//

import Foundation

final public class Tree: Object {
    
    public let hash: String
    public let repository: Repository
    public let type: ObjectType = .tree
    
    public let treeEntries: [TreeEntry]
    
    public init(entries: [TreeEntry], hash: String, repository: Repository) {
        self.treeEntries = entries
        
        self.hash = hash
        self.repository = repository
    }
    
    public init(hash: String, data: Data, repository: Repository) {
        let dataReader = DataReader(data: data)
        
        var treeEntries: [TreeEntry] = []
        while dataReader.canRead {
            let modeData = dataReader.readUntil(byte: 32) // Read until space
            let nameData = dataReader.readUntil(byte: 0)
            guard let mode = String(data: modeData, encoding: .ascii),
                let name = String(data: nameData, encoding: .ascii) else {
                    fatalError("Couldn't parse tree \(hash)")
            }
            let entryHash = dataReader.readHex(bytes: 20)
            let entry = TreeEntry(mode: mode, hash: entryHash, name: name, repository: repository)
            treeEntries.append(entry)
        }
        
        self.treeEntries = treeEntries
        
        self.hash = hash
        self.repository = repository
    }
    
    public func cat() -> String {
        let lines = treeEntries.map { String(describing: $0) }
        return lines.joined(separator: "\n")
    }
    
    public func entry(for filePath: String) -> TreeEntry? {
        var components = filePath.components(separatedBy: "/")
        guard !components.isEmpty else {
            return nil
        }
        let firstComponent = components.removeFirst()
        guard let entry = treeEntries.first(where: { $0.name == firstComponent }) else {
            return nil
        }
        if entry.mode == .directory, !components.isEmpty, let subtree = entry.object as? Tree {
            return subtree.entry(for: components.joined(separator: "/"))
        } else {
            return entry
        }
    }
    
}

// MARK: - TreeEntry

public struct TreeEntry {
    
    public let mode: FileMode
    public let hash: String
    public let name: String
    let repository: Repository
    
    public var object: Object {
        guard let object = repository.objectStore[hash] else {
            fatalError("Could not resolve tree entry: \(hash)")
        }
        return object
    }
    
    init(mode raw: String, hash: String, name: String, repository: Repository) {
        guard let mode = FileMode(rawValue: raw) else {
            fatalError("Unrecognized mode: \(raw)")
        }
        self.mode = mode
        self.hash = hash
        self.name = name
        self.repository = repository
    }
    
    init(mode: FileMode, hash: String, name: String, repository: Repository) {
        self.mode = mode
        self.hash = hash
        self.name = name
        self.repository = repository
    }
    
}

extension TreeEntry: CustomStringConvertible {
    
    public var description: String {
        return "\(mode.intText) \(mode.name) \(hash)\t\(name)"
    }
    
}

// MARK: - Tree iterators

public class TreeIterator: IteratorProtocol {
    
    public func next() -> TreeEntry? {
        return nil
    }
    
}

public class FlatTreeIterator: TreeIterator {
    
    let tree: Tree
    private var index: Int = 0
    
    public init(tree: Tree) {
        self.tree = tree
    }
    
    override public func next() -> TreeEntry? {
        guard index < tree.treeEntries.count else {
            return nil
        }
        let entry = tree.treeEntries[index]
        index += 1
        return entry
    }
    
}

public class RecursiveTreeIterator: TreeIterator {
    
    let iterator: FlatTreeIterator
    var subtreeIterator: RecursiveTreeIterator?
    
    let prefix: String?
    
    public init(tree: Tree, prefix: String? = nil) {
        self.iterator = FlatTreeIterator(tree: tree)
        self.prefix = prefix
    }
    
    override public func next() -> TreeEntry? {
        if let subtreeIterator = subtreeIterator {
            if let entry = subtreeIterator.next() {
                return entry
            } else {
                self.subtreeIterator = nil
            }
        }
        
        guard let entry = iterator.next() else {
            return nil
        }
        if entry.mode == .directory {
            guard let subtree = entry.object as? Tree else {
                fatalError("Mode of file not matching type: \(entry.name)")
            }
            let subprefix = prefix?.appending("/" + entry.name) ?? entry.name
            subtreeIterator = RecursiveTreeIterator(tree: subtree, prefix: subprefix)
            return subtreeIterator?.next()
        }
        if let prefix = prefix {
            return TreeEntry(mode: entry.mode, hash: entry.hash, name: prefix + "/" + entry.name, repository: entry.repository)
        }
        
        return entry
    }
    
}
