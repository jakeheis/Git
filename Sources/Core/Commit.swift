import Foundation

public class Commit: Object {
    
    public let treeHash: String
    public var tree: Tree {
        guard let tree = repository.objectStore[treeHash] as? Tree else {
            fatalError("Couldn't resolve tree hash \(treeHash)")
        }
        return tree
    }
    
    public let parentHash: String?
    public var parent: Commit? {
        guard let parentHash = parentHash else {
            return nil
        }
        return repository.objectStore[parentHash] as? Commit
    }
    
    public let authorSignature: Signature
    public let committerSignature: Signature
    public let message: String
    
    public required init(hash: String, data: Data, repository: Repository) {
        guard let contents = String(data: data, encoding: .ascii) else {
            fatalError("Couldn't read object \(hash)")
        }
        var lines = contents.components(separatedBy: "\n")
        _ = lines.removeLast() // Blank line
        var typeLines: [(type: String, value: String)] = lines.map { (line) in
            var words = line.components(separatedBy: " ")
            let type = words.removeFirst()
            return (type, words.joined(separator: " "))
        }
        
        treeHash = typeLines.removeFirst().value
        let secondLine = typeLines.removeFirst()
        if secondLine.type == "parent" {
            parentHash = secondLine.value
            authorSignature = Signature(signature: typeLines.removeFirst().value)
        } else {
            parentHash = nil
            authorSignature = Signature(signature: secondLine.value)
        }
        
        committerSignature = Signature(signature: typeLines.removeFirst().value)
        _ = typeLines.removeFirst()
        message = typeLines.map({ $0.type + " " + $0.value }).joined(separator: "\n")
        
        super.init(hash: hash, data: data, type: .commit, repository: repository)
    }
    
    override public func cat() -> String {
        let lines = [
            "tree \(treeHash)",
            "parent \(parentHash ?? "(none)")",
            "author \(authorSignature)",
            "committer \(committerSignature)",
            "",
            message
        ]
        return lines.joined(separator: "\n")
    }
    
}
