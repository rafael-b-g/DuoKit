// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "DuoKit",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "DuoKit",
            targets: ["DuoKit"]
        ),
    ],
    targets: [
        .target(
            name: "DuoKit",
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
        .testTarget(name: "DuoKitTests", dependencies: ["DuoKit"]),
    ]
)
