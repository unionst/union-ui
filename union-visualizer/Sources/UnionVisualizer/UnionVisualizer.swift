import SwiftUI

/// A fluid, mesh-gradient style visualizer that creates animated warping effects on an image.
/// Inspired by Apple Music's album art background animation.
public struct Visualizer: View {
    private let image: Image
    private let animationSpeed: Double

    private static let shaderLibrary = ShaderLibrary.bundle(.module)

    public init(
        _ resource: ImageResource,
        animationSpeed: Double = 1.0
    ) {
        self.image = Image(resource)
        self.animationSpeed = animationSpeed
    }

    public var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate * animationSpeed

                // Background layer animation
                let rotation = Angle(radians: time * 0.015)
                let offsetX = cos(time * 0.03) * size.width * 0.1
                let offsetY = sin(time * 0.025) * size.height * 0.1

                // Foreground layer animation
                let rotation2 = Angle(radians: time * -0.02 + 0.5)
                let offsetX2 = cos(time * 0.04 + 1.5) * size.width * 0.2
                let offsetY2 = sin(time * 0.035 + 1.5) * size.height * 0.2

                // 16 mesh control points (4x4 grid)
                let p = meshControlPoints(time: time, size: size)

                ZStack {
                    // Background layer
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size.width * 2.5, height: size.height * 2.5)
                        .rotationEffect(rotation)
                        .offset(x: offsetX, y: offsetY)

                    // Foreground layer with mesh distortion
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: size.width * 1.2, height: size.height * 1.2)
                        .distortionEffect(
                            Self.shaderLibrary.meshDistort(
                                .float2(size),
                                // Row 0
                                .float2(p[0]), .float2(p[1]), .float2(p[2]), .float2(p[3]),
                                // Row 1
                                .float2(p[4]), .float2(p[5]), .float2(p[6]), .float2(p[7]),
                                // Row 2
                                .float2(p[8]), .float2(p[9]), .float2(p[10]), .float2(p[11]),
                                // Row 3
                                .float2(p[12]), .float2(p[13]), .float2(p[14]), .float2(p[15])
                            ),
                            maxSampleOffset: CGSize(width: size.width * 0.4, height: size.height * 0.4)
                        )
                        .rotationEffect(rotation2)
                        .offset(x: offsetX2, y: offsetY2)
                }
                .frame(width: size.width, height: size.height)
                .clipped()
            }
        }
    }

    /// Generate 16 animated control point displacements for the mesh (4x4 grid)
    private func meshControlPoints(time: Double, size: CGSize) -> [CGPoint] {
        var points: [CGPoint] = []
        let amplitude = min(size.width, size.height) * 0.35

        for row in 0..<4 {
            for col in 0..<4 {
                let index = row * 4 + col
                let phase = Double(index) * 0.5

                // Vary amplitude based on position - more in center
                let centerDistX = abs(Double(col) - 1.5) / 1.5
                let centerDistY = abs(Double(row) - 1.5) / 1.5
                let centerFactor = 1.0 - (centerDistX + centerDistY) * 0.3

                // Each point moves in a unique pattern
                let dx = cos(time * 0.05 + phase) * amplitude * centerFactor
                let dy = sin(time * 0.04 + phase * 1.3) * amplitude * centerFactor

                points.append(CGPoint(x: dx, y: dy))
            }
        }

        return points
    }
}
