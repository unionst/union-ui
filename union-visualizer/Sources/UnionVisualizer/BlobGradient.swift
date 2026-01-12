import CoreMotion
import QuartzCore
import SwiftUI
import UIKit

public struct BlobGradient: View {
    private let colors: [Color]
    private let highlights: [Color]
    private let blur: CGFloat

    @State private var blurValue: CGFloat = 0.0

    public init(
        colors: [Color],
        highlights: [Color] = [],
        blur: CGFloat = 0.75
    ) {
        self.colors = colors
        self.highlights = highlights
        self.blur = blur
    }

    public var body: some View {
        BlobGradientRepresentable(
            colors: colors,
            highlights: highlights,
            blurValue: $blurValue
        )
        .blur(radius: pow(blurValue, blur))
        .ignoresSafeArea()
    }
}

extension Color {
    @MainActor
    public func blobGradient(
        highlights: [Color] = [],
        blur: CGFloat = 0.75
    ) -> some View {
        BlobGradient(
            colors: [self],
            highlights: highlights,
            blur: blur
        )
    }
}

private struct BlobGradientRepresentable: UIViewRepresentable {
    let colors: [Color]
    let highlights: [Color]
    @Binding var blurValue: CGFloat

    func makeUIView(context: Context) -> BlobGradientView {
        context.coordinator.view
    }

    func updateUIView(_ view: BlobGradientView, context: Context) {
        context.coordinator.update(colors: colors, highlights: highlights)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(colors: colors, highlights: highlights, blurValue: $blurValue)
    }

    @MainActor
    class Coordinator: BlobGradientViewDelegate {
        var colors: [Color]
        var highlights: [Color]
        var blurValue: Binding<CGFloat>
        let view: BlobGradientView

        init(colors: [Color], highlights: [Color], blurValue: Binding<CGFloat>) {
            self.colors = colors
            self.highlights = highlights
            self.blurValue = blurValue
            self.view = BlobGradientView(colors: colors, highlights: highlights)
            self.view.delegate = self
        }

        func update(colors: [Color], highlights: [Color]) {
            guard colors != self.colors || highlights != self.highlights else { return }
            self.colors = colors
            self.highlights = highlights
            view.updateColors(colors, layer: view.baseLayer)
            view.updateColors(highlights, layer: view.highlightLayer)
        }

        nonisolated func didUpdateBlur(_ value: CGFloat) {
            Task { @MainActor in
                blurValue.wrappedValue = value
            }
        }
    }
}

private protocol BlobGradientViewDelegate: AnyObject {
    func didUpdateBlur(_ value: CGFloat)
}

private class BlobGradientView: UIView {
    let baseLayer = BlobContainerLayer()
    let highlightLayer = BlobContainerLayer()
    private let motionManager = CMMotionManager()
    private var currentOffset: CGPoint = .zero
    private var velocity: CGPoint = .zero
    private let smoothing: CGFloat = 0.04
    private let inertia: CGFloat = 0.96
    private let velocityScale: CGFloat = 0.8

    weak var delegate: BlobGradientViewDelegate?

    init(colors: [Color] = [], highlights: [Color] = []) {
        super.init(frame: .zero)

        clipsToBounds = false
        highlightLayer.compositingFilter = "overlayBlendMode"

        layer.addSublayer(baseLayer)
        layer.addSublayer(highlightLayer)

        updateColors(colors, layer: baseLayer)
        updateColors(highlights, layer: highlightLayer)

        setupMotion()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupMotion() {
        guard motionManager.isDeviceMotionAvailable else { return }

        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.applyMotion(pitch: motion.attitude.pitch, roll: motion.attitude.roll)
        }
    }

    private func applyMotion(pitch: Double, roll: Double) {
        guard bounds.width > 0 else { return }

        let sensitivity: CGFloat = 0.35
        let targetX = CGFloat(roll) * sensitivity
        let targetY = CGFloat(pitch) * sensitivity

        let previousOffset = currentOffset

        let smoothedX = currentOffset.x + (targetX - currentOffset.x) * smoothing
        let smoothedY = currentOffset.y + (targetY - currentOffset.y) * smoothing

        velocity = CGPoint(
            x: (velocity.x + (smoothedX - previousOffset.x) * velocityScale) * inertia,
            y: (velocity.y + (smoothedY - previousOffset.y) * velocityScale) * inertia
        )

        currentOffset = CGPoint(
            x: smoothedX + velocity.x,
            y: smoothedY + velocity.y
        )

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        for sublayer in (baseLayer.sublayers ?? []) + (highlightLayer.sublayers ?? []) {
            if let blob = sublayer as? BlobLayer {
                blob.applyMotionOffset(currentOffset)
            }
        }

        CATransaction.commit()
    }

    override func removeFromSuperview() {
        super.removeFromSuperview()
        motionManager.stopDeviceMotionUpdates()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let buffer: CGFloat = 100
        let expandedFrame = bounds.insetBy(dx: -buffer, dy: -buffer)

        baseLayer.frame = expandedFrame
        highlightLayer.frame = expandedFrame

        for sublayer in (baseLayer.sublayers ?? []) + (highlightLayer.sublayers ?? []) {
            sublayer.frame = CGRect(origin: .zero, size: expandedFrame.size)
        }

        CATransaction.commit()

        delegate?.didUpdateBlur(min(bounds.width, bounds.height))
    }

    func updateColors(_ colors: [Color], layer: CALayer) {
        let existingCount = layer.sublayers?.count ?? 0
        let removeCount = existingCount - colors.count

        if removeCount > 0 {
            layer.sublayers?.suffix(removeCount).forEach { $0.removeFromSuperlayer() }
        }

        for (index, color) in colors.enumerated() {
            if index < existingCount, let blob = layer.sublayers?[index] as? BlobLayer {
                blob.setColor(color)
            } else {
                let blob = BlobLayer(color: color)
                blob.frame = layer.bounds
                layer.addSublayer(blob)
            }
        }
    }
}

private class BlobContainerLayer: CALayer {
    override init() {
        super.init()
        sublayers = []
        masksToBounds = false
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSublayers() {
        super.layoutSublayers()
        sublayers?.forEach { $0.frame = bounds }
    }
}

private class BlobLayer: CAGradientLayer {
    private var basePosition: CGPoint = .zero
    private var radius: CGPoint = .zero

    init(color: Color) {
        super.init()

        type = .radial
        masksToBounds = false

        basePosition = CGPoint(
            x: CGFloat.random(in: 0.2...0.8),
            y: CGFloat.random(in: 0.2...0.8)
        )
        radius = CGPoint(
            x: CGFloat.random(in: 0.3...0.6),
            y: CGFloat.random(in: 0.3...0.6)
        )

        startPoint = basePosition
        endPoint = basePosition.offset(by: radius)

        setColor(color)
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setColor(_ color: Color) {
        let uiColor = UIColor(color)
        colors = [
            uiColor.cgColor,
            uiColor.cgColor,
            UIColor(color.opacity(0)).cgColor
        ]
        locations = [0.0, 0.9, 1.0]
    }

    func applyMotionOffset(_ offset: CGPoint) {
        let newPosition = CGPoint(
            x: basePosition.x + offset.x,
            y: basePosition.y + offset.y
        )
        startPoint = newPosition
        endPoint = newPosition.offset(by: radius)
    }
}

private extension CGPoint {
    func offset(by point: CGPoint) -> CGPoint {
        CGPoint(x: x + point.x, y: y + point.y)
    }
}
