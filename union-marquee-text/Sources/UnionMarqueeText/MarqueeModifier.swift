import SwiftUI

public extension Text {
    func marquee(speed: Double = 30.0, delay: Double = 4.0, insets: CGFloat? = nil, easeOutDistance: CGFloat = 40.0) -> some View {
        MarqueeText(text: self, speed: speed, delay: delay, insets: insets, easeOutDistance: easeOutDistance)
    }
}

struct MarqueeText: View {
    let text: Text
    let speed: Double
    let delay: Double
    let insets: CGFloat?
    let easeOutDistance: CGFloat

    @Environment(\.multilineTextAlignment) private var textAlignment

    @State private var contentWidth: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var offset: CGFloat = 0
    @State private var animationPhase: AnimationPhase = .idle
    @State private var animationTask: Task<Void, Never>?
    @State private var isVisible = false

    private enum AnimationPhase {
        case idle
        case linear
        case easeOut
    }

    private var needsScrolling: Bool {
        contentWidth > containerWidth && containerWidth > 0
    }

    private var spacing: CGFloat {
        contentHeight * 2
    }

    private var featherWidth: CGFloat {
        insets ?? (contentHeight * 0.6)
    }

    private var totalDistance: CGFloat {
        contentWidth + spacing
    }

    private var linearDistance: CGFloat {
        max(0, totalDistance - easeOutDistance)
    }

    private var linearDuration: Double {
        linearDistance / speed
    }

    private var easeOutDuration: Double {
        // Ease out takes a bit longer since it decelerates
        (easeOutDistance / speed) * 1.5
    }

    private var frameAlignment: Alignment {
        switch textAlignment {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }

    private var currentAnimation: Animation? {
        switch animationPhase {
        case .idle:
            return nil
        case .linear:
            return .linear(duration: linearDuration)
        case .easeOut:
            return .easeOut(duration: easeOutDuration)
        }
    }

    var body: some View {
        text
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: frameAlignment)
            .opacity(needsScrolling ? 0 : 1)
            .background(
                GeometryReader { containerGeometry in
                    text
                        .fixedSize()
                        .hidden()
                        .background(
                            GeometryReader { textGeometry in
                                Color.clear
                                    .onAppear {
                                        contentWidth = textGeometry.size.width
                                        contentHeight = textGeometry.size.height
                                        containerWidth = containerGeometry.size.width
                                    }
                                    .onChange(of: textGeometry.size.width) { _, newWidth in
                                        contentWidth = newWidth
                                    }
                                    .onChange(of: textGeometry.size.height) { _, newHeight in
                                        contentHeight = newHeight
                                    }
                                    .onChange(of: containerGeometry.size.width) { _, newWidth in
                                        containerWidth = newWidth
                                    }
                            }
                        )
                }
            )
            .overlay {
                if needsScrolling && containerWidth > 0 {
                    HStack(spacing: spacing) {
                        text.fixedSize()
                        text.fixedSize()
                    }
                    .offset(x: offset + featherWidth)
                    .animation(currentAnimation, value: offset)
                    .frame(width: containerWidth + featherWidth, height: contentHeight, alignment: .leading)
                    .clipped()
                    .mask {
                        HStack(spacing: 0) {
                            LinearGradient(
                                colors: [.clear, .black],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: featherWidth)

                            Rectangle().fill(.black)

                            LinearGradient(
                                colors: [.black, .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: featherWidth)
                        }
                    }
                    .frame(width: containerWidth, alignment: .trailing)
                }
            }
            .onAppear {
                isVisible = true
                restartAnimationIfNeeded()
            }
            .onDisappear {
                isVisible = false
                stopScrolling()
            }
            .onChange(of: needsScrolling) { _, _ in
                restartAnimationIfNeeded()
            }
    }
    
    private func restartAnimationIfNeeded() {
        stopScrolling()
        guard isVisible && needsScrolling else { return }
        startScrolling()
    }
    
    private func startScrolling() {
        animationTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))

            while !Task.isCancelled && needsScrolling && isVisible {
                // Phase 1: Linear animation for most of the distance
                animationPhase = .linear
                offset = -linearDistance

                try? await Task.sleep(for: .seconds(linearDuration))
                guard !Task.isCancelled else { break }

                // Phase 2: Ease out for the final portion
                animationPhase = .easeOut
                offset = -totalDistance

                try? await Task.sleep(for: .seconds(easeOutDuration))
                guard !Task.isCancelled else { break }

                // Reset to start position
                animationPhase = .idle
                offset = 0

                try? await Task.sleep(for: .seconds(delay))
            }
        }
    }

    private func stopScrolling() {
        animationTask?.cancel()
        animationTask = nil
        animationPhase = .idle
        offset = 0
    }
}
