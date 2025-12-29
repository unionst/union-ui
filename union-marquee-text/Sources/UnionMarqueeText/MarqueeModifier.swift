import SwiftUI

public extension Text {
    func marquee(duration: Double = 8.0, delay: Double = 4.0, insets: CGFloat? = nil) -> some View {
        MarqueeText(text: self, duration: duration, delay: delay, insets: insets)
    }
}

struct MarqueeText: View {
    let text: Text
    let duration: Double
    let delay: Double
    let insets: CGFloat?
    
    @State private var contentWidth: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var offset: CGFloat = 0
    @State private var isAnimating = false
    
    private var needsScrolling: Bool {
        contentWidth > containerWidth && containerWidth > 0
    }
    
    private var isScrolling: Bool {
        offset < 0
    }
    
    private var spacing: CGFloat {
        contentHeight * 2
    }

    private var featherWidth: CGFloat {
        insets ?? (contentHeight * 0.6)
    }

    var body: some View {
        text
            .lineLimit(1)
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
                    .animation(isAnimating ? .linear(duration: duration) : nil, value: offset)
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
                if needsScrolling {
                    startScrolling()
                }
            }
            .onChange(of: needsScrolling) { _, scrolling in
                if scrolling {
                    startScrolling()
                } else {
                    stopScrolling()
                }
            }
    }
    
    private func startScrolling() {
        Task {
            try? await Task.sleep(for: .seconds(delay))
            
            while needsScrolling {
                isAnimating = true
                offset = -(contentWidth + spacing)
                
                try? await Task.sleep(for: .seconds(duration))
                
                isAnimating = false
                offset = 0
                
                try? await Task.sleep(for: .seconds(delay))
            }
        }
    }
    
    private func stopScrolling() {
        isAnimating = false
        offset = 0
    }
}
