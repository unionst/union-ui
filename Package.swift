// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "union-ui",
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
        .package(url: "https://github.com/unionst/union-address-button.git", branch: "main"),
        .package(url: "https://github.com/unionst/union-animated-number.git", branch: "main"),
        .package(url: "https://github.com/unionst/union-blurs.git", branch: "main"),
        .package(url: "https://github.com/unionst/union-border-mask.git", branch: "main"),
        .package(url: "https://github.com/unionst/union-buttons.git", branch: "main"),
        .package(url: "https://github.com/unionst/union-confetti.git", branch: "main"),
        .package(url: "https://github.com/unionst/union-cursor.git", branch: "main"),
        .package(url: "https://github.com/unionst/union-debounce.git", branch: "main"),
        .package(url: "https://github.com/unionst/union-fonts.git", branch: "main"),
        .package(url: "https://github.com/unionst/union-gestures.git", branch: "main"),
        .package(url: "https://github.com/unionst/union-gradients.git", branch: "main"),
        .package(url: "https://github.com/unionst/union-haptics.git", branch: "main"),
        .package(url: "https://github.com/unionst/union-hash.git", branch: "main"),
        .package(url: "https://github.com/unionst/union-image.git", branch: "main"),
        .package(url: "https://github.com/unionst/union-keychain.git", branch: "main"),
        .package(url: "https://github.com/unionst/union-loading.git", branch: "main"),
        .package(url: "https://github.com/unionst/union-maps.git", branch: "main"),
        .package(url: "https://github.com/unionst/union-materials.git", branch: "main"),
        .package(url: "https://github.com/unionst/union-modify.git", branch: "main"),
        .package(url: "https://github.com/unionst/union-network.git", branch: "main"),
        .package(url: "https://github.com/unionst/union-networking.git", branch: "main"),
        .package(url: "https://github.com/unionst/union-notifications.git", branch: "main"),
        .package(url: "https://github.com/unionst/union-numbers.git", branch: "main"),
        .package(url: "https://github.com/unionst/union-persistence.git", branch: "main"),
        .package(url: "https://github.com/unionst/union-scroll.git", branch: "main"),
        .package(url: "https://github.com/unionst/union-shake.git", branch: "main"),
        .package(url: "https://github.com/unionst/union-shapes.git", branch: "main"),
        .package(url: "https://github.com/unionst/union-share-link.git", branch: "main"),
        .package(url: "https://github.com/unionst/union-stacks.git", branch: "main"),
        .package(url: "https://github.com/unionst/union-tab-view.git", branch: "main"),
        .package(url: "https://github.com/unionst/union-toast.git", branch: "main")
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
