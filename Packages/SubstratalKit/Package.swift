// swift-tools-version: 6.0
// SubstratalKit: everything the Hub shares between iOS/iPadOS and (later) macOS.
// SubstratalAPI is generated from openapi.yaml at build time; SubstratalCore wraps it with the
// request conventions from CLIENT-ARCHITECTURE §4; SubstratalUI holds the theme and shared components.
import PackageDescription

let package = Package(
    name: "SubstratalKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SubstratalAPI", targets: ["SubstratalAPI"]),
        .library(name: "SubstratalCore", targets: ["SubstratalCore"]),
        .library(name: "SubstratalUI", targets: ["SubstratalUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.10.0"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.8.0"),
        .package(url: "https://github.com/apple/swift-openapi-urlsession", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-http-types", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "SubstratalAPI",
            dependencies: [.product(name: "OpenAPIRuntime", package: "swift-openapi-runtime")],
            plugins: [.plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")]
        ),
        .target(
            name: "SubstratalCore",
            dependencies: [
                "SubstratalAPI",
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
                .product(name: "HTTPTypes", package: "swift-http-types"),
            ]
        ),
        .target(name: "SubstratalUI", dependencies: ["SubstratalCore"]),
        .testTarget(name: "SubstratalCoreTests", dependencies: ["SubstratalCore"]),
    ]
)
