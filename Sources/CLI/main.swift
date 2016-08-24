import Darwin.C
import SwiftCLI
import FileKit
import Core

Path.Current = "/Users/jakeheiser/Documents/Swift/Git"

//let r = Repository(path: Path.Current)!

CLI.setup(name: "Git")

let plumbing: [RepositoryCommand] = [
    CatFileCommand(),
    LsFilesCommand(),
    LsTreeCommand()
]

let porcelain: [RepositoryCommand] = [
    BranchCommand(),
    LogCommand(),
    StatusCommand(),
    TagCommand()
]

CLI.register(commands: plumbing)
CLI.register(commands: porcelain)

let result = CLI.debugGo(with: "git ls-tree -r dc16361a31c86f8176b6093a052a2ff18f69e235")
exit(result)
