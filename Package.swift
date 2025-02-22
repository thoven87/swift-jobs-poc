// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-jobs-poc",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .executable(
            name: "swift-jobs-poc",
            targets: ["App"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", branch: "main"),
        .package(
            url: "https://github.com/hummingbird-project/swift-jobs.git", branch: "main"),
        .package(
            url: "https://github.com/hummingbird-project/hummingbird-postgres.git", branch: "main"),
        .package(
            url: "https://github.com/hummingbird-project/swift-jobs-postgres.git", branch: "main"),
        .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.25.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "HummingbirdPostgres", package: "hummingbird-postgres"),
                .product(name: "HummingbirdRouter", package: "hummingbird"),
                .product(name: "Jobs", package: "swift-jobs"),
                .product(name: "JobsPostgres", package: "swift-jobs-postgres"),
                .product(name: "PostgresNIO", package: "postgres-nio"),
            ]
        )
    ]
)
