import PackageDescription

let package = Package(
    name: "CLITests_",
    dependencies: [
        .Package(url: "https://github.com/jakeheis/FileKit", Version(4, 0, 0, prereleaseIdentifiers: ["beta"])),
        .Package(url: "https://github.com/onevcat/Rainbow", Version(2, 0, 0, prereleaseIdentifiers: ["alpha", "1"]))
    ]
)
