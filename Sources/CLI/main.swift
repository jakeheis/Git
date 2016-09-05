import Darwin.C
import SwiftCLI
import FileKit
import Core

//Path.Current = "/Users/jakeheiser/Documents/Swift/Git"
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

let result = CLI.debugGo(with: "git ls-tree 8393ade13629654eea620a491feb6af1c74d4bb3")
exit(result)

// xcodebuild -project Git.xcodeproj -scheme Git clean build | grep [1-9].[0-9]ms | sort -nr > culprits.txt
