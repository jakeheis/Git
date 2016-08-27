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
        
        var chunks: [Int: Data] = [:]
        
        let objectCount = dataReader.readInt(bytes: 4)
        
        for i in 0 ..< objectCount {
            print("NEXT", i)
            let objectMetadata = dataReader.readBits(bytes: 1)
            let packfileObjectType = PackfileObjectType(rawValue: Array(objectMetadata[1 ..< 4]).bitIntValue())
            var numberBits = Array(objectMetadata[4 ..< 8])
            print(objectMetadata)
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
                let data = dataReader.readData(bytes: nextOffset - thisOffset)
                chunks[entry.offset] = try! (data as NSData).gzipUncompressed() as Data
                let object = try! Object.from(data: data, hash: entry.hash, type: objectType, repository: repository)
                
                if let blob = object as? Blob, blob.data.count != length {
                    fatalError("Inflated blob should be correct length")
                }
//                print(object.cat())
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
                    let baseObject = chunks[deltaFromObjectOffset]!
                    
                    let thisOffset = entry.offset + numberByteCount + backwardsDistanceByteCount
                    let data = dataReader.readData(bytes: nextOffset - thisOffset)
                    let deltaData = try! (data as NSData).gzipUncompressed() as Data
                    let deltaReader = DataReader(data: deltaData)!
                    _ = deltaReader.readVariableLengthInt() // Source length
                    _ = deltaReader.readVariableLengthInt() // Target length
                    
                    var builtData = Data()
                    
                    while deltaReader.canRead {
                        let byte = deltaReader.readBits(bytes: 1)
                        let instructionInt = byte.bitIntValue()
                        
                        // TODO: Swift-ify; this is translated directrly from dulwich
                        if instructionInt & 0x80 == 0 { // Insertion
                            let insertionByteCount = Array(byte[1 ..< 8]).bitIntValue()
                            builtData.append(deltaReader.readData(bytes: insertionByteCount))
                        } else { // Copy
                            var cp_off = 0
                            for i in 0 ..< 4 {
                                if instructionInt & (1 << i) > 0 {
                                    let byte = deltaReader.readInt(bytes: 1)
                                    cp_off |= byte << (i * 8)
                                }
                            }
                            var cp_size = 0
                            for i in 0 ..< 3 {
                                if instructionInt & (1 << (4 + i)) > 0 {
                                    let byte = deltaReader.readInt(bytes: 1)
                                    cp_size |= byte << (i * 8)
                                }
                            }
                            if cp_size == 0 {
                                cp_size = 0x10000
                            }
                            builtData.append(baseObject.subdata(in: cp_off ..< (cp_off + cp_size)))
                        }
                    }
                    
                    print(Tree(hash: entry.hash, data: builtData, repository: repository).cat())
                    
                    break
                    
                } else {
                    let parent = dataReader.readHex(bytes: 20)
                    print("delta from", parent)
                }
            }
        }
    }
    
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
