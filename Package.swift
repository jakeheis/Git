import PackageDescription

let package = Package(
    name: "Git",
    dependencies: [
        .Package(url: "https://github.com/jakeheis/FileKit", Version(4, 0, 0, prereleaseIdentifiers: ["beta"])),
        .Package(url: "/Users/jakeheiser/Documents/Swift/Czlib", majorVersion: 1, minor: 0)
    ]
)
