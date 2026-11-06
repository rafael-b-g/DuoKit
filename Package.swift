// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DuoKit",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "DuoKit",
            targets: ["DuoKit"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "DuoKit",
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
    ]
)
