import Darwin.C
import SwiftCLI
import FileKit
import Core
import Foundation

Path.Current = "/Users/jakeheiser/Documents/Swift/Git"
//let r = Repository(path: Path.Current)!

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
if let name = ProcessInfo.processInfo.arguments.first, name.hasSuffix(".build/debug/CLI") {
    result = CLI.go()
} else {
    result = CLI.debugGo(with: "git hash-object -w .gitignore")
}
exit(result)

// xcodebuild -project Git.xcodeproj -scheme Git clean build | grep [1-9].[0-9]ms | sort -nr > culprits.txt
