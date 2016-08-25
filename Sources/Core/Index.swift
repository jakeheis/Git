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
    
    public let version: Int
    
    enum Error: Swift.Error {
        case readError
        case parseError
    }
    
    fileprivate let entries: [IndexEntry]
    private let keyedEntries: [String: IndexEntry]
    
    let repository: Repository
    
    init(repository: Repository) throws {
        let indexPath = repository.subpath(with: "index")
        guard let dataReader = DataReader(path: indexPath) else {
            throw Error.readError
        }
        guard dataReader.read(next: 4) == "DIRC" else {
            throw Error.parseError
        }
        
        guard let version = dataReader.readInt(bytes: 4) else {
            throw Error.parseError
        }
        self.version = version
        
        guard let count = dataReader.readInt(bytes: 4) else {
            throw Error.parseError
        }
        
        // 12 byte header
        
        // TODO: Initial ugly implementation; refactor
        
        var entries: [IndexEntry] = []
        var keyedEntries: [String: IndexEntry] = [:]
        for _ in 0 ..< count {
            guard
                let cSeconds = dataReader.readInt(bytes: 4),
                let cNanoseconds = dataReader.readInt(bytes: 4),
                let mSeconds = dataReader.readInt(bytes: 4),
                let mNanoseconds = dataReader.readInt(bytes: 4),
                let dev = dataReader.readInt(bytes: 4),
                let ino = dataReader.readInt(bytes: 4) else {
                    throw Error.parseError
            }
            let cTimeInterval = Double(cSeconds) + Double(cNanoseconds) / 1_000_000_000
            let cDate = Date(timeIntervalSince1970: cTimeInterval)
            
            let mTimeInterval = Double(mSeconds) + Double(mNanoseconds) / 1_000_000_000
            let mDate = Date(timeIntervalSince1970: mTimeInterval)
            
            // 24 bytes in entry
            
            guard let mode = FileMode(rawValue: dataReader.readOctal(bytes: 4)) else {
                    throw Error.parseError
            }
            
            // 28 bytes in entry
            
            guard
                let uid = dataReader.readInt(bytes: 4),
                let gid = dataReader.readInt(bytes: 4),
                let fileSize = dataReader.readInt(bytes: 4) else {
                    throw Error.parseError
            }
            
            // 40 bytes in entry
            
            let hash = dataReader.readHex(bytes: 20)
            
            // 60 bytes in entry
            
            let flags = dataReader.readBits(bytes: 1)
            
            let assumeValid = flags[0] > 0
            let extended = flags[1] > 0
            let firstStage = flags[2] > 0
            let secondStage = flags[3] > 0
            
            guard let nameLength = dataReader.readInt(bytes: 1) else {
                throw Error.parseError
            }
            
            // 62 bytes in entry
            
            let name: String
            if nameLength == 0xFFF { // Length too big to store; do it manually
                name = dataReader.read(until: "\0", skipCharacter: false)
            } else {
                name = dataReader.read(next: nameLength)
            }
            
            let bytesIn = 62 + name.characters.count
            
            let paddingCount = 8 - (bytesIn % 8)
            dataReader.read(next: paddingCount)
            
            let entry = IndexEntry(cDate: cDate, mDate: mDate, dev: dev, ino: ino, mode: mode, uid: uid, gid: gid, fileSize: fileSize, hash: hash, assumeValid: assumeValid, extended: extended, firstStage: firstStage, secondStage: secondStage, name: name)
            entries.append(entry)
            keyedEntries[name] = entry
        }
        
        self.entries = entries
        self.keyedEntries = keyedEntries
        self.repository = repository
    }
    
    subscript(name: String) -> IndexEntry? {
        return keyedEntries[name]
    }
    
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

extension Index: Collection {
    
    public var startIndex: Int {
        return entries.startIndex
    }
    
    public var endIndex: Int {
        return entries.endIndex
    }
    
    public subscript(index: Int) -> IndexEntry {
        return entries[index]
    }
    
    public func index(after i: Int) -> Int {
        return entries.index(after: i)
    }
    
}

public struct IndexEntry {
    public let cDate: Date
    public let mDate: Date
    public let dev: Int
    public let ino: Int
    public let mode: FileMode
    public let uid: Int
    public let gid: Int
    public let fileSize: Int
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

extension Repository {
    
    public var index: Index? {
        return try? Index(repository: self)
    }
    
}

// MARK: - IndexDelta

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
        var indexNames = Set(index.entries.map({ $0.name }))
        
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
        var indexNames = Set(index.map { $0.name })
        
        var deltaFiles: [DeltaFile] = []
        let gitIgnore = repository.gitIgnore
        
        guard let fileIterator = FileManager.default.enumerator(atPath: repository.path.rawValue) else {
            fatalError("Couldn't iterate the files of the working directory")
        }
        for file in fileIterator {
            guard let file = file as? String, !Path(file).isDirectory else {
                continue
            }
            if let indexEntry = index[file] {
                indexNames.remove(file)
                guard let blob = Blob(file: repository.path + file, repository: repository) else {
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
