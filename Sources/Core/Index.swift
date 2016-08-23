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
    
    let repository: Repository
    public let entries: [IndexEntry]
    
    init(repository: Repository) throws {
        let indexPath = repository.subpath(with: "index")
        guard let fileReader = FileReader(path: indexPath) else {
            throw Error.readError
        }
        guard fileReader.read(next: 4) == "DIRC" else {
            throw Error.parseError
        }
        
        guard let version = fileReader.readHexInt(length: 4) else {
            throw Error.parseError
        }
        self.version = version
        
        guard let count = fileReader.readHexInt(length: 4) else {
            throw Error.parseError
        }
        
        // 12 byte header
        
        var entries: [IndexEntry] = []
        for _ in 0 ..< count {
            guard
                let cSeconds = fileReader.readHexInt(length: 4),
                let cNanoseconds = fileReader.readHexInt(length: 4),
                let mSeconds = fileReader.readHexInt(length: 4),
                let mNanoseconds = fileReader.readHexInt(length: 4),
                let dev = fileReader.readHexInt(length: 4),
                let ino = fileReader.readHexInt(length: 4) else {
                    throw Error.parseError
            }
            let cTimeInterval = Double(cSeconds) + Double(cNanoseconds) / 1_000_000_000
            let cDate = Date(timeIntervalSince1970: cTimeInterval)
            
            let mTimeInterval = Double(mSeconds) + Double(mNanoseconds) / 1_000_000_000
            let mDate = Date(timeIntervalSince1970: mTimeInterval)
            
            // 24 bytes in entry
            
            guard let mode = fileReader.readBinary(length: 4) else {
                throw Error.parseError
            }
            
            let objectTypeBinary = mode.substring(to: mode.index(mode.startIndex, offsetBy: 4))
            let unixPermissionBinary = mode.substring(from: mode.index(mode.startIndex, offsetBy: 7))
            
            guard
                let objectTypeInt = Int(objectTypeBinary, radix: 2),
                let objectType = IndexEntry.ObjectType(rawValue: objectTypeInt),
                let unixPermissionInt = Int(unixPermissionBinary, radix: 2),
                let unixPermission = IndexEntry.UnixPermission(rawValue: unixPermissionInt) else {
                    throw Error.parseError
            }
            
            // 28 bytes in entry
            
            guard
                let uid = fileReader.readHexInt(length: 4),
                let gid = fileReader.readHexInt(length: 4),
                let fileSize = fileReader.readHexInt(length: 4) else {
                    throw Error.parseError
            }
            
            // 40 bytes in entry
            
            let hash = fileReader.readHex(length: 20)
            
            // 60 bytes in entry
            
            guard var flags = fileReader.readBinary(length: 2) else {
                throw Error.parseError
            }
            
            while flags.characters.count < 16 {
                flags = "0" + flags
            }
            
            let assumeValidBinary = String(flags.remove(at: flags.startIndex))
            let assumeValid = (Int(assumeValidBinary) ?? 0) > 0
            
            let extendedBinary = String(flags.remove(at: flags.startIndex))
            let extended = (Int(extendedBinary) ?? 0) > 0
            
            let firstStageBinary = String(flags.remove(at: flags.startIndex))
            let firstStage = (Int(firstStageBinary) ?? 0) > 0
            
            let secondStageBinary = String(flags.remove(at: flags.startIndex))
            let secondStage = (Int(secondStageBinary) ?? 0) > 0
            
            guard let nameLength = Int(flags, radix: 2) else {
                throw Error.parseError
            }
            
            // 62 bytes in entry
            
            let name: String
            if nameLength == 0xFFF { // Length too big to store; do it manually
                name = fileReader.read(until: "\0", skipCharacter: false)
            } else {
                name = fileReader.read(next: nameLength)
            }
            
            let bytesIn = 62 + name.characters.count
            
            let paddingCount = 8 - (bytesIn % 8)
            fileReader.read(next: paddingCount)
            
            let entry = IndexEntry(cDate: cDate, mDate: mDate, dev: dev, ino: ino, objectType: objectType, unixPermission: unixPermission, uid: uid, gid: gid, fileSize: fileSize, hash: hash, assumeValid: assumeValid, extended: extended, firstStage: firstStage, secondStage: secondStage, name: name)
            entries.append(entry)
        }
        
        self.entries = entries
        self.repository = repository
    }
    
}

public struct IndexEntry {
    
    public enum ObjectType: Int {
        case regularFile = 0b1000
        case symbolicLink = 0b1010
        case gitLink = 0b1110
    }
    
    public enum UnixPermission: Int {
        case zero = 0
        case sixFourtyFour = 0o644
        case sevemFiftyFive = 0o755
    }
    
    public let cDate: Date
    public let mDate: Date
    public let dev: Int
    public let ino: Int
    public let objectType: ObjectType
    public let unixPermission: UnixPermission
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
