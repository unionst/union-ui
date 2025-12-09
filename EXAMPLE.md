# Using UnionUI in Your Project

## Adding to Xcode Project

1. In Xcode, go to **File → Add Package Dependencies...**
2. Enter the repository URL: `https://github.com/unionst/union-ui.git`
3. Select version or branch
4. Add to your target

## Adding to Package.swift

If you're building a Swift package, add UnionUI to your dependencies:

```swift
// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "YourApp",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "YourApp",
            targets: ["YourApp"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/unionst/union-ui.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "YourApp",
            dependencies: [
                .product(name: "UnionUI", package: "union-ui")
            ]
        )
    ]
)
```

## Example Usage

```swift
import SwiftUI
import UnionUI

struct ContentView: View {
    @State private var amount = 1234.56
    @State private var showToast = false
    
    var body: some View {
        VStack(spacing: 20) {
            AnimatedNumber(value: amount, format: .currency)
            
            Button("Show Toast") {
                showToast = true
            }
            .hapticButtonStyle()
        }
        .toast(isPresented: $showToast) {
            Text("Hello from UnionUI!")
        }
    }
}
```

## What You Get

With a single `import UnionUI`, you have access to:

- 35+ component packages
- Haptic feedback utilities
- Animated components
- Custom buttons and navigation
- Chat interfaces
- Toast notifications
- And much more!

Your Xcode project sidebar will show just **one** dependency instead of 35+ separate packages.

