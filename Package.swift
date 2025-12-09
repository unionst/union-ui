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
    targets: [
        .target(
            name: "UnionUI",
            dependencies: [
                "UnionAddressButton",
                "UnionAnimatedNumber",
                "UnionBlurs",
                "UnionBorderMask",
                "UnionButtons",
                "UnionChat",
                "UnionConfetti",
                "UnionCursor",
                "UnionDebounce",
                "UnionFonts",
                "UnionGestures",
                "UnionGradients",
                "UnionHaptics",
                "UnionHash",
                "UnionImage",
                "UnionKeyboard",
                "UnionKeychain",
                "UnionLoading",
                "UnionMaps",
                "UnionMaterials",
                "UnionModify",
                "UnionNetwork",
                "UnionNetworking",
                "UnionNotifications",
                "UnionNumbers",
                "UnionPersistence",
                "UnionScreen",
                "UnionScroll",
                "UnionShake",
                "UnionShapes",
                "UnionShareLink",
                "UnionSheets",
                "UnionStacks",
                "UnionTabBar",
                "UnionTabView",
                "UnionToast"
            ],
            path: "Sources/UnionUI"
        ),
        
        .target(
            name: "UnionHaptics",
            path: "union-haptics/Sources/union-haptics"
        ),
        
        .target(
            name: "UnionGestures",
            dependencies: ["EdgeGestureModifier"],
            path: "union-gestures/Sources/UnionGestures"
        ),
        
        .target(
            name: "EdgeGestureModifier",
            path: "coverd-edge-gesture/Sources/UnionGestures"
        ),
        
        .target(
            name: "UnionShake",
            path: "union-shake/Sources/UnionShake"
        ),
        
        .target(
            name: "UnionGradients",
            path: "union-gradients/Sources/UnionGradients"
        ),
        
        .target(
            name: "UnionButtons",
            dependencies: ["UnionHaptics", "UnionGestures"],
            path: "union-buttons/Sources/UnionButtons"
        ),
        
        .target(
            name: "UnionScroll",
            path: "union-scroll/Sources/UnionScroll"
        ),
        
        .target(
            name: "UnionAnimatedNumber",
            dependencies: ["UnionShake", "UnionGradients"],
            path: "union-animated-number/Sources/UnionAnimatedNumber"
        ),
        
        .target(
            name: "UnionMaterials",
            path: "union-materials/Sources/UnionMaterials"
        ),
        
        .target(
            name: "UnionChat",
            dependencies: ["UnionMaterials", "UnionButtons"],
            path: "union-chat/source/Sources/union-chat"
        ),
        
        .target(
            name: "UnionToast",
            dependencies: ["UnionHaptics", "UnionScroll", "UnionGestures"],
            path: "union-toast/Sources/UnionToast"
        ),
        
        .target(
            name: "UnionNotifications",
            dependencies: ["UnionButtons"],
            path: "union-notifications/Sources/UnionNotifications",
            resources: [
                .process("Resources")
            ]
        ),
        
        .target(
            name: "UnionAddressButton",
            path: "union-address-button/Sources/UnionAddressButton"
        ),
        
        .target(
            name: "UnionBlurs",
            path: "union-blurs/Sources/UnionBlurs"
        ),
        
        .target(
            name: "UnionBorderMask",
            path: "union-border-mask/Sources/union-border-mask"
        ),
        
        .target(
            name: "UnionConfetti",
            path: "union-confetti/Sources/ConfettiView"
        ),
        
        .target(
            name: "UnionCursor",
            path: "union-cursor/Sources/UnionCursor"
        ),
        
        .target(
            name: "UnionDebounce",
            path: "union-debounce/Sources/UnionDebounce"
        ),
        
        .target(
            name: "UnionFonts",
            path: "union-fonts/Sources/union-fonts"
        ),
        
        .target(
            name: "UnionHash",
            path: "union-hash/Sources/UnionHash"
        ),
        
        .target(
            name: "UnionImage",
            path: "union-image/Sources/UnionImage"
        ),
        
        .target(
            name: "UnionKeyboard",
            path: "union-keyboard/Sources/UnionKeyboard"
        ),
        
        .target(
            name: "UnionKeychain",
            path: "union-keychain/Sources/UnionKeychain"
        ),
        
        .target(
            name: "UnionLoading",
            path: "union-loading/Sources/UnionLoading"
        ),
        
        .target(
            name: "UnionMaps",
            path: "union-maps/Sources/UnionMaps"
        ),
        
        .target(
            name: "UnionModify",
            path: "union-modify/Sources/UnionModify"
        ),
        
        .target(
            name: "UnionNetwork",
            path: "union-network/Sources/UnionNetwork"
        ),
        
        .target(
            name: "UnionNetworking",
            path: "union-networking/Sources/UnionNetworking"
        ),
        
        .target(
            name: "UnionNumbers",
            path: "union-numbers/Sources/UnionNumbers"
        ),
        
        .target(
            name: "UnionPersistence",
            path: "union-persistence/Sources/UnionPersistence"
        ),
        
        .target(
            name: "UnionScreen",
            path: "union-screen/Sources/UnionScreen"
        ),
        
        .target(
            name: "UnionShapes",
            path: "union-shapes/Sources/UnionShapes"
        ),
        
        .target(
            name: "UnionShareLink",
            path: "union-share-link/Sources/UnionShareLink"
        ),
        
        .target(
            name: "UnionSheets",
            path: "union-sheets/Sources/union-sheets"
        ),
        
        .target(
            name: "UnionStacks",
            path: "union-stacks/Sources/UnionStacks"
        ),
        
        .target(
            name: "UnionTabBar",
            path: "union-tab-bar/Sources/UnionTabBar"
        ),
        
        .target(
            name: "UnionTabView",
            path: "union-tab-view/Sources/UnionTabView"
        )
    ]
)

