import Foundation

class Tree: Object {
    
    typealias TreeObject = (mode: Int, hash: String, name: String)
    
    let treeObjects: [TreeObject]
    
    required init(hash: String, data: Data) {
        var unparsed = String(data: data, encoding: .ascii)!
        
        var byteCounter = 0
        let headerIndex = unparsed.characters.index(of: "\0")!
        byteCounter += unparsed.distance(from: unparsed.startIndex, to: headerIndex) + 1
        unparsed = unparsed.substring(from: unparsed.index(headerIndex, offsetBy: 1))
        
        var treeObjects: [TreeObject] = []
        while !unparsed.isEmpty {
            let modeIndex = unparsed.characters.index(of: " ")!
            let mode = unparsed.substring(to: modeIndex)
            byteCounter += unparsed.distance(from: unparsed.startIndex, to: modeIndex) + 1
            unparsed = unparsed.substring(from: unparsed.index(modeIndex, offsetBy: 1))
            
            let nameIndex = unparsed.characters.index(of: "\0")!
            let name = unparsed.substring(to: nameIndex)
            byteCounter += unparsed.distance(from: unparsed.startIndex, to: nameIndex) + 1
            unparsed = unparsed.substring(from: unparsed.index(nameIndex, offsetBy: 1))
            
            let hashIndex = unparsed.index(unparsed.startIndex, offsetBy: 20)
            // let hashBytes = data.subdata(in: byteCounter..<(byteCounter + 20))
            let hashBytes = (data as NSData).subdata(with: NSRange(location: byteCounter, length: 20))
            unparsed = unparsed.substring(from: hashIndex)
            byteCounter += 20
            
            let hash = NSMutableString()
            for i in 0..<hashBytes.count {
                hash.append(NSString(format: "%02x", hashBytes[i]) as String)
            }

            let object = (Int(mode) ?? 0, hash as String, name)
            treeObjects.append(object)
        }
        
        self.treeObjects = treeObjects
        
        super.init(hash: hash, data: data, type: .tree)
    }
    
    func ls() {
        for treeObject in treeObjects {
            print(treeObject.mode, treeObject.hash, treeObject.name)
        }
    }
    
}

