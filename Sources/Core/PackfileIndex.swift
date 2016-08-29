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
    
    static let packDirectory = ".git/objects/pack/"
    
    let data: Data
    let path: Path
    let repository: Repository
    
    var packfile: Packfile? {
        var packfilePath = path
        packfilePath.pathExtension = "pack"
        return Packfile(path: packfilePath, repository: repository)
    }
    
    convenience init?(name: String, repository: Repository) {
        let path = repository.subpath(with: PackfileIndex.packDirectory + name)
        self.init(path: path, repository: repository)
    }
    
    init?(path: Path, repository: Repository) {
        guard path.pathExtension == "idx" else {
            return nil
        }
        
        guard let data = try? NSData.readFromPath(path) as Data else {
            return nil
        }
        
        self.data = data
        self.path = path
        self.repository = repository
    }
    
    func offset(for hash: String) -> Int? {
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
        for i in lastCount ..< thisCount {
            let entryHash = dataReader.readHex(bytes: 20)
            if entryHash == hash {
                potentialIndex = i
            }
        }
        
        guard let index = potentialIndex else {
            return nil
        }
        
        // Header + fan out table + hash table + crc table + offset into offset table
        let hashCrcOffset = totalCount * 24
        let offsetOffset = index * 4
        dataReader.byteCounter = 8 + 256 * 4 + hashCrcOffset + offsetOffset
        
        let thisOffset = dataReader.readInt(bytes: 4)
        
        return thisOffset
    }
    
    func readAll() -> [PackfileIndexEntry] {
        let dataReader = DataReader(data: data)
        
        let header = dataReader.readData(bytes: 4)
        let version = dataReader.readInt(bytes: 4)
        guard Array(header) == [255, 116, 79, 99], version == 2 else {
            fatalError("Corrupt packfile index or invalid version")
        }
        
        var fanOutTable: [String: Int] = [:]
        var cumulative = 0
        for i in 0 ..< 256 {
            let count = dataReader.readInt(bytes: 4)
            if count > cumulative {
                fanOutTable[String(format: "%02x", i)] = count - cumulative
                cumulative = count
            }
        }
        
        var hashes: [String] = []
        for _ in 0 ..< cumulative {
            hashes.append(dataReader.readHex(bytes: 20))
        }
        
        var crcs: [Data] = []
        for _ in 0 ..< cumulative {
            crcs.append(dataReader.readData(bytes: 4))
        }
        
        var entries: [PackfileIndexEntry] = []
        for i in 0 ..< cumulative {
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

struct PackfileIndexEntry {
    let hash: String
    let crc: Data
    let offset: Int
}

extension Repository {
    
    public var packfileIndices: [PackfileIndex] {
        let packDirectory = Path(PackfileIndex.packDirectory)
        return packDirectory.flatMap { (packIndexPath) in
            return PackfileIndex(path: packIndexPath, repository: self)
        }
    }
    
}
