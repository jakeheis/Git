//
//  Reflog.swift
//  Git
//
//  Created by Jake Heiser on 10/13/16.
//
//

import Foundation
import FileKit

public class Reflog {
    
    static let folder = "logs"
    
    public let path: Path
    
    public private(set) var entries: [ReflogEntry]
    
    init(ref: Ref, repository: Repository) {
        self.path = repository.subpath(with: Reflog.folder + "/" + ref.path)
        
        var entries: [ReflogEntry] = []
        if let contents = try? String(contentsOfPath: self.path) {
            for line in contents.components(separatedBy: "\n") where !line.isEmpty {
                entries.append(ReflogEntry(line: line))
            }
        }
        self.entries = entries
    }
    
    func append(entry: ReflogEntry) throws {
        entries.append(entry)
        try write()
    }
    
    func write() throws {
        let text = entries.map({ String(describing: $0) }).joined(separator: "\n") + "\n"
        try text.writeToPath(path)
    }
    
}

public struct ReflogEntry {
    
    public let oldHash: String
    public let newHash: String
    public let signature: Signature
    public let message: String?
    
    init(oldHash: String, newHash: String, signature: Signature, message: String?) {
        self.oldHash = oldHash
        self.newHash = newHash
        self.signature = signature
        self.message = message
    }
    
    init(line: String) {
        let segments = line.components(separatedBy: "\t")
        
        let hashWords = segments[0].components(separatedBy: " ")
        self.oldHash = hashWords[0]
        self.newHash = hashWords[1]
        self.signature = Signature(signature: hashWords[2 ..< hashWords.count].joined(separator: " "))
        
        self.message = segments.count > 1 ? segments[1] : nil
    }
    
}

extension ReflogEntry: CustomStringConvertible {
    
    public var description: String {
        var text = "\(oldHash) \(newHash) \(signature)"
        if let message = message {
            text += "\t\(message)"
        }
        return text
    }
    
}
