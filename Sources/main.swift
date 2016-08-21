import Foundation

let repo = Repository(path: "/Users/jakeheiser/Documents/Swift/Git")!

let trees = repo.objects.flatMap { $0 as? Tree }
let tree = trees.first!
tree.ls()

let blobs = repo.objects.flatMap { $0 as? Blob }
let blob = blobs[2]
print(blob.contents)
