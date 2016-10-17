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
    
    convenience init(repository: Repository) {
        let ignoreFile = repository.path + ".gitignore"
        
        let lines: [String]
        if let contents = try? String.read(from: ignoreFile) {
            lines = contents.components(separatedBy: "\n")
        } else {
            lines = []
        }
        
        self.init(lines: lines)
    }
    
    init(lines: [String]) {
        var ignoreEntries = [GitIgnoreEntry(".git")!]
        ignoreEntries += lines.flatMap { (line) in
            return GitIgnoreEntry(line)
        }
        
        self.ignoreEntries = ignoreEntries
    }
    
    func ignoreFile(_ file: String) -> Bool {
        for entry in ignoreEntries {
            if entry.matches(file) {
                return true
            }
        }
        return false
    }
    
    func ignoreDirectory(_ directory: String) -> Bool {
        for entry in ignoreEntries {
            if entry.matches(directory, directory: true) {
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
    
    let fileRegex: NSRegularExpression
    let directoryRegex: NSRegularExpression?
    
    let negate: Bool
    
    init?(_ text: String) {
        // TODO: this is pretty ugly, kinda hacked together
        
        var originalText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if originalText.hasPrefix("#") || originalText.isEmpty { // Comment or empty line
            return nil
        }
        if originalText.hasPrefix("!") {
            negate = true
            originalText = originalText.substring(from: originalText.index(after: originalText.startIndex)) // Remove !
        } else {
            negate = false
        }
        
        let startsWithDoubleAsterisk: Bool
        if originalText.hasPrefix("**/") {
            originalText = originalText.substring(from: originalText.index(originalText.startIndex, offsetBy: 3)) // Remove **/
            startsWithDoubleAsterisk = true
        } else {
            startsWithDoubleAsterisk = false
        }
        
        if originalText.hasSuffix("/**") {
            originalText = originalText.substring(to: originalText.index(originalText.endIndex, offsetBy: -3)) // Remove /**
            if !originalText.hasPrefix("/") {
                originalText = "/" + originalText // Ending in /** is like starting with /
            }
        }
        
        let placeholder = "\0\0\0"
        var wildText = originalText.replacingOccurrences(of: "/**", with: placeholder) // /** in the middle of a path matches zero or more directories
        wildText = wildText.replacingOccurrences(of: "+", with: "\\+") // Escape special regex characters
        wildText = wildText.replacingOccurrences(of: ".", with: "\\.") // Escape special regex characters
        wildText = wildText.replacingOccurrences(of: "*", with: "[^\\/]*") // Wildcards can be any character besides /
        wildText = wildText.replacingOccurrences(of: placeholder, with: "(\\/.*)*") // Wildcards can be any character besides /
        
        var regexText = "^"
        if wildText.hasPrefix("/") {
            regexText += wildText.substring(from: wildText.index(after: wildText.startIndex)) // Remove leading slash
        } else {
            let slashInMiddle = originalText.substring(with: originalText.index(after: originalText.startIndex) ..< originalText.index(before: originalText.endIndex)).contains("/")
            if !slashInMiddle || startsWithDoubleAsterisk {
                regexText += "(.*\\/)*" // Match matches within directories if no slash in entry
            }
            if wildText.hasPrefix("\\") {
                regexText += wildText.substring(from: wildText.index(after: wildText.startIndex)) // Remove leading back slash
            } else {
                regexText += wildText
            }
        }
        
        if regexText.hasSuffix("/") {
            regexText = regexText.substring(to: regexText.index(before: regexText.endIndex)) // Remove trailing slash
            
            let directoryText = regexText + "(\\/.*)*$" // Match directory itself and all contained files
            guard let directoryRegex = try? NSRegularExpression(pattern: directoryText, options: []) else {
                return nil
            }
            self.directoryRegex = directoryRegex
            
            regexText += "(\\/.*)+" // Only match contained files, not file with name itself
        } else {
            self.directoryRegex = nil
            regexText += "(\\/.*)*" // Match directory itself and all contained files
        }
        
        regexText += "$"
        
        guard let fileRegex = try? NSRegularExpression(pattern: regexText, options: []) else {
            return nil
        }
        self.fileRegex = fileRegex
    }
    
    func matches(_ path: String, directory: Bool = false) -> Bool {
        if directory {
            if let directoryRegex = directoryRegex {
                return !directoryRegex.matches(in: path, options: [], range: NSRange(location: 0, length: path.characters.count)).isEmpty
            }
        }
        return !fileRegex.matches(in: path, options: [], range: NSRange(location: 0, length: path.characters.count)).isEmpty
    }
    
}
