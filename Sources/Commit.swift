import Foundation

class Commit: Object {
    
    let treeHash: String
    let authorString: String
    let commitString: String
    let message: String
    
    required init(hash: String, data: Data) {
        _ = (data as NSData).subdata(with: NSRange(location: 0, length: 1)) // Keeps compiler from crashing
        
        var lines = String(data: data, encoding: .ascii)!.components(separatedBy: "\n")
        
        treeHash = lines.removeFirst()
        authorString = lines.removeFirst()
        commitString = lines.removeFirst()
        _ = lines.removeFirst()
        message = lines.joined(separator: "\n")
        
        super.init(hash: hash, data: data, type: .commit)
    }
    
    func log() -> String {
        return [treeHash, authorString, commitString, "", message].joined(separator: "\n")
    }
    
}
