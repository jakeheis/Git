import Foundation

class Blob: Object {
    
    let contents: String
    
    required init(hash: String, data: Data, repository: Repository) {
        self.contents = String(data: data, encoding: .ascii) ?? String()
        
        _ = (data as NSData).subdata(with: NSRange(location: 0, length: 1)) // Keeps compiler from crashing
        
        super.init(hash: hash, data: data, type: .blob, repository: repository)
    }
    
}
