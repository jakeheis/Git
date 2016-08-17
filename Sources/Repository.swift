import Foundation

struct Paths {
    static let hiddenDirectory = ".git"
}

struct Repository {
    
    let url: URL
    
    private var internalDirectory: URL {
        return url.appendingPathComponent(".git")
    }
    
    init?(path: String) {
        let url = URL(fileURLWithPath: path)
        self.init(url: url)
    }
    
    init?(url: URL) {
        do {
            if try !url.appendingPathComponent(Paths.hiddenDirectory).checkResourceIsReachable() {
                return nil
            }
        } catch {
             return nil
        }
        
        self.url = url
    }
    
    func suburl(with path: String) -> URL {
        return internalDirectory.appendingPathComponent(path)
    }
    
}