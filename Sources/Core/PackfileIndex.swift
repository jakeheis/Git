//
//  PackfileIndex.swift
//  Git
//
//  Created by Jake Heiser on 8/24/16.
//
//

import Foundation
import FileKit

public class PackfileIndex {
    
    static let packDirectory = "objects/pack/"
    
    let data: Data
    let path: Path
    let repository: Repository
    
    public var packfile: Packfile? {
        var packfilePath = path
        packfilePath.pathExtension = "pack"
        return Packfile(path: packfilePath, index: self, repository: repository)
    }
    
    convenience init?(name: String, repository: Repository) {
        let path = repository.subpath(with: PackfileIndex.packDirectory + name)
        self.init(path: path, repository: repository)
    }
    
    public init?(path: Path, repository: Repository) {
        guard path.pathExtension == "idx" else {
            return nil
        }
        
        guard let data = try? NSData.read(from: path) as Data else {
            return nil
        }
        
        self.data = data
        self.path = path
        self.repository = repository
    }
    
    func offset(for hash: String) -> (offset: Int, fullHash: String)? {
        let dataReader = DataReader(data: data)
        
        let firstTwo = hash.substring(to: hash.index(hash.startIndex, offsetBy: 2))
        guard let firstTwoIntVal = Int(firstTwo, radix: 16) else {
            fatalError("Couldn't convert hash to int")
        }
        
        // Header + offset into fan out table - 4
        dataReader.byteCounter = 8 + firstTwoIntVal * 4 - 4
        let lastCount = dataReader.readInt(bytes: 4)
        let thisCount = dataReader.readInt(bytes: 4)
        guard thisCount > lastCount else {
            return nil
        }
        
        // Header + offset to last entry of fan table
        dataReader.byteCounter = 8 + 255 * 4
        let totalCount = dataReader.readInt(bytes: 4)
        
        // Header + fan out table + offset into hash table
        dataReader.byteCounter = 8 + 256 * 4 + lastCount * 20
       
        var potentialIndex: Int?
        var potentialFullHash: String?
        for i in lastCount ..< thisCount {
            let entryHash = dataReader.readHex(bytes: 20)
            if entryHash == hash {
                potentialIndex = i
                potentialFullHash = entryHash
                break
            } else if entryHash.hasPrefix(hash) { // In case hash prefix is passed
                if potentialIndex != nil { // Already found a hash with the given prefix -- ambiguous
                    return nil
                }
                potentialIndex = i
                potentialFullHash = entryHash
            }
        }
        
        guard let index = potentialIndex, let fullHash = potentialFullHash else {
            return nil
        }
        
        // Header + fan out table + hash table + crc table + offset into offset table
        let hashCrcOffset = totalCount * 24
        let offsetOffset = index * 4
        dataReader.byteCounter = 8 + 256 * 4 + hashCrcOffset + offsetOffset
        
        let thisOffset = dataReader.readInt(bytes: 4)
        
        return (thisOffset, fullHash)
    }
    
    func readAll() -> [PackfileIndexEntry] {
        let dataReader = DataReader(data: data)
        
        let header = dataReader.readData(bytes: 4)
        let version = dataReader.readInt(bytes: 4)
        guard Array(header) == [255, 116, 79, 99], version == 2 else {
            fatalError("Corrupt packfile index or invalid version")
        }
        
        dataReader.byteCounter = 8 + 255 * 4
        let objectCount = dataReader.readInt(bytes: 4) // Read last entry
        
        var hashes: [String] = []
        for _ in 0 ..< objectCount {
            hashes.append(dataReader.readHex(bytes: 20))
        }
        
        var crcs: [Data] = []
        for _ in 0 ..< objectCount {
            crcs.append(dataReader.readData(bytes: 4))
        }
        
        var entries: [PackfileIndexEntry] = []
        for i in 0 ..< objectCount {
            let offset = dataReader.readInt(bytes: 4)
            if offset < 0b1000_0000_0000_0000 { // Basically check if first bit is 0
                let entry = PackfileIndexEntry(hash: hashes[i], crc: crcs[i], offset: offset)
                entries.append(entry)
            } else {
                // TODO: Deal with larger Packfiles
                fatalError("Can't deal with large Packfiles yet")
            }
        }
        
        return entries.sorted { $0.offset < $1.offset }
    }
    
}

// MARK: - PackfileIndexEntry

struct PackfileIndexEntry {
    let hash: String
    let crc: Data
    let offset: Int
}

// MARK: -

extension Repository {
    
    public var packfileIndices: [PackfileIndex] {
        let packDirectory = subpath(with: PackfileIndex.packDirectory)
        return packDirectory.flatMap { (packIndexPath) in
            return PackfileIndex(path: packIndexPath, repository: self)
        }
    }
    
}
