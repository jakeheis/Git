//
//  GitIgnore.swift
//  Git
//
//  Created by Jake Heiser on 8/24/16.
//
//

import Foundation
import FileKit

public class GitIgnore {
    
    let ignoreEntries: [GitIgnoreEntry]
    let repository: Repository
    
    init(repository: Repository) {
        var ignoreEntries = [GitIgnoreEntry(".git")!]
        
        let ignoreFile = repository.path + ".gitignore"
        if let contents = try? String.readFromPath(ignoreFile) {
            ignoreEntries += contents.components(separatedBy: "\n").flatMap { (line) in
                return GitIgnoreEntry(line)
            }
        }
        
        self.ignoreEntries = ignoreEntries
        self.repository = repository
    }
    
    func ignoreFile(_ file: String) -> Bool {
        for entry in ignoreEntries {
            if entry.matches(file) {
                return true
            }
        }
        return false
    }
    
}

extension Repository {
    
    public var gitIgnore: GitIgnore {
        return GitIgnore(repository: self)
    }
    
}

public struct GitIgnoreEntry {
    
    let regex: NSRegularExpression
    
    init?(_ text: String) {
        var regexText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if regexText.hasPrefix("#") || regexText.isEmpty { // Comment
            return nil
        }
        if regexText.hasPrefix("/") {
            regexText = regexText.substring(from: regexText.index(after: regexText.startIndex))
        }
        // TODO: Make this work for all git ignore entries
        
        regexText = "^(.*\\/)*" + regexText.replacingOccurrences(of: "*", with: "[^\\/]*")
        regexText += "(\\/.*)*$" // If directory, match contained files
        guard let regex = try? NSRegularExpression(pattern: regexText, options: []) else {
            return nil
        }
        self.regex = regex
    }
    
    func matches(_ path: String) -> Bool {
        return !regex.matches(in: path, options: [], range: NSRange(location: 0, length: path.characters.count)).isEmpty
    }
    
}
