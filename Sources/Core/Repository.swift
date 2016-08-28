import Foundation
import FileKit

public class Repository {
    
    public let path: Path
    
    private var internalDirectory: Path {
        return path + ".git"
    }
    
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
        guard (path + ".git").isDirectory else {
            return nil
        }
        self.path = path
    }
    
    func subpath(with sub: String) -> Path {
        return internalDirectory + sub
    }
    
}
