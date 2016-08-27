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
        
        let pack: [UInt8] = [80, 65, 67, 75]
        guard Array(dataReader.readData(bytes: 4)) == pack, dataReader.readInt(bytes: 4) == 2 else {
            return nil
        }
        
        print(packfileIndex.entries.map { $0.hash + " -- " + String(describing: $0.offset) })
        
        var chunks: [Int: PackfileChunk] = [:]
        
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
            
            if let objectType = packfileObjectType?.objectType {
                let dataOffset = entry.offset + lengthByteCount
                guard let data = dataReader.readData(bytes: nextOffset - dataOffset).uncompressed() else {
                    fatalError("Couldn't uncompress data")
                }
                if data.count != objectLength {
                    fatalError("Inflated object should be correct length")
                }
                
                let object = objectType.objectClass.init(hash: entry.hash, data: data, repository: repository)
                print(object)
                chunks[entry.offset] = PackfileChunk(data: data, object: object)
            } else {
                if packfileObjectType == .ofsDelta {
                    var currentByte = dataReader.readByte()
                    var negativeOffset = currentByte.intValue(ofBits: 1 ..< 8)
                    var backwardsDistanceByteCount = 1
                    
                    while currentByte[0] == 1 {
                        currentByte = dataReader.readByte()
                        negativeOffset += 1
                        negativeOffset <<= 7
                        negativeOffset += currentByte.intValue(ofBits: 1 ..< 8)
                        backwardsDistanceByteCount += 1
                    }
                    
                    let deltaFromObjectOffset = entry.offset - negativeOffset
                    let chunk = chunks[deltaFromObjectOffset]!
                    let baseObject = chunk.data
                    
                    let thisOffset = entry.offset + lengthByteCount + backwardsDistanceByteCount
                    let data = dataReader.readData(bytes: nextOffset - thisOffset)
                    let deltaData = data.uncompressed()!
                    let deltaReader = DataReader(data: deltaData)
                    _ = deltaReader.readVariableLengthInt() // Source length
                    _ = deltaReader.readVariableLengthInt() // Target length
                    
                    var builtData = Data()
                    
                    while deltaReader.canRead {
                        let instructionByte = deltaReader.readByte()
                        
                        if instructionByte[0] == 0 { // Insertion
                            let insertionByteCount = instructionByte.intValue(ofBits: 1 ..< 8)
                            builtData.append(deltaReader.readData(bytes: insertionByteCount))
                        } else { // Copy
                            var offset = 0
                            for bitIndex in 0 ..< 4 {
                                if instructionByte[7 - bitIndex] == 1 {
                                    let byte = deltaReader.readInt(bytes: 1)
                                    offset |= byte << (bitIndex * 8)
                                }
                            }
                            
                            var size = 0
                            for bitIndex in 0 ..< 3 {
                                if instructionByte[3 - bitIndex] == 1 {
                                    let byte = deltaReader.readInt(bytes: 1)
                                    size |= byte << (bitIndex * 8)
                                }
                            }
                            if size == 0 {
                                size = 0x10000
                            }
                            
                            builtData.append(baseObject.subdata(in: offset ..< (offset + size)))
                        }
                    }
                    
                    print(chunk.object.type.objectClass.init(hash: entry.hash, data: builtData, repository: repository))
                } else {
                    let parent = dataReader.readHex(bytes: 20)
                    print("delta from", parent)
                }
            }
        }
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
