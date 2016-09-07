import Darwin.C
import SwiftCLI
import FileKit
import Core
import Foundation

let isDebug: Bool
if let name = ProcessInfo.processInfo.arguments.first, name.hasSuffix(".build/debug/CLI") {
    if ProcessInfo.processInfo.arguments.count > 1 {
        isDebug = (ProcessInfo.processInfo.arguments[1] == "-d")
    } else {
        isDebug = false
    }
} else {
    isDebug = true
    Path.Current = "/Users/jakeheiser/Documents/Swift/Git"
}

if isDebug {
    let r = Repository(path: Path.Current)!
    
    print(r.index!.rootTreeExtension)
}

CLI.setup(name: "Git")

let plumbing: [RepositoryCommand] = [
    CatFileCommand(),
    HashObjectCommand(),
    LsFilesCommand(),
    LsTreeCommand(),
    VerifyPackCommand(),
    WriteTreeCommand()
]

let porcelain: [RepositoryCommand] = [
    BranchCommand(),
    LogCommand(),
    StatusCommand(),
    TagCommand()
]

CLI.register(commands: plumbing)
CLI.register(commands: porcelain)

let result: CLIResult
if isDebug {
//    result = CLI.debugGo(with: "git cat-file -p HEAD")
} else {
    result = CLI.go()
}
//exit(result)

// xcodebuild -project Git.xcodeproj -scheme Git clean build | grep [1-9].[0-9]ms | sort -nr > culprits.txt
