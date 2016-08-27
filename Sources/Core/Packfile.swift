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
        
        guard dataReader.read(next: 4) == "PACK", dataReader.readInt(bytes: 4) == 2 else {
            return nil
        }
        
        print(packfileIndex.entries.map { $0.hash + " -- " + String(describing: $0.offset) })
        
        var chunks: [Int: PackfileChunk] = [:]
        
        let objectCount = dataReader.readInt(bytes: 4)
        
        for i in 0 ..< objectCount {
            let objectMetadata = dataReader.readBits(bytes: 1)
            let packfileObjectType = PackfileObjectType(rawValue: Array(objectMetadata[1 ..< 4]).bitIntValue())
            var numberBits = Array(objectMetadata[4 ..< 8])
            var numberByteCount = 1
            if objectMetadata[0] == 1 {
                var nextByte: [UInt8]
                repeat {
                    nextByte = dataReader.readBits(bytes: 1)
                    numberBits = nextByte[1 ..< 8] + numberBits
                    numberByteCount += 1
                } while nextByte[0] == 1
            }
            
            let length = numberBits.bitIntValue()
            
            let entry = packfileIndex.entries[i]
            
            let nextOffset = i + 1 < objectCount ? packfileIndex.entries[i + 1].offset : dataReader.data.count - 20
            
            if let objectType = packfileObjectType?.objectType {
                let thisOffset = entry.offset + numberByteCount
                guard let data = dataReader.readData(bytes: nextOffset - thisOffset).uncompressed() else {
                    fatalError("Couldn't uncompress data")
                }
                if data.count != length {
                    fatalError("Inflated object should be correct length")
                }
                
                let object = objectType.objectClass.init(hash: entry.hash, data: data, repository: repository)
                
                chunks[entry.offset] = PackfileChunk(data: data, object: object)
            } else {
                if packfileObjectType == .ofsDelta {
                    var currentByte: [UInt8] = dataReader.readBits(bytes: 1)
                    var negativeOffset = Array(currentByte[1 ..< 8]).bitIntValue()
                    var backwardsDistanceByteCount = 1
                    
                    
                    while currentByte[0] == 1 {
                        currentByte = dataReader.readBits(bytes: 1)
                        negativeOffset += 1
                        negativeOffset <<= 7
                        negativeOffset += Array(currentByte[1 ..< 8]).bitIntValue()
                        backwardsDistanceByteCount += 1
                    }
                    
                    let deltaFromObjectOffset = entry.offset - negativeOffset
                    let chunk = chunks[deltaFromObjectOffset]!
                    let baseObject = chunk.data
                    
                    let thisOffset = entry.offset + numberByteCount + backwardsDistanceByteCount
                    let data = dataReader.readData(bytes: nextOffset - thisOffset)
                    let deltaData = data.uncompressed()!
                    let deltaReader = DataReader(data: deltaData)!
                    _ = deltaReader.readVariableLengthInt() // Source length
                    _ = deltaReader.readVariableLengthInt() // Target length
                    
                    var builtData = Data()
                    
                    while deltaReader.canRead {
                        let byte = deltaReader.readBits(bytes: 1)
                        
                        if byte[0] == 0 { // Insertion
                            let insertionByteCount = Array(byte[1 ..< 8]).bitIntValue()
                            builtData.append(deltaReader.readData(bytes: insertionByteCount))
                        } else { // Copy
                            var offsetBits: [UInt8] = []
                            for bitIndex in 0 ..< 4 {
                                if byte[7 - bitIndex] == 1 {
                                    let byte = deltaReader.readBits(bytes: 1)
                                    offsetBits = byte + offsetBits
                                } else {
                                    offsetBits = Array(repeating: 0, count: 8) + offsetBits // Add empty byte
                                }
                            }
                            let offset = offsetBits.bitIntValue()
                            
                            var sizeBits: [UInt8] = []
                            for bitIndex in 0 ..< 3 {
                                if byte[3 - bitIndex] == 1 {
                                    let byte = deltaReader.readBits(bytes: 1)
                                    sizeBits = byte + sizeBits
                                } else {
                                    sizeBits = Array(repeating: 0, count: 8) + sizeBits // Add empty byte
                                }
                            }
                            let bitValue = sizeBits.bitIntValue()
                            let size = bitValue == 0 ? 0x10000 : bitValue
                            
                            builtData.append(baseObject.subdata(in: offset ..< (offset + size)))
                        }
                    }
                    
                    print(chunk.object.type.objectClass.init(hash: entry.hash, data: builtData, repository: repository).cat())
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
