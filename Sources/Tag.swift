import Foundation
import FileKit

class Tag: Reference {
    
}

extension Repository {
    
    var tags: [Tag] {
        get {
            let tagsDirectory = subpath(with: "refs/tags")
            return tagsDirectory.flatMap { Tag(path: $0) }
        }
    }
    
}

func arg()  {
    
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = ["printf", "\"\\x1f\\x8b\\x08\\x00\\x00\\x00\\x00\\x00\""]
    task.standardOutput = Pipe()
    
    let task2 = Process()
    task2.launchPath = "/usr/bin/env"
    task2.arguments = ["cat", "-", "/Users/jakeheiser/Documents/Swift/Git/.git/objects/1b/1749ea312ac4fce5a2883d471be35a80524176"]
    task2.standardInput = task.standardOutput
    task2.standardOutput = Pipe()
    
    let task3 = Process()
    task3.launchPath = "/usr/bin/env"
    task3.arguments = ["gzip", "-dc"]
    task3.standardInput = task2.standardOutput
    
    task.launch()
    // task.waitUntilExit()
    task2.launch()
    // task2.waitUntilExit()
    task3.launch()
    // task3.waitUntilExit()
    
    //   if let pipe = task.standardOutput as? Pipe {
    //           let data = pipe.fileHandleForReading.readDataToEndOfFile()
    //           if let string = String(data: data, encoding: String.Encoding.utf8) {
    //               print(string)
    //           }
    // }
}
