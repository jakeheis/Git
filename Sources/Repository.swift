import Foundation
import FileKit

struct Paths {
    static let hiddenDirectory = ".git"
}

struct Repository {
    
    let path: Path
    
    private var internalDirectory: Path {
        return path + ".git"
    }
    
    init?(path: String) {
        self.init(path: Path(path))
    }
    
    init?(url: URL) {
        guard let path = Path(url: url) else {
            return nil
        }
        self.init(path: path)
    }
    
    init?(path: Path) {
        guard (path + ".git").isDirectory else {
            return nil
        }
        self.path = path
    }
    
    func subpath(with sub: String) -> Path {
        return internalDirectory + sub
    }
    
}