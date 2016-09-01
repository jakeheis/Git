import Foundation
import FileKit

public class Blob: Object {
    
    public let data: Data
    
    public static func formBlob(from file: Path, in repository: Repository) -> Blob? {
        let contentData: Data
        if file.isSymbolicLink {
            guard let data = (try? FileManager.default.destinationOfSymbolicLink(atPath: file.rawValue))?.data(using: .ascii) else {
                return nil
            }
            contentData = data
        } else {
            guard let data = try? NSData.readFromPath(file) as Data else {
                return nil
            }
            contentData = data
        }
        
        let header = "\(ObjectType.blob.rawValue) \(contentData.count)\0"
        guard let headerData = header.data(using: .utf8) else {
            fatalError("Could not generate header data for blob")
        }
        guard let sha = (headerData + contentData).sha1() else {
            fatalError("Could not hash file")
        }
         let hash = DataReader(data: sha).readHex(bytes: 20)
        
        return Blob(hash: hash, data: contentData, repository: repository)
    }
    
    public required init(hash: String, data: Data, repository: Repository) {
        self.data = data
                
        super.init(hash: hash, type: .blob, repository: repository)
    }
    
    override public func cat() -> String {
        let contents = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) ?? "(Could not represent blob data as string)"
        return contents
    }
    
}
