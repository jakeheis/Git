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
//    Path.Current = "/Users/jakeheiser/Documents/Swift/Git"
//    Path.Current = "/Users/jakeheiser/Documents/Apps/Git Implementations/git"
    Path.Current = "/Users/jakeheiser/Documents/Swift/initgit"
}

if isDebug {
    let r = Repository(path: Path.Current)!
    print(r)
}

CLI.setup(name: "sgit", version: "0.0.1", description: "Like git but in Swift")

let plumbing: [RepositoryCommand] = [
    CatFileCommand(),
    CommitTreeCommand(),
    HashObjectCommand(),
    LsFilesCommand(),
    LsTreeCommand(),
    UpdateIndexCommand(),
    UpdateRefCommand(),
    VerifyPackCommand(),
    WriteTreeCommand()
]

let porcelain: [RepositoryCommand] = [
    BranchCommand(),
    CommitCommand(),
    LogCommand(),
    StatusCommand(),
    TagCommand()
]

CLI.register(commands: plumbing)
CLI.register(commands: porcelain)

let result: CLIResult
if isDebug {
    result = 0 //CLI.debugGo(with: "sgit update-ref HEAD 1e3965ebd93700a8c6acf99e7372bd59de5b0e39")
} else {
    result = CLI.go()
}
exit(result)

// xcodebuild -project Git.xcodeproj -scheme Git clean build | grep [1-9].[0-9]ms | sort -nr > culprits.txt
