import Foundation

struct Paths {
    static let hiddenDirectory = ".git"
}

struct Repository {
    
    let url: URL
    
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
    
}