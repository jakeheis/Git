//
//  IndexWriter.swift
//  Git
//
//  Created by Jake Heiser on 9/6/16.
//
//

import Foundation
import FileKit

class IndexWriter {
    
    enum Error: Swift.Error {
        case writeError
    }
    
    let index: Index
    
    init(index: Index) {
        self.index = index
    }
    
    func write() throws {
        let path = index.repository.subpath(with: Index.path)
        try write(to: path)
    }
    
    func write(to path: Path) throws {
        let data = try generateData()
        try data.write(to: path)
    }
    
    func generateData() throws -> Data {
        let dataWriter = DataWriter()
        dataWriter.write(bytes: [68, 73, 82, 67]) // DIRC
        dataWriter.write(int: index.version, overBytes: 4)
        dataWriter.write(int: index.entries.count, overBytes: 4)
        
        for entry in index.entries {
            try write(entry: entry, using: dataWriter)
        }
        
        if let rootTreeExtension = index.rootTreeExtension {
            dataWriter.write(bytes: [84, 82, 69, 69]) // TREE
            
            let extensionWriter = DataWriter()
            write(treeExtension: rootTreeExtension, using: extensionWriter)
            
            let extensionData = extensionWriter.data
            dataWriter.write(int: extensionData.count, overBytes: 4)
            dataWriter.write(data: extensionData)
        }
        
        dataWriter.write(data: dataWriter.data.sha1) // Checksum
        
        return dataWriter.data
    }
    
    func write(entry: IndexEntry, using dataWriter: DataWriter) throws {
        dataWriter.write(int: entry.stat.cSeconds, overBytes: 4)
        dataWriter.write(int: entry.stat.cNanoseconds, overBytes: 4)
        dataWriter.write(int: entry.stat.mSeconds, overBytes: 4)
        dataWriter.write(int: entry.stat.mNanoseconds, overBytes: 4)
        dataWriter.write(int: entry.stat.dev, overBytes: 4)
        dataWriter.write(int: entry.stat.ino, overBytes: 4)
        try dataWriter.write(octal: entry.stat.mode.rawValue, overBytes: 4)
        dataWriter.write(int: entry.stat.uid, overBytes: 4)
        dataWriter.write(int: entry.stat.gid, overBytes: 4)
        dataWriter.write(int: entry.stat.fileSize, overBytes: 4)
        dataWriter.write(hex: entry.hash)
        
        let flagByte = Byte(bits: [UInt8(entry.assumeValid), UInt8(entry.extended), UInt8(entry.firstStage), UInt8(entry.secondStage), 0, 0, 0, 0])
        dataWriter.write(byte: flagByte)
        
        guard let nameData = entry.name.data(using: .ascii) else {
            throw Error.writeError
        }
        let nameLength = nameData.count > 0xFF ? 0xFF : nameData.count
        dataWriter.write(int: nameLength, overBytes: 1)
        dataWriter.write(data: nameData)
        
        let byteCount = 62 + nameData.count
        let paddingCount = 8 - (byteCount % 8)
        for _ in 0 ..< paddingCount {
            dataWriter.write(byte: 0)
        }
    }
    
    func write(treeExtension: IndexTreeExtension, using extensionWriter: DataWriter) {
        guard let pathData = treeExtension.path.data(using: .ascii),
            let entryCountData = String(treeExtension.entryCount).data(using: .ascii),
            let subtreeCountData = String(treeExtension.subtreeCount).data(using: .ascii) else {
                return
        }
        extensionWriter.write(data: pathData)
        extensionWriter.write(byte: 0)
        extensionWriter.write(data: entryCountData)
        extensionWriter.write(byte: 32)
        extensionWriter.write(data: subtreeCountData)
        extensionWriter.write(byte: 10)
        if let hash = treeExtension.hash {
            extensionWriter.write(hex: hash)
        }
        for subtree in treeExtension.subtrees {
            write(treeExtension: subtree, using: extensionWriter)
        }
    }
    
}

private extension UInt8 {
    
    init(_ bool: Bool) {
        self.init(bool ? 1 : 0)
    }
    
}
