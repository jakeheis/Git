//
//  Index.swift
//  Git
//
//  Created by Jake Heiser on 8/22/16.
//
//

import Foundation
import FileKit

public class Index {
    
    static let path = "index"
    
    public let version: Int
    
    enum Error: Swift.Error {
        case readError
        case parseError
        case writeError
    }
    
    private(set) public var entries: [IndexEntry] = []
    private var keyedEntries: [String: IndexEntry] = [:]
   
    public let rootTreeExtension: IndexTreeExtension?
    
    let repository: Repository
    
    init(repository: Repository) throws {
        let indexPath = repository.subpath(with: Index.path)
        
        guard let dataReader = DataReader(path: indexPath) else {
            throw Error.readError
        }
        
        // Read 12 byte header
        
        let dirc: [UInt8] = [68, 73, 82, 67] // "DIRC"
        guard Array(dataReader.readData(bytes: 4)) == dirc else {
            throw Error.parseError
        }
        
        let version = dataReader.readInt(bytes: 4)
        guard version == 2 else {
            fatalError("Index versions other than 2 are not yet supported")
        }
        self.version = version
        
        let count = dataReader.readInt(bytes: 4)
        
        // Read entries
        for _ in 0 ..< count {
            let cSeconds = dataReader.readInt(bytes: 4)
            let cNanoseconds = dataReader.readInt(bytes: 4)
            
            let mSeconds = dataReader.readInt(bytes: 4)
            let mNanoseconds = dataReader.readInt(bytes: 4)
            
            let dev = dataReader.readInt(bytes: 4)
            let ino = dataReader.readInt(bytes: 4)
            
            guard let mode = FileMode(rawValue: dataReader.readOctal(bytes: 4)) else {
                throw Error.parseError
            }
            
            let uid = dataReader.readInt(bytes: 4)
            let gid = dataReader.readInt(bytes: 4)
            let fileSize = dataReader.readInt(bytes: 4)
            
            let hash = dataReader.readHex(bytes: 20)
            
            let flags = dataReader.readByte()
            let assumeValid = flags[0] > 0
            let extended = flags[1] > 0
            let firstStage = flags[2] > 0
            let secondStage = flags[3] > 0
            
            let nameLength = dataReader.readInt(bytes: 1)
            
            let potentialName: String?
            if nameLength == 0xFF { // Length too big to store; do it manually
                let data = dataReader.readUntil(byte: 0, skipByte: false) // Read until null byte
                potentialName = String(data: data, encoding: .ascii)
            } else {
                potentialName = String(data: dataReader.readData(bytes: nameLength), encoding: .ascii)
            }
            
            guard let name = potentialName else {
                fatalError("Couldn't parse index entry name")
            }
            
            // Entry byte lengths are multiples of 8, so pad to multiple of 8
            let bytesIn = 62 + name.characters.count
            let paddingCount = 8 - (bytesIn % 8)
            dataReader.readData(bytes: paddingCount)
            
            let stat = Stat(cSeconds: cSeconds, cNanoseconds: cNanoseconds, mSeconds: mSeconds, mNanoseconds: mNanoseconds, dev: dev, ino: ino, mode: mode, uid: uid, gid: gid, fileSize: fileSize)
            let entry = IndexEntry(stat: stat, hash: hash, assumeValid: assumeValid, extended: extended, firstStage: firstStage, secondStage: secondStage, name: name)
            entries.append(entry)
            keyedEntries[name] = entry
        }
        
        var rootTreeExtension: IndexTreeExtension?
        if dataReader.remainingBytes > 20 { // Has extensions
            let signature = Array(dataReader.readData(bytes: 4))
            let size = dataReader.readInt(bytes: 4)
            
            let endByteCount = dataReader.byteCounter + size
            
            if signature == [84, 82, 69, 69] { // TREE
                func readTreeExtension() throws -> IndexTreeExtension {
                    guard let path = String(data: dataReader.readUntil(byte: 0), encoding: .ascii),
                        let entryCountString = String(data: dataReader.readUntil(byte: 32), encoding: .ascii),
                        let entryCount = Int(entryCountString),
                        let subtreeCountString = String(data: dataReader.readUntil(byte: 10), encoding: .ascii),
                        let subtreeCount = Int(subtreeCountString) else {
                            throw Error.parseError
                    }
                    
                    let hash: String? = entryCount >= 0 ? dataReader.readHex(bytes: 20) : nil
                    
                    var subtrees: [IndexTreeExtension] = []
                    for _ in 0 ..< subtreeCount {
                        subtrees.append(try readTreeExtension())
                    }
                    
                    return IndexTreeExtension(path: path, entryCount: entryCount, subtreeCount: subtreeCount, hash: hash, subtrees: subtrees)
                }
                
                rootTreeExtension = try readTreeExtension()
            }
            
            if dataReader.byteCounter != endByteCount {
                fatalError("The index extension was read incorrectly")
            }
        }
        
        if dataReader.remainingBytes != 20 {
            fatalError("The index has extensions that cannot yet be parsed")
        }
        
        let checksum = dataReader.readData(bytes: 20)
        guard dataReader.data.subdata(in: 0 ..< (dataReader.data.count - 20)).sha1 == checksum else {
            throw Error.parseError
        }
        
        self.rootTreeExtension = rootTreeExtension
        self.repository = repository
    }
    
