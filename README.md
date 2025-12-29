# UnionUI

A comprehensive collection of SwiftUI components and utilities for iOS development.

## Installation

Add UnionUI to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/unionst/union-ui.git", from: "1.0.0")
]
```

## Usage

Simply import UnionUI in your Swift files:

```swift
import SwiftUI
import UnionUI

struct MyView: View {
    var body: some View {
        VStack {
            Text("Hello")
                .unionFont(.title)
        }
    }
}
```

All components from all sub-packages are available with just the single `import UnionUI` statement.

### Benefits

- **Single Import**: Use `import UnionUI` instead of importing 35+ individual packages
- **Clean Sidebar**: Xcode shows only one package dependency instead of dozens
- **Automatic Updates**: All components update together as a unified package
- **No Version Conflicts**: Internal dependencies are managed automatically

## Components

This single import gives you access to all UnionUI components:

- **UnionAddressButton** - Address button components
- **UnionAnimatedNumber** - Animated number displays with currency support
- **UnionBlurs** - Blur effects and materials
- **UnionBorderMask** - Border masking utilities
- **UnionButtons** - Button components with haptics
- **UnionConfetti** - Confetti animations
- **UnionCursor** - Cursor utilities
- **UnionDebounce** - Debouncing utilities
- **UnionFonts** - Font utilities
- **UnionGestures** - Custom gesture recognizers
- **UnionGradients** - Gradient utilities
- **UnionHaptics** - Haptic feedback
- **UnionHash** - Hashing utilities
- **UnionImage** - Image utilities
- **UnionKeyboard** - Keyboard management
- **UnionKeychain** - Keychain wrapper
- **UnionLoading** - Loading indicators
- **UnionMaps** - Map utilities
- **UnionMaterials** - Material effects
- **UnionModify** - View modification utilities
- **UnionNetwork** - Networking utilities
- **UnionNetworking** - Advanced networking
- **UnionNotifications** - Notification components
- **UnionNumbers** - Number formatting and utilities
- **UnionPersistence** - Data persistence
- **UnionScreen** - Screen utilities
- **UnionScroll** - Scroll utilities
- **UnionShake** - Shake animations
- **UnionShapes** - Custom shapes
- **UnionShareLink** - Share link components
- **UnionSheets** - Sheet utilities
- **UnionStacks** - Stack utilities
- **UnionTabBar** - Tab bar components
- **UnionTabView** - Tab view components
- **UnionToast** - Toast notifications

## Requirements

- iOS 17.0+
- Swift 6.1+

## License

See individual component directories for licensing information.

