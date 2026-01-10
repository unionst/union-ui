// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "union-visualizer",
    platforms: [.iOS(.v17)],
    products: [.library(name: "UnionVisualizer", targets: ["UnionVisualizer"])],
    targets: [
        .target(
            name: "UnionVisualizer"
        )
    ]
)
