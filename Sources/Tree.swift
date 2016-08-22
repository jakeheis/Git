import Foundation

class Tree: Object {
    
    let treeEntries: [TreeEntry]
    
    required init(hash: String, data: Data, repository: Repository) {
        var unparsed = String(data: data, encoding: .ascii)!        
        var byteCounter = 0
        var treeEntries: [TreeEntry] = []
        
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
            
            let object = TreeEntry(mode: mode, hash: hash as String, name: name, repository: repository)
            treeEntries.append(object)
        }
        
        self.treeEntries = treeEntries
        
        super.init(hash: hash, data: data, type: .tree, repository: repository)
    }
    
    func ls() {
        for treeEntry in treeEntries {
            print(treeEntry)
        }
    }
    
}

struct TreeEntry {
    
    enum Mode: Int {
        case directory = 40000
        case blob = 100644
        case executable = 100755
        case link = 120000
        
        var intText: String {
            if self == .directory {
                return "0" + String(describing: rawValue)
            }
            return String(describing: rawValue)
        }
        
        var name: String {
            switch self {
            case .directory: return "tree"
            case .blob, .link, .executable: return "blob"
            }
        }
    }
    
    let mode: Mode
    let hash: String
    let name: String
    let repository: Repository
    
    var object: Object {
        guard let object = try? Object.from(hash: hash, in: repository) else {
            fatalError("Could not resolve tree entry: \(hash)")
        }
        return object
    }
    
    init(mode raw: String, hash: String, name: String, repository: Repository) {
        guard let modeInt = Int(raw), let mode = Mode(rawValue: modeInt) else {
            fatalError("Unrecognized mode: \(raw)")
        }
        self.mode = mode
        self.hash = hash
        self.name = name
        self.repository = repository
    }
    
}

extension TreeEntry: CustomStringConvertible {
    var description: String {
        return "\(mode.intText) \(mode.name) \(hash) \(name)"
    }
}

