//
//  FileDiff.swift
//  Git
//
//  Created by Jake Heiser on 9/12/16.
//
//

import Foundation
import FileKit

public class FileDiff {
    
    let original: Path
    let new: Path
    let fileName: String
    
    public init(original: Path, new: Path, fileName: String) {
        self.original = original
        self.new = new
        self.fileName = fileName
    }
    
    public func generate() -> [String]? {
        var lines: [String]
        if new.exists {
            let output = Pipe()
            
            let process = Process()
            process.launchPath = "/usr/bin/diff"
            process.arguments = ["-u", original.rawValue, new.rawValue]
            process.standardOutput = output
            process.launch()
            process.waitUntilExit()
            
            let data = output.fileHandleForReading.readDataToEndOfFile()
            guard let string = String(data: data, encoding: .utf8) else {
                return nil
            }
            
            lines = string.components(separatedBy: "\n")
            lines[0] = "--- a/\(fileName)"
            lines[1] = "+++ b/\(fileName)"
        } else {
            guard let contents = try? String.readFromPath(original) else {
                return nil
            }
            let rawLines = contents.components(separatedBy: "\n").map({ "-" + $0 })
            
            lines = ["--- a/\(fileName)", "+++ /dev/null"] + rawLines
        }
        
       
        lines.insert("diff --git a/\(fileName) b/\(fileName)", at: 0)
        
        return lines
    }
    
}
