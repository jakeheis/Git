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
        
        // Read 12 byte header
        
        let dirc: [UInt8] = [68, 73, 82, 67] // "DIRC"
        guard Array(dataReader.readData(bytes: 4)) == dirc else {
            throw Error.parseError
        }
        
        let version = dataReader.readInt(bytes: 4)
        guard version == 2 else {
            throw Error.parseError
        }
        self.version = version
        
        let count = dataReader.readInt(bytes: 4)
        
        // Read entries
        
        var entries: [IndexEntry] = []
        var keyedEntries: [String: IndexEntry] = [:]
        for _ in 0 ..< count {
            let cSeconds = dataReader.readInt(bytes: 4)
            let cNanoseconds = dataReader.readInt(bytes: 4)
            let cTimeInterval = Double(cSeconds) + Double(cNanoseconds) / 1_000_000_000
            let cDate = Date(timeIntervalSince1970: cTimeInterval)
            
            let mSeconds = dataReader.readInt(bytes: 4)
            let mNanoseconds = dataReader.readInt(bytes: 4)
            let mTimeInterval = Double(mSeconds) + Double(mNanoseconds) / 1_000_000_000
            let mDate = Date(timeIntervalSince1970: mTimeInterval)
            
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
            if nameLength == 0xFFFF { // Length too big to store; do it manually
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
            
            let entry = IndexEntry(cDate: cDate, mDate: mDate, dev: dev, ino: ino, mode: mode, uid: uid, gid: gid, fileSize: fileSize, hash: hash, assumeValid: assumeValid, extended: extended, firstStage: firstStage, secondStage: secondStage, name: name)
            entries.append(entry)
            keyedEntries[name] = entry
        }
        
        self.entries = entries
        self.keyedEntries = keyedEntries
        self.repository = repository
    }
    
    public subscript(name: String) -> IndexEntry? {
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

// MARK: - IndexEntry

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

// MARK: -

extension Repository {
    
    public var index: Index? {
        return try? Index(repository: self)
    }
    
}
