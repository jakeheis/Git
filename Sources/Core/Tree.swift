import Foundation

public class Tree: Object {
    
    public let treeEntries: [TreeEntry]
    
    public required init(hash: String, data: Data, repository: Repository) {
        guard let fileReader = FileReader(data: data) else {
            fatalError("Couldn't read data of tree: \(hash)")
        }
        
        var treeEntries: [TreeEntry] = []
        while fileReader.canRead {
            let mode = fileReader.read(until: " ")
            let name = fileReader.read(until: "\0")
            let entryHash = fileReader.readHex(length: 20)
            let entry = TreeEntry(mode: mode, hash: entryHash, name: name, repository: repository)
            treeEntries.append(entry)
        }
        
        self.treeEntries = treeEntries
        
        super.init(hash: hash, data: data, type: .tree, repository: repository)
    }
    
    override public func cat() -> String {
        let lines = treeEntries.map { String(describing: $0) }
        return lines.joined(separator: "\n")
    }
    
}

public struct TreeEntry {
    
    public enum Mode: Int {
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
    
    public let mode: Mode
    public let hash: String
    public let name: String
    let repository: Repository
    
    public var object: Object {
        guard let object = repository.objectStore[hash] else {
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
    public var description: String {
        return "\(mode.intText) \(mode.name) \(hash) \(name)"
    }
}

