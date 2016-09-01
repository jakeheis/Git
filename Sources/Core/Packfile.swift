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
    
    var offsetHashCache: [Int: String] = [:]
    
    convenience init?(name: String, repository: Repository) {
        let path = repository.subpath(with: PackfileIndex.packDirectory + name)
        self.init(path: path, repository: repository)
    }
    
    public init?(path: Path, repository: Repository) {
        guard path.pathExtension == "pack" else {
            return nil
        }
        
        guard let data = try? NSData.readFromPath(path) as Data else {
            return nil
        }
        
        var packfileIndexPath = path
        packfileIndexPath.pathExtension = "idx"
        
        guard let index = PackfileIndex(path: packfileIndexPath, repository: repository) else {
            return nil
        }
        
        self.data = data
        self.index = index
        self.repository = repository
    }
    
    func readChunk(at offset: Int, hash potentialHash: String? = nil, packfileSize: Int? = nil) -> PackfileChunk? {
        if let hash = potentialHash {
            offsetHashCache[offset] = hash
        }
        let hash = potentialHash ?? offsetHashCache[offset]
        
        let dataReader = DataReader(data: data)
        dataReader.byteCounter = offset
        
        let objectMetadata = dataReader.readByte()
        
        let packfileObjectType = PackfileObjectType(rawValue: objectMetadata.intValue(ofBits: 1 ..< 4))
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
        
        if let objectType = packfileObjectType?.objectType {
            guard let data = dataReader.readData(bytes: dataReader.remainingBytes).uncompressed() else {
                fatalError("Couldn't uncompress data")
            }
            
            if data.count != objectLength {
                fatalError("Inflated object should be correct length")
            }
            
            return PackfileChunk(data: data, objectType: objectType, hash: hash, offset: offset, packfileSize: packfileSize ?? 0)
        }
        
        let parentChunk: PackfileChunk
        if packfileObjectType == .ofsDelta {
            let deltaOffset = Delta.readBaseOffset(using: dataReader)
            let absoluteOffset = offset - deltaOffset.value
            
            guard let chunk = readChunk(at: absoluteOffset) else {
                fatalError("Couldn't read parent chunk of delta")
            }
            parentChunk = chunk
        } else {
            let parentHash = dataReader.readHex(bytes: 20)
            var potentialParentOffset: Int?
            for (offset, offsetHash) in offsetHashCache {
                if offsetHash == parentHash {
                    potentialParentOffset = offset
                    break
                }
            }
            guard let parentOffset = potentialParentOffset,
                let chunk = readChunk(at: parentOffset, hash: parentHash) else {
                    fatalError("Couldn't read parent chunk of delta")
            }
            parentChunk = chunk
        }
        
        guard let deltaData = dataReader.readData(bytes: dataReader.remainingBytes).uncompressed() else {
            fatalError("Couldn't decompress delta")
        }
        
        let delta = Delta(data: deltaData)
        let result = delta.apply(to: parentChunk.data)
        
        let deltaInfo = PackfileChunk.DeltaInfo(parentHash: parentChunk.hash, depth: (parentChunk.deltaInfo?.depth ?? 0) + 1, deltaDataLength: deltaData.count)
        
        return PackfileChunk(data: result, objectType: parentChunk.objectType, hash: hash, offset: offset, packfileSize: packfileSize ?? 0, deltaInfo: deltaInfo)
    }
    
    func readObject(at offset: Int, hash: String) -> Object? {
        return readChunk(at: offset, hash: hash)?.object(in: repository)
    }
    
    public func readAll() -> [PackfileChunk] {
        let dataReader = DataReader(data: data)
        
        let pack: [UInt8] = [80, 65, 67, 75] // PACK
        guard Array(dataReader.readData(bytes: 4)) == pack, dataReader.readInt(bytes: 4) == 2 else {
            fatalError("Broken pack - missing header")
        }
        
        var chunks: [PackfileChunk] = []
        
        let objectCount = dataReader.readInt(bytes: 4)
        let entries = index.readAll()
        
        for i in 0 ..< objectCount {
            let entry = entries[i]
            let nextOffset = i + 1 < entries.count ? entries[i + 1].offset : dataReader.data.count - 20
            guard let chunk = readChunk(at: entry.offset, hash: entry.hash, packfileSize: nextOffset - entry.offset) else {
                fatalError("Couldn't read packfile")
            }
            
            chunks.append(chunk)
        }
        
        return chunks
    }
    
}

// MARK: - PackfileChunk

public struct PackfileChunk {
    
    public let data: Data
    public let objectType: ObjectType
    public let hash: String?
    public let offset: Int
    public let packfileSize: Int
    
    public struct DeltaInfo {
        public let parentHash: String?
        public let depth: Int
        public let deltaDataLength: Int
    }
    
    public let deltaInfo: DeltaInfo?
    
    init(data: Data, objectType: ObjectType, hash: String?, offset: Int, packfileSize: Int, deltaInfo: DeltaInfo? = nil) {
        self.data = data
        self.objectType = objectType
        self.hash = hash
        self.offset = offset
        self.packfileSize = packfileSize
        
        self.deltaInfo = deltaInfo
    }
    
    public func object(in repository: Repository) -> Object? {
        guard let hash = hash else {
            return nil
        }
        return objectType.objectClass.init(hash: hash, data: data, repository: repository)
    }
    
}

extension PackfileChunk: CustomStringConvertible {
    
    public var description: String {
        var type = objectType.rawValue
        type += String(repeating: " ", count: 6 - type.characters.count)
        let uncompressedLength = deltaInfo?.deltaDataLength ?? data.count
        var components = [hash ?? "(no hash)", type, String(uncompressedLength), String(packfileSize), String(offset)]
        if let deltaInfo = deltaInfo {
            components.append(String(deltaInfo.depth))
            components.append(deltaInfo.parentHash ?? "(no parent hash)")
        }
        return components.joined(separator: " ")
    }
    
}

enum PackfileObjectType: Int {
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
