import Darwin.C
import SwiftCLI
import FileKit
import Core

Path.Current = "/Users/jakeheiser/Documents/Swift/Git/Tests/Repositories/Basic"

//let r = Repository(path: Path.Current)!

CLI.setup(name: "Git")

let plumbing: [RepositoryCommand] = [
    CatFileCommand(),
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

let result = CLI.debugGo(with: "git cat-file -p b1cab66f094cc38fe71fdc425de075851e69bee2")
exit(result)

// xcodebuild -project Git.xcodeproj -scheme Git clean build | grep [1-9].[0-9]ms | sort -nr > culprits.txt
