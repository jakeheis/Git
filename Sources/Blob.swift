import Foundation

class Blob: Object {
    
    let contents: String
    
    required init(hash: String, data: Data, repository: Repository) {
        self.contents = String(data: data, encoding: .ascii) ?? String()
                
        super.init(hash: hash, data: data, type: .blob, repository: repository)
    }
    
}
