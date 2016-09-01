import Foundation
import FileKit

public class Repository {
    
    static let internalDirectory = ".git"
    
    public let path: Path
    
    public convenience init?(path: String) {
        self.init(path: Path(path))
    }
    
    public convenience init?(url: URL) {
        guard let path = Path(url: url) else {
            return nil
        }
        self.init(path: path)
    }
    
    public init?(path: Path) {
        guard (path + Repository.internalDirectory).isDirectory else {
            return nil
        }
        self.path = path
    }
    
    func subpath(with sub: String) -> Path {
        return path + Repository.internalDirectory + sub
    }
    
}
