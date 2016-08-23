import Darwin.C
import Core
import SwiftCLI
import FileKit

//let repo = Repository(path: "/Users/jakeheiser/Documents/Swift/initgit")!
//let repo = Repository(path: "/Users/jakeheiser/Documents/Swift/Git")!
//let repo = Repository(path: "/Users/jakeheiser/Documents/Apps/HinsdaleCentral")!

//let trees = repo.objects.flatMap { $0 as? Tree }
//let tree = trees.first!
//tree.ls()

//let blobs = repo.objects.flatMap { $0 as? Blob }
//let blob = blobs[2]
//print(blob.contents)

//let commits = repo.objects.flatMap { $0 as? Commit }
//let commit = commits[3]
//print(commit.hash)
//print(commit.log())

//print((commit.tree.treeEntries.first!.object as! Blob).contents)

//print(commit.parent?.log())

//let tags = repo.tags
//print(tags)
//
//print((tags.first!.object as! Commit).log())

//let index = repo.index!
//print(index.entries)

//print(repo.head!.commit!.log())

Path.Current = "/Users/jakeheiser/Documents/Swift/Git"

CLI.setup(name: "Git")

CLI.register(command: CatFileCommand())
CLI.register(command: LogCommand())

let result = CLI.debugGo(with: "git log")
exit(result)
