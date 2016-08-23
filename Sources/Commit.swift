import Foundation

class Commit: Object {
    
    let treeHash: String
    var tree: Tree {
        guard let tree = repository.objectStore[treeHash] as? Tree else {
            fatalError("Couldn't resolve tree hash \(treeHash)")
        }
        return tree
    }
    
    let parentHash: String?
    var parent: Commit? {
        guard let parentHash = parentHash else {
            return nil
        }
        return repository.objectStore[parentHash] as? Commit
    }
    
    let author: Annotation
    let commit: Annotation
    let message: String
    
    required init(hash: String, data: Data, repository: Repository) {
        var lines = String(data: data, encoding: .ascii)!.components(separatedBy: "\n")
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
            author = Annotation(annotation: typeLines.removeFirst().value)
        } else {
            parentHash = nil
            author = Annotation(annotation: secondLine.value)
        }
        commit = Annotation(annotation: typeLines.removeFirst().value)
        _ = typeLines.removeFirst()
        message = typeLines.map({ $0.type + " " + $0.value }).joined(separator: "\n")
        
        super.init(hash: hash, data: data, type: .commit, repository: repository)
    }
    
    func log() -> String {
        return [treeHash, parentHash ?? "(first)", String(describing: author), String(describing: commit), "", message].joined(separator: "\n")
    }
    
}
