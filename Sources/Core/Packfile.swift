//
//  Packfile.swift
//  Git
//
//  Created by Jake Heiser on 8/25/16.
//
//

import Foundation
import FileKit

public class Packfile {
    
    let data: Data
    let index: PackfileIndex
    let repository: Repository
    
    var offsetCache: [String: Int] = [:]
    var chunkCache: [Int: PackfileChunk] = [:]
    
    convenience init?(name: String, repository: Repository) {
        let path = repository.subpath(with: PackfileIndex.packDirectory + name)
        self.init(path: path, repository: repository)
    }
    
    public convenience init?(path: Path, repository: Repository) {
        var packfileIndexPath = path
        packfileIndexPath.pathExtension = "idx"
        
        guard let index = PackfileIndex(path: packfileIndexPath, repository: repository) else {
            return nil
        }
        
        self.init(path: path, index: index, repository: repository)
    }
    
    public init?(path: Path, index: PackfileIndex, repository: Repository) {
        guard path.pathExtension == "pack" else {
            return nil
        }
        
        guard let data = try? NSData.readFromPath(path) as Data else {
            return nil
        }
        
        self.data = data
        self.index = index
        self.repository = repository
    }
    
    public func readObject(at offset: Int, hash: String) -> Object? {
        return readChunk(at: offset, hash: hash)?.object(in: repository)
    }
    
    public func readAll() -> [PackfileChunk] {
        let dataReader = DataReader(data: data)
        
        let pack: [UInt8] = [80, 65, 67, 75] // PACK
        guard Array(dataReader.readData(bytes: 4)) == pack else {
            fatalError("Broken pack - missing header")
        }
        
        // TODO: Make work with other versions
        guard dataReader.readInt(bytes: 4) == 2 else {
            fatalError("Can only read version 2 packfiles (for now)")
        }
        
        var chunks: [PackfileChunk] = []
        
        let objectCount = dataReader.readInt(bytes: 4)
        let entries = index.readAll()
        
        for i in 0 ..< objectCount {
            let entry = entries[i]
            guard let chunk = readChunk(at: entry.offset, hash: entry.hash) else {
                fatalError("Couldn't read packfile")
            }
            
            chunks.append(chunk)
        }
        
        return chunks
    }
    
    // MARK: - Helpers
    
    func readChunk(at offset: Int, hash: String? = nil) -> PackfileChunk? {
        if let chunk = chunkCache[offset] {
            return chunk
        }
        
        let dataReader = DataReader(data: data)
        dataReader.byteCounter = offset
        
        guard let (packfileChunkType, objectLength) = readChunkMetadata(using: dataReader) else {
            return nil
        }
        
        let chunk: PackfileChunk
        if let objectType = packfileChunkType.objectType {
            chunk = readNonDeltifiedChunk(using: dataReader, offset: offset, objectType: objectType, objectLength: objectLength)
        } else {
            chunk = readDeltifiedChunk(using: dataReader, offset: offset, packfileChunkType: packfileChunkType, objectLength: objectLength)
        }
        
        chunk.hash = hash
        
        chunkCache[offset] = chunk
        if let key = hash {
            offsetCache[key] = offset
        }
        
        return chunk
    }
    
    private func readChunkMetadata(using dataReader: DataReader) -> (type: PackfileChunkType, length: Int)? {
        let objectMetadata = dataReader.readByte()
        
        guard let packfileChunkType = PackfileChunkType(rawValue: objectMetadata.intValue(ofBits: 1 ..< 4)) else {
            return nil
        }
        
        var objectLength = objectMetadata.intValue(ofBits: 4 ..< 8)
        var shiftCount = 4
        
        if objectMetadata[0] == 1 {
            var nextByte: Byte
            repeat {
                nextByte = dataReader.readByte()
                objectLength |= (nextByte.intValue(ofBits: 1 ..< 8) << shiftCount)
                shiftCount += 7
            } while nextByte[0] == 1
        }
        
        return (packfileChunkType, objectLength)
    }
    
    private func readNonDeltifiedChunk(using dataReader: DataReader, offset: Int, objectType: ObjectType, objectLength: Int) -> PackfileChunk {
        let headerLength = dataReader.byteCounter - offset
        
        guard let (data, compressedSize) = dataReader.readData(bytes: dataReader.remainingBytes).uncompressedWithInfo() else {
            fatalError("Couldn't uncompress data")
        }
        
        if data.count != objectLength {
            fatalError("Inflated object was not correct length")
        }
        
        return PackfileChunk(data: data, objectType: objectType, offset: offset, objectLength: objectLength, sizeInPackfile: headerLength + compressedSize)
    }
    
