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
    
    let fanOutTable: [String: Int]
    let entries: [PackfileIndexEntry]
    
    convenience init?(name: String, repository: Repository) {
        let path = repository.subpath(with: PackfileIndex.packDirectory + name)
        self.init(path: path, repository: repository)
    }
    
    init?(path: Path, repository: Repository) {
        guard path.pathExtension == "idx" else {
            return nil
        }
        guard let dataReader = DataReader(path: path) else {
            return nil
        }
        
        let header = dataReader.readData(bytes: 4)
        let version = dataReader.readInt(bytes: 4)
        guard Array(header) == [255, 116, 79, 99], version == 2 else {
            return nil
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
        
        self.fanOutTable = fanOutTable
        self.entries = entries.sorted { $0.offset < $1.offset }
    }
    
}

struct PackfileIndexEntry {
    
    let hash: String
    let crc: Data
    let offset: Int
    
}
//
//extension Repository {
//    
//    public var packfileIndices: [PackfileIndex] {
//        let packDirectory = Path(PackfileIndex.packDirectory)
//        return packDirectory.flatMap { (packIndexPath) in
//            return PackfileIndex(path: packIndexPath, repository: self)
//        }
//    }
//    
//}
