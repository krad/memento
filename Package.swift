// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "memento",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "memento",
            targets: ["memento"]),
    ],
    dependencies: [
        .package(url: "https://www.github.com/krad/Clibavcodec.git", from: "0.0.9"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "memento",
            dependencies: []),
        .testTarget(
            name: "mementoTests",
            dependencies: ["memento"]),
    ]
)
