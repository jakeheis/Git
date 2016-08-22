import Foundation

let repo = Repository(path: "/Users/jakeheiser/Documents/Swift/initgit")!
//let repo = Repository(path: "/Users/jakeheiser/Documents/Swift/Git")!

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

let annotatedTags = repo.objects.flatMap { $0 as? AnnotatedTag }
print((annotatedTags.first!.object as! Commit).log())
