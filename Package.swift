import PackageDescription

let package = Package(
    name: "Git",
    dependencies: [
        .Package(url: "https://github.com/jakeheis/FileKit", Version(4, 0, 0, prereleaseIdentifiers: ["beta"]))
    ]
)
