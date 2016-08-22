import Foundation
import FileKit

enum Head {
    case hash(String)
    case ref(String)
    
    init?(path: Path) {
        guard let contents = try? String.readFromPath(path) else {
            return nil
        }
        
        self.init(text: contents)
    }
    
    init(text: String) {
        if text.hasPrefix("ref: "), let refSpace = text.characters.index(of: " ") {
            let startIndex = text.index(refSpace, offsetBy: 1)
            let endIndex = text.characters.index(of: "\n") ?? text.endIndex
            let ref = text.substring(with: startIndex ..< endIndex)
            self = .ref(ref)
        } else {
            self = .hash(text.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
    
}

extension Repository {
    
    var head: Head? {
        get {
            return Head(path: subpath(with: "HEAD"))
        }
    }
    
}
