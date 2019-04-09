// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "AFNetworking",
    products: [
        .library(name: "AFNetworking", targets: ["AFNetworking"])
    ],
    targets: [
        .target(
            name: "AFNetworking",
            path: "AFNetworking"
        )
    ]
)
