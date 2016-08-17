import Foundation

struct Tag {
    let name: String
    let hash: String
    
    init?(url: URL) {
        guard let hash = try? String(contentsOf: url, encoding: String.Encoding.utf8) else {
            return nil
        }
        
        self.name = url.lastPathComponent
        self.hash = hash.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}

extension Repository {
    
    var tags: [Tag] {
        get {
            let directoryURL = suburl(with: "refs/tags")
            if let urls = try? FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: []) {
                return urls.flatMap { Tag(url: $0) }
            }
            return []
        }
    }
    
}