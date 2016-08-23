import Foundation

public class Blob: Object {
    
    public let contents: String
    
    public required init(hash: String, data: Data, repository: Repository) {
        self.contents = String(data: data, encoding: .ascii) ?? String()
                
        super.init(hash: hash, data: data, type: .blob, repository: repository)
    }
    
    override public func cat() -> String {
        return contents
    }
    
}