    private func readDeltifiedChunk(using dataReader: DataReader, offset: Int, packfileChunkType: PackfileChunkType, objectLength: Int) -> PackfileChunk {
        let parentChunk: PackfileChunk
        if packfileChunkType == .ofsDelta {
            let deltaOffset = Delta.readBaseOffset(using: dataReader)
            let absoluteOffset = offset - deltaOffset.value
            
            guard let chunk = readChunk(at: absoluteOffset) else {
                fatalError("Couldn't read parent chunk of delta")
            }
            parentChunk = chunk
        } else {
            let parentHash = dataReader.readHex(bytes: 20)
            
            guard let parentOffset = offsetCache[parentHash],
                let chunk = readChunk(at: parentOffset) else {
                    fatalError("Couldn't read parent chunk of delta")
            }
            
            parentChunk = chunk
        }
        
        let headerLength = dataReader.byteCounter - offset
        
        guard let (deltaData, compressedSize) = dataReader.readData(bytes: dataReader.remainingBytes).uncompressedWithInfo() else {
            fatalError("Couldn't decompress delta")
        }
        
        if deltaData.count != objectLength {
            fatalError("Delta data was not correct length")
        }
        
        let delta = Delta(data: deltaData)
        let result = delta.apply(to: parentChunk.data)
        
        let deltaDepth: Int
        if let deltifiedParentChunk = parentChunk as? DeltifiedPackfileChunk {
            deltaDepth = deltifiedParentChunk.deltaDepth + 1
        } else {
            deltaDepth = 1
        }
        
        return DeltifiedPackfileChunk(data: result, objectType: parentChunk.objectType, offset: offset, objectLength: objectLength, sizeInPackfile: headerLength + compressedSize, parentHash: parentChunk.hash, deltaDepth: deltaDepth)
    }
    
}

// MARK: - Packfile chunks

public class PackfileChunk: CustomStringConvertible {
    
    public let data: Data
    public let objectType: ObjectType
    public let offset: Int
    public let objectLength: Int
    public let sizeInPackfile: Int
    
    public var hash: String?
    
    public var description: String {
        var type = objectType.rawValue
        type += String(repeating: " ", count: 6 - type.characters.count)
        let components = [hash ?? "(no hash)", type, String(objectLength), String(sizeInPackfile), String(offset)]
        return components.joined(separator: " ")
    }
    
    init(data: Data, objectType: ObjectType, offset: Int, objectLength: Int, sizeInPackfile: Int) {
        self.data = data
        self.objectType = objectType
        self.offset = offset
        self.objectLength = objectLength
        self.sizeInPackfile = sizeInPackfile
    }
    
    public func object(in repository: Repository) -> Object? {
        guard let hash = hash else {
            return nil
        }
        return objectType.objectClass.init(hash: hash, data: data, repository: repository)
    }
    
}

public class DeltifiedPackfileChunk: PackfileChunk {
    
    public let parentHash: String?
    public let deltaDepth: Int
    
    public override var description: String {
        return super.description + " \(deltaDepth) \(parentHash ?? "(no parent hash)")"
    }
    
    init(data: Data, objectType: ObjectType, offset: Int, objectLength: Int, sizeInPackfile: Int, parentHash: String?, deltaDepth: Int) {
        self.parentHash = parentHash
        self.deltaDepth = deltaDepth
        super.init(data: data, objectType: objectType, offset: offset, objectLength: objectLength, sizeInPackfile: sizeInPackfile)
    }
    
}

enum PackfileChunkType: Int {
    case commit = 0b001
    case tree = 0b010
    case blob = 0b011
    case tag = 0b100
    case ofsDelta = 0b110
    case refDelta = 0b111
    
    var objectType: ObjectType? {
        switch self {
        case .commit: return .commit
        case .tree: return .tree
        case .blob: return .blob
        case .tag: return .tag
        default: return nil
        }
    }
}

// MARK: -

extension Repository {
    
    public var packfiles: [Packfile] {
        let packDirectory = subpath(with: PackfileIndex.packDirectory)
        return packDirectory.flatMap { (packIndexPath) in
            return Packfile(path: packIndexPath, repository: self)
        }
    }
    
}
