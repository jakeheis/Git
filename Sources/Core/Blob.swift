import Foundation
import FileKit

public class Blob: Object {
    
    public let data: Data
    
    public required init(hash: String, data: Data, repository: Repository) {
        self.data = data
                
        super.init(hash: hash, type: .blob, repository: repository)
    }
    
    public init?(file: Path, repository: Repository) {
        guard let contentData = try? NSData.readFromPath(file) as Data else {
            return nil
        }
        
        self.data = contentData
        
        super.init(contentData: contentData, type: .blob, repository: repository)
    }
    
    override public func cat() -> String {
        let contents = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) ?? "(Could not represent blob data as string)"
        return contents
    }
    
}
