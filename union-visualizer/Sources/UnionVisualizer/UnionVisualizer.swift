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

            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate * animationSpeed

                // Background layer animation
                let rotation = Angle(radians: time * 0.015)
                let offsetX = cos(time * 0.03) * size.width * 0.1
                let offsetY = sin(time * 0.025) * size.height * 0.1

                // Foreground layer 1 animation
                let rotation2 = Angle(radians: time * -0.02 + 0.5)
                let offsetX2 = cos(time * 0.04 + 1.5) * size.width * 0.2
                let offsetY2 = sin(time * 0.035 + 1.5) * size.height * 0.2

                // Foreground layer 2 animation
                let rotation3 = Angle(radians: time * 0.025 + 1.2)
                let offsetX3 = cos(time * 0.03 + 3.0) * size.width * 0.25
                let offsetY3 = sin(time * 0.045 + 3.0) * size.height * 0.25

                // Mesh control points for foreground layers
                let p1 = meshControlPoints(time: time, size: size, phase: 0)
                let p2 = meshControlPoints(time: time, size: size, phase: 2.5)

                ZStack {
                    // Background layer - no distortion for performance
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size.width * 2.5, height: size.height * 2.5)
                        .rotationEffect(rotation)
                        .offset(x: offsetX, y: offsetY)

                    // Foreground layer 1 with mesh distortion
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: size.width * 1.2, height: size.height * 1.2)
                        .distortionEffect(
                            Self.shaderLibrary.meshDistort(
                                .float2(size),
                                .float2(p1[0]), .float2(p1[1]), .float2(p1[2]), .float2(p1[3]),
                                .float2(p1[4]), .float2(p1[5]), .float2(p1[6]), .float2(p1[7]),
                                .float2(p1[8]), .float2(p1[9]), .float2(p1[10]), .float2(p1[11]),
                                .float2(p1[12]), .float2(p1[13]), .float2(p1[14]), .float2(p1[15])
                            ),
                            maxSampleOffset: CGSize(width: size.width * 0.4, height: size.height * 0.4)
                        )
                        .rotationEffect(rotation2)
                        .offset(x: offsetX2, y: offsetY2)

                    // Foreground layer 2 with mesh distortion
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: size.width * 1.0, height: size.height * 1.0)
                        .distortionEffect(
                            Self.shaderLibrary.meshDistort(
                                .float2(size),
                                .float2(p2[0]), .float2(p2[1]), .float2(p2[2]), .float2(p2[3]),
                                .float2(p2[4]), .float2(p2[5]), .float2(p2[6]), .float2(p2[7]),
                                .float2(p2[8]), .float2(p2[9]), .float2(p2[10]), .float2(p2[11]),
                                .float2(p2[12]), .float2(p2[13]), .float2(p2[14]), .float2(p2[15])
                            ),
                            maxSampleOffset: CGSize(width: size.width * 0.4, height: size.height * 0.4)
                        )
                        .rotationEffect(rotation3)
                        .offset(x: offsetX3, y: offsetY3)
                }
                .frame(width: size.width, height: size.height)
                .clipped()
            }
        }
    }

    /// Generate 16 animated control point displacements for the mesh (4x4 grid)
    private func meshControlPoints(time: Double, size: CGSize, phase basePhase: Double) -> [CGPoint] {
        var points: [CGPoint] = []
        let amplitude = min(size.width, size.height) * 0.35

        for row in 0..<4 {
            for col in 0..<4 {
                let index = row * 4 + col
                let phase = Double(index) * 0.5 + basePhase

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