    public subscript(name: String) -> IndexEntry? {
        return keyedEntries[name]
    }
    
    // MARK: - Modifying
    
    public func update(file: String, write shouldWrite: Bool = true) throws {
        guard let existing = self[file],
            let index = entries.index(of: existing) else {
            return
        }
        guard let updated = createEntry(for: file) else {
            return
        }
        guard updated.hash != existing.hash else { // File didn't change
            return
        }
        
        entries[index] = updated
        keyedEntries[file] = updated
        
        refreshTreeExtensions(afterFile: file)
        
        if shouldWrite {
            try write()
        }
    }
    
    public func add(file: String, write shouldWrite: Bool = true) throws {
        if self[file] != nil {
            return
        }
        
        var insertionIndex: Int?
        for (index, entry) in entries.enumerated() {
            if entry.name > file {
                insertionIndex = index
            }
        }
        guard let index = insertionIndex else {
            return
        }
        
        guard let new = createEntry(for: file) else {
            return
        }
        
        entries.insert(new, at: index)
        keyedEntries[file] = new
        
        refreshTreeExtensions(afterFile: file)
      
        if shouldWrite {
            try write()
        }
    }
    
    func write() throws {
        let indexWriter = IndexWriter(index: self)
        try indexWriter.write()
    }
    
    // MARK: - Modification helpers
    
    private func createEntry(for file: String) -> IndexEntry? {
        let path = repository.path + file
        
        guard let blob = try? BlobWriter(file: path, repository: repository).write() else {
            return nil
        }
        
        let stat = Stat(path: path)
        
        let entry = IndexEntry(
            stat: stat,
            hash: blob.hash,
            assumeValid: false, extended: false, firstStage: false, secondStage: false,
            name: file
        )
        return entry
    }
    
    func refreshTreeExtensions(afterFile file: String) {
        var pathComponents = file.components(separatedBy: "/")
        pathComponents.removeLast()
        
        if let rootTreeExtension = rootTreeExtension {
            invalidate(treeExtension: rootTreeExtension, pathComponents: pathComponents)
        }
    }
    
    func invalidate(treeExtension: IndexTreeExtension, pathComponents: [String]) {
        treeExtension.invalidate()
        
        guard !pathComponents.isEmpty else {
            return
        }
        
        if let matchingExtension = treeExtension.subtrees.first(where: { $0.path == pathComponents.first }) {
            let subComponents = Array(pathComponents[1 ..< pathComponents.count])
            invalidate(treeExtension: matchingExtension, pathComponents: subComponents)
        }
    }
    
    // MARK: - Deltas
    
    public func stagedChanges() -> IndexDelta? {
        guard let tree = repository.head?.commit?.tree else {
            return nil
        }
        return IndexDelta(index: self, tree: tree)
    }
    
    public func unstagedChanges() -> IndexDelta? {
        return IndexDelta(index: self, repository: repository)
    }
    
}

// MARK: - IndexEntry

public struct IndexEntry {
    
    public let stat: Stat
    public let hash: String
    public let assumeValid: Bool
    public let extended: Bool
    public let firstStage: Bool
    public let secondStage: Bool
    public let name: String
    
}

extension IndexEntry: CustomStringConvertible {

    public var description: String {
        return name
    }

}

extension IndexEntry: Equatable {}

public func == (lhs: IndexEntry, rhs: IndexEntry) -> Bool {
    return lhs.stat == rhs.stat && lhs.hash == rhs.hash && lhs.assumeValid == rhs.assumeValid && lhs.extended == rhs.extended && lhs.firstStage == rhs.firstStage && lhs.secondStage == rhs.secondStage
}

// MARK: - IndexTreeExtension

public class IndexTreeExtension {
    
    public let path: String
    private(set) public var entryCount: Int
    public let subtreeCount: Int
    private(set) public var hash: String?
    public let subtrees: [IndexTreeExtension]
 
    init(path: String, entryCount: Int, subtreeCount: Int, hash: String?, subtrees: [IndexTreeExtension]) {
        self.path = path
        self.entryCount = entryCount
        self.subtreeCount = subtreeCount
        self.hash = hash
        self.subtrees = subtrees
    }
    
    func invalidate() {
        entryCount = -1
        hash = nil
    }
    
}

extension IndexTreeExtension: CustomStringConvertible {
    
    public var description: String {
        return "\(path.isEmpty ? "(root)" : path) \(entryCount) \(subtreeCount) \(hash)"
    }
    
}

// MARK: -

extension Repository {
    
    public var index: Index? {
        return try? Index(repository: self)
    }
    
}
