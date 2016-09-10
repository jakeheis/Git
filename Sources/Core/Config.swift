//
//  Config.swift
//  Git
//
//  Created by Jake Heiser on 9/8/16.
//
//

import FileKit

public class Config {
    
    public static let global = Config(path: Path(rawValue: "~/.gitconfig").standardized)
    
    public let groups: [ConfigGroup]
    public let path: Path
    
    private let keyedGroups: [String: ConfigGroup]
    
    public static func value(for key: String, in group: String) -> String? {
        if let group = Config.global?.keyedGroups[group] {
            return group.values[key]
        }
        return nil
    }
    
    init?(path: Path) {
        guard var lines = (try? String.readFromPath(path))?.components(separatedBy: "\n") else {
            return nil
        }
        
        var groups: [ConfigGroup] = []
        var keyedGroups: [String: ConfigGroup] = [:]
        while !lines.isEmpty {
            let firstLine = lines.removeFirst().trimmingCharacters(in: .whitespacesAndNewlines)
            if firstLine.hasPrefix("#") || firstLine.isEmpty {
                continue
            }
            guard firstLine.hasPrefix("[") else {
                fatalError("Something went wrong")
            }
            if firstLine.hasPrefix("[") {
                let name = firstLine.substring(with: firstLine.index(after: firstLine.startIndex) ..< firstLine.index(before: firstLine.endIndex))
                
                var entries: [(key: String, value: String)] = []
                while !lines.isEmpty {
                    if !lines.first!.hasPrefix("\t") {
                        break
                    }
                    let line = lines.removeFirst()
                    guard let equalsIndex = line.characters.index(of: "=") else {
                        fatalError("No = in line")
                    }
                    let key = line.substring(to: equalsIndex).trimmingCharacters(in: .whitespaces)
                    let value = line.substring(from: line.index(after: equalsIndex)).trimmingCharacters(in: .whitespaces)
                    entries.append((key, value))
                }
                let newGroup = ConfigGroup(name: name, entries: entries)
                groups.append(newGroup)
                keyedGroups[newGroup.name] = newGroup
            }
        }
        
        self.groups = groups
        self.path = path
        self.keyedGroups = keyedGroups
    }
    
}

extension Config: CustomStringConvertible {

    public var description: String {
        return groups.map({ $0.output() }).joined(separator: "\n")
    }
    
}

// MARK: - ConfigGroup

public struct ConfigGroup {
    
    public let name: String
    public let entries: [(key: String, value: String)]
    public let values: [String: String]
    
    init(name: String, entries: [(key: String, value: String)]) {
        self.name = name
        self.entries = entries
        
        var values: [String: String] = [:]
        for entry in entries {
            values[entry.key] = entry.value
        }
        self.values = values
    }
    
    public func output() -> String {
        var lines = ["[\(name)]"]
        for entry in entries {
            lines.append("\t\(entry.key) = \(entry.value)")
        }
        return lines.joined(separator: "\n")
    }
    
}

extension ConfigGroup: CustomStringConvertible {
    
    public var description: String {
        return output()
    }
    
}
