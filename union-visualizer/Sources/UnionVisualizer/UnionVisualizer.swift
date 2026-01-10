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

                // 9 mesh control points with animated displacement
                let meshPoints = meshControlPoints(time: time, size: size)

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
                                .float2(meshPoints[0]), .float2(meshPoints[1]), .float2(meshPoints[2]),
                                .float2(meshPoints[3]), .float2(meshPoints[4]), .float2(meshPoints[5]),
                                .float2(meshPoints[6]), .float2(meshPoints[7]), .float2(meshPoints[8])
                            ),
                            maxSampleOffset: CGSize(width: size.width * 0.3, height: size.height * 0.3)
                        )
                        .rotationEffect(rotation2)
                        .offset(x: offsetX2, y: offsetY2)
                }
                .frame(width: size.width, height: size.height)
                .clipped()
            }
        }
    }

    /// Generate 9 animated control point displacements for the mesh
    private func meshControlPoints(time: Double, size: CGSize) -> [CGPoint] {
        var points: [CGPoint] = []
        let amplitude = min(size.width, size.height) * 0.35

        for row in 0..<3 {
            for col in 0..<3 {
                let index = row * 3 + col
                let phase = Double(index) * 0.7

                // Each point moves in a unique pattern
                let dx = cos(time * 0.05 + phase) * amplitude * (col == 1 ? 1.5 : 1.0)
                let dy = sin(time * 0.04 + phase * 1.3) * amplitude * (row == 1 ? 1.5 : 1.0)

                points.append(CGPoint(x: dx, y: dy))
            }
        }

        return points
    }
}
