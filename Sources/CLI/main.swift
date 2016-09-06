import Darwin.C
import SwiftCLI
import FileKit
import Core
import Foundation

let isDebug: Bool
if let name = ProcessInfo.processInfo.arguments.first, name.hasSuffix(".build/debug/CLI") {
    isDebug = false
} else {
    isDebug = true
}

if isDebug {
    Path.Current = "/Users/jakeheiser/Documents/Swift/Flock"
    let r = Repository(path: Path.Current)!
    
//    print(r.index?.entries)
//    try! TreeWriter(index: r.index!).write(actuallyWrite: false)
}

CLI.setup(name: "Git")

let plumbing: [RepositoryCommand] = [
    CatFileCommand(),
    HashObjectCommand(),
    LsFilesCommand(),
    LsTreeCommand(),
    VerifyPackCommand()
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
    result = CLI.debugGo(with: "git cat-file -p HEAD")
} else {
    result = CLI.go()
}
exit(result)

// xcodebuild -project Git.xcodeproj -scheme Git clean build | grep [1-9].[0-9]ms | sort -nr > culprits.txt
