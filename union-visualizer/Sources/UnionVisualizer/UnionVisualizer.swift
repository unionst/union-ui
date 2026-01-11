import SwiftUI
import UIKit

/// A fluid, mesh-gradient style visualizer that creates animated warping effects on an image.
/// Inspired by Apple Music's album art background animation.
public struct Visualizer: View {
    private let image: Image
    private let animationSpeed: Double
    private let blur: CGFloat

    private static let maxImageSize: CGFloat = 100

    public init(
        _ resource: ImageResource,
        animationSpeed: Double = 1.0,
        blur: CGFloat = 20
    ) {
        self.image = Self.loadDownsampled(resource)
        self.animationSpeed = animationSpeed
        self.blur = blur
    }

    private static func loadDownsampled(_ resource: ImageResource) -> Image {
        autoreleasepool {
            let uiImage = UIImage(resource: resource)
            let downsampled = downsample(uiImage, maxSize: maxImageSize)
            return Image(uiImage: downsampled)
        }
    }

    private static func downsample(_ image: UIImage, maxSize: CGFloat) -> UIImage {
        let size = image.size
        let scale = min(maxSize / size.width, maxSize / size.height, 1.0)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    public var body: some View {
        TimelineView(.animation) { timeline in
            GeometryReader { geometry in
                let size = geometry.size
                let time = timeline.date.timeIntervalSinceReferenceDate * animationSpeed

                // Background layer animation
                let rotation0 = Angle(radians: time * 0.01)
                let offsetX0 = cos(time * 0.02) * size.width * 0.05
                let offsetY0 = sin(time * 0.015) * size.height * 0.05

                // Top layer animation
                let rotation1 = Angle(radians: time * 0.02)
                let offsetX1 = cos(time * 0.03) * size.width * 0.15
                let offsetY1 = sin(time * 0.025) * size.height * 0.1 - size.height * 0.25

                // Bottom layer animation
                let rotation2 = Angle(radians: time * -0.015 + 1.0)
                let offsetX2 = cos(time * 0.035 + 2.0) * size.width * 0.15
                let offsetY2 = sin(time * 0.03 + 2.0) * size.height * 0.1 + size.height * 0.25

                ZStack {
                    // Background image
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size.width * 2.0, height: size.height * 2.0)
                        .rotationEffect(rotation0)
                        .offset(x: offsetX0, y: offsetY0)

                    // Top image
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: size.width * 1.0, height: size.height * 0.7)
                        .rotationEffect(rotation1)
                        .offset(x: offsetX1, y: offsetY1)

                    // Bottom image
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: size.width * 1.0, height: size.height * 0.7)
                        .rotationEffect(rotation2)
                        .offset(x: offsetX2, y: offsetY2)
                }
                .saturation(1.3)
                .contrast(0.4)
                .brightness(-0.15)
                .blur(radius: blur)
                .frame(width: size.width, height: size.height)
                .clipped()
            }
        }
    }
}
