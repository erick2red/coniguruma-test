// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "coniguruma-test",
    platforms: [
        .macOS(.v11)
    ],
    targets: [
        .systemLibrary(name: "coniguruma", pkgConfig: "oniguruma", providers: [.brew(["oniguruma"])]),
        .target(
            name: "coniguruma-test",
            dependencies: ["coniguruma"]),
    ]
)
