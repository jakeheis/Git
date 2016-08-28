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
    
    convenience init?(name: String, repository: Repository) {
        let path = repository.subpath(with: PackfileIndex.packDirectory + name)
        self.init(path: path, repository: repository)
    }
    
    init?(path: Path, repository: Repository) {
        guard path.pathExtension == "pack" else {
            return nil
        }
        
        let url = path.url.deletingPathExtension().appendingPathExtension("idx")
        guard let packfileIndexPath = Path(url: url),
            let packfileIndex = PackfileIndex(path: packfileIndexPath, repository: repository) else {
                return nil
        }
        
        guard let dataReader = DataReader(path: path) else {
            return nil
        }
        
        let pack: [UInt8] = [80, 65, 67, 75] // PACK
        guard Array(dataReader.readData(bytes: 4)) == pack, dataReader.readInt(bytes: 4) == 2 else {
            return nil
        }
        
        var chunks: [PackfileChunk] = []
        var offsetChunkIndexMap: [Int: Int] = [:]
        var hashChunkIndexMap: [String: Int] = [:]
        
        let objectCount = dataReader.readInt(bytes: 4)
        
        for i in 0 ..< objectCount {
            let objectMetadata = dataReader.readByte()
            
            let packfileObjectType = PackfileObjectType(rawValue: objectMetadata.intValue(ofBits: 1 ..< 4))
            var objectLength = objectMetadata.intValue(ofBits: 4 ..< 8)
            var shiftCount = 4
            var lengthByteCount = 1
            
            if objectMetadata[0] == 1 {
                var nextByte: Byte
                repeat {
                    nextByte = dataReader.readByte()
                    objectLength |= (nextByte.intValue(ofBits: 1 ..< 8) << shiftCount)
                    shiftCount += 7
                    lengthByteCount += 1
                } while nextByte[0] == 1
            }
            
            let entry = packfileIndex.entries[i]
            
            let nextOffset = i + 1 < objectCount ? packfileIndex.entries[i + 1].offset : dataReader.data.count - 20
            
            let chunk: PackfileChunk
            if let objectType = packfileObjectType?.objectType {
                let dataOffset = entry.offset + lengthByteCount
                guard let data = dataReader.readData(bytes: nextOffset - dataOffset).uncompressed() else {
                    fatalError("Couldn't uncompress data")
                }
                if data.count != objectLength {
                    fatalError("Inflated object should be correct length")
                }
                
                let object = objectType.objectClass.init(hash: entry.hash, data: data, repository: repository)
                chunk = PackfileChunk(data: data, object: object)
            } else {
                let parentChunkIndex: Int?
                let deltaDataLength: Int
                if packfileObjectType == .ofsDelta {
                    let offset = Delta.offset(using: dataReader)
                    let absoluteOffset = entry.offset - offset.value
                    
                    parentChunkIndex = offsetChunkIndexMap[absoluteOffset]
                    deltaDataLength = nextOffset - (entry.offset + lengthByteCount + offset.byteCount)
                } else {
                    let baseHash = dataReader.readHex(bytes: 20)
                    
                    parentChunkIndex = hashChunkIndexMap[baseHash]
                    deltaDataLength = nextOffset - (entry.offset + lengthByteCount + 20)
                }
                
                guard let data = dataReader.readData(bytes: deltaDataLength).uncompressed() else {
                    fatalError("Couldn't decompress delta")
                }
                
                guard let index = parentChunkIndex else {
                    fatalError("Couldn't find base object")
                }
                let parentChunk = chunks[index]
                
                let delta = Delta(data: data)
                let result = delta.apply(to: parentChunk.data)
                
                let objectType = parentChunk.object.type.objectClass
                let object = objectType.init(hash: entry.hash, data: result, repository: repository)
                chunk = PackfileChunk(data: result, object: object)
            }
            
            chunks.append(chunk)
            offsetChunkIndexMap[entry.offset] = chunks.endIndex - 1
            hashChunkIndexMap[entry.hash] = chunks.endIndex - 1
        }
        
        print(chunks.map({ $0.object }))
    }
    
}

struct PackfileChunk {
    let data: Data
    let object: Object
}

enum PackfileObjectType: Int {
    case commit = 0b001
    case tree = 0b010
    case blob = 0b011
    case tag = 0b100
    case ofsDelta = 0b110
    case refDelta = 0b111
    
    var objectType: Object.ObjectType? {
        switch self {
        case .commit: return .commit
        case .tree: return .tree
        case .blob: return .blob
        case .tag: return .tag
        default: return nil
        }
    }
}

extension Repository {
    
    public var packfiles: [Packfile] {
        let packDirectory = Path(PackfileIndex.packDirectory)
        return packDirectory.flatMap { (packIndexPath) in
            return Packfile(path: packIndexPath, repository: self)
        }
    }
    
}

extension Data {
    
    func uncompressed() -> Data? {
        return (try? (self as NSData).gzipUncompressed()) as Data?
    }
    
}
