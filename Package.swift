// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "UnionUI",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "UnionUI",
            targets: ["UnionUI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/unionst/union-address-button.git", from: "1.0.0"),
        .package(url: "https://github.com/unionst/union-animated-number.git", from: "1.0.0"),
        .package(url: "https://github.com/unionst/union-blurs.git", from: "1.0.0"),
        .package(url: "https://github.com/unionst/union-border-mask.git", from: "1.0.0"),
        .package(url: "https://github.com/unionst/union-buttons.git", from: "2.0.0"),
        .package(url: "https://github.com/unionst/union-confetti.git", from: "1.0.0"),
        .package(url: "https://github.com/unionst/union-cursor.git", from: "2.0.0"),
        .package(url: "https://github.com/unionst/union-debounce.git", from: "1.0.0"),
        .package(url: "https://github.com/unionst/union-fonts.git", from: "1.0.0"),
        .package(url: "https://github.com/unionst/union-gestures.git", from: "1.0.0"),
        .package(url: "https://github.com/unionst/union-gradients.git", from: "1.0.0"),
        .package(url: "https://github.com/unionst/union-haptics.git", from: "1.0.0"),
        .package(url: "https://github.com/unionst/union-hash.git", from: "1.0.0"),
        .package(url: "https://github.com/unionst/union-image.git", from: "1.0.0"),
        .package(url: "https://github.com/unionst/union-keychain.git", from: "1.0.0"),
        .package(url: "https://github.com/unionst/union-loading.git", from: "1.0.0"),
        .package(url: "https://github.com/unionst/union-maps.git", from: "1.0.0"),
        .package(url: "https://github.com/unionst/union-materials.git", from: "1.0.0"),
        .package(url: "https://github.com/unionst/union-modify.git", from: "1.0.0"),
        .package(url: "https://github.com/unionst/union-network.git", from: "1.0.0"),
        .package(url: "https://github.com/unionst/union-networking.git", from: "1.0.0"),
        .package(url: "https://github.com/unionst/union-notifications.git", from: "1.0.0"),
        .package(url: "https://github.com/unionst/union-numbers.git", from: "1.0.0"),
        .package(url: "https://github.com/unionst/union-persistence.git", from: "1.0.0"),
        .package(url: "https://github.com/unionst/union-scroll.git", from: "1.0.0"),
        .package(url: "https://github.com/unionst/union-shake.git", from: "1.0.0"),
        .package(url: "https://github.com/unionst/union-shapes.git", from: "1.0.0"),
        .package(url: "https://github.com/unionst/union-share-link.git", from: "1.0.0"),
        .package(url: "https://github.com/unionst/union-stacks.git", from: "1.0.0"),
        .package(url: "https://github.com/unionst/union-tab-view.git", from: "1.0.0"),
        .package(url: "https://github.com/unionst/union-toast.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "UnionUI",
            dependencies: [
                .product(name: "UnionAddressButton", package: "union-address-button"),
                .product(name: "UnionAnimatedNumber", package: "union-animated-number"),
                .product(name: "UnionBlurs", package: "union-blurs"),
                .product(name: "UnionBorderMask", package: "union-border-mask"),
                .product(name: "UnionButtons", package: "union-buttons"),
                .product(name: "UnionConfetti", package: "union-confetti"),
                .product(name: "UnionCursor", package: "union-cursor"),
                .product(name: "UnionDebounce", package: "union-debounce"),
                .product(name: "UnionFonts", package: "union-fonts"),
                .product(name: "UnionGestures", package: "union-gestures"),
                .product(name: "UnionGradients", package: "union-gradients"),
                .product(name: "UnionHaptics", package: "union-haptics"),
                .product(name: "UnionHash", package: "union-hash"),
                .product(name: "UnionImage", package: "union-image"),
                .product(name: "UnionKeychain", package: "union-keychain"),
                .product(name: "UnionLoading", package: "union-loading"),
                .product(name: "UnionMaps", package: "union-maps"),
                .product(name: "UnionMaterials", package: "union-materials"),
                .product(name: "UnionModify", package: "union-modify"),
                .product(name: "UnionNetwork", package: "union-network"),
                .product(name: "UnionNetworking", package: "union-networking"),
                .product(name: "UnionNotifications", package: "union-notifications"),
                .product(name: "UnionNumbers", package: "union-numbers"),
                .product(name: "UnionPersistence", package: "union-persistence"),
                .product(name: "UnionScroll", package: "union-scroll"),
                .product(name: "UnionShake", package: "union-shake"),
                .product(name: "UnionShapes", package: "union-shapes"),
                .product(name: "UnionShareLink", package: "union-share-link"),
                .product(name: "UnionStacks", package: "union-stacks"),
                .product(name: "UnionTabView", package: "union-tab-view"),
                .product(name: "UnionToast", package: "union-toast")
            ],
            path: "Sources/UnionUI"
        )
    ]
)
