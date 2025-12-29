import SwiftUI

public extension Text {
    func marquee(duration: Double = 8.0, delay: Double = 4.0) -> some View {
        MarqueeText(text: self, duration: duration, delay: delay)
    }
}

struct MarqueeText: View {
    let text: Text
    let duration: Double
    let delay: Double
    
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
        contentHeight * 3
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
                    .offset(x: offset)
                    .animation(isAnimating ? .linear(duration: duration) : nil, value: offset)
                    .frame(width: containerWidth, height: contentHeight, alignment: .leading)
                    .clipped()
                    .mask {
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: isScrolling ? .clear : .black, location: 0),
                                .init(color: .black, location: isScrolling ? contentHeight / containerWidth : 0),
                                .init(color: .black, location: 1 - (contentHeight / containerWidth)),
                                .init(color: .clear, location: 1)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
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
