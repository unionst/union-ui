import CoreMotion
import QuartzCore
import SwiftUI
import UIKit

public struct BlobGradient: View {
    private let blobColors: [Color]
    private let blur: CGFloat
    private let blurAmount: CGFloat

    @State private var blurValue: CGFloat = 0.0

    public init(
        primary: Color,
        secondary: Color,
        blur: CGFloat = 0.75,
        blurAmount: CGFloat = 1.0
    ) {
        self.blobColors = Self.generateBlobColors(primary: primary, secondary: secondary)
        self.blur = blur
        self.blurAmount = blurAmount
    }

    public var body: some View {
        BlobGradientRepresentable(
            colors: blobColors,
            blurValue: $blurValue
        )
        .blur(radius: pow(blurValue, blur) * blurAmount)
        .ignoresSafeArea()
    }

    private static func generateBlobColors(primary: Color, secondary: Color) -> [Color] {
        var colors: [Color] = []

        colors.append(primary)
        colors.append(primary.opacity(0.8))
        colors.append(secondary)
        colors.append(secondary.opacity(0.8))
        colors.append(primary.mix(with: secondary, by: 0.5))
        colors.append(primary.lighter(by: 0.2))
        colors.append(secondary.darker(by: 0.15))

        return colors
    }
}

extension Color {
    @MainActor
    public func blobGradient(
        secondary: Color? = nil,
        blur: CGFloat = 0.75,
        blurAmount: CGFloat = 1.0
    ) -> some View {
        BlobGradient(
            primary: self,
            secondary: secondary ?? self.lighter(by: 0.3),
            blur: blur,
            blurAmount: blurAmount
        )
    }

    func mix(with other: Color, by amount: CGFloat) -> Color {
        let uiSelf = UIColor(self)
        let uiOther = UIColor(other)

        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

        uiSelf.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        uiOther.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        return Color(
            red: r1 + (r2 - r1) * amount,
            green: g1 + (g2 - g1) * amount,
            blue: b1 + (b2 - b1) * amount,
            opacity: a1 + (a2 - a1) * amount
        )
    }

    func lighter(by amount: CGFloat) -> Color {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(hue: h, saturation: max(0, s - amount * 0.3), brightness: min(1, b + amount), opacity: a)
    }

    func darker(by amount: CGFloat) -> Color {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(hue: h, saturation: s, brightness: max(0, b - amount), opacity: a)
    }
}

private struct BlobGradientRepresentable: UIViewRepresentable {
    let colors: [Color]
    @Binding var blurValue: CGFloat

    func makeUIView(context: Context) -> BlobGradientView {
        context.coordinator.view
    }

    func updateUIView(_ view: BlobGradientView, context: Context) {
        context.coordinator.update(colors: colors)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(colors: colors, blurValue: $blurValue)
    }

    @MainActor
    class Coordinator: BlobGradientViewDelegate {
        var colors: [Color]
        var blurValue: Binding<CGFloat>
        let view: BlobGradientView

        init(colors: [Color], blurValue: Binding<CGFloat>) {
            self.colors = colors
            self.blurValue = blurValue
            self.view = BlobGradientView(colors: colors)
            self.view.delegate = self
        }

        func update(colors: [Color]) {
            guard colors != self.colors else { return }
            self.colors = colors
            view.updateColors(colors)
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
    let blobLayer = BlobContainerLayer()
    private let motionManager = CMMotionManager()
    private var displayLink: CADisplayLink?
    private var startTime: CFTimeInterval = 0
    private var currentOffset: CGPoint = .zero
    private let smoothing: CGFloat = 0.12

    weak var delegate: BlobGradientViewDelegate?

    init(colors: [Color] = []) {
        super.init(frame: .zero)

        clipsToBounds = false
        layer.addSublayer(blobLayer)

        updateColors(colors)

        setupMotion()
        setupDisplayLink()
    }

    private func setupDisplayLink() {
        startTime = CACurrentMediaTime()
        displayLink = CADisplayLink(target: self, selector: #selector(updateAnimation))
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60)
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc private func updateAnimation() {
        let time = CACurrentMediaTime() - startTime

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        for sublayer in blobLayer.sublayers ?? [] {
            if let blob = sublayer as? BlobLayer {
                blob.updateAnimation(time: time, motionOffset: currentOffset)
            }
        }

        CATransaction.commit()
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

        let sensitivity: CGFloat = 0.30
        let maxOffset: CGFloat = 0.20
        let targetX = max(-maxOffset, min(maxOffset, CGFloat(roll) * sensitivity))
        let targetY = max(-maxOffset, min(maxOffset, CGFloat(pitch) * sensitivity))

        currentOffset = CGPoint(
            x: currentOffset.x + (targetX - currentOffset.x) * smoothing,
            y: currentOffset.y + (targetY - currentOffset.y) * smoothing
        )
    }

    override func removeFromSuperview() {
        super.removeFromSuperview()
        displayLink?.invalidate()
        displayLink = nil
        motionManager.stopDeviceMotionUpdates()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let buffer: CGFloat = 100
        let expandedFrame = bounds.insetBy(dx: -buffer, dy: -buffer)

        blobLayer.frame = expandedFrame

        for sublayer in blobLayer.sublayers ?? [] {
            sublayer.frame = CGRect(origin: .zero, size: expandedFrame.size)
        }

        CATransaction.commit()

        delegate?.didUpdateBlur(min(bounds.width, bounds.height))
    }

    func updateColors(_ colors: [Color]) {
        let existingCount = blobLayer.sublayers?.count ?? 0
        let removeCount = existingCount - colors.count

        if removeCount > 0 {
            blobLayer.sublayers?.suffix(removeCount).forEach { $0.removeFromSuperlayer() }
        }

        for (index, color) in colors.enumerated() {
            if index < existingCount, let blob = blobLayer.sublayers?[index] as? BlobLayer {
                blob.setColor(color)
            } else {
                let blob = BlobLayer(color: color)
                blob.frame = blobLayer.bounds
                blobLayer.addSublayer(blob)
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
    private var baseRadius: CGPoint = .zero

    private let phaseX: CGFloat = .random(in: 0...(.pi * 2))
    private let phaseY: CGFloat = .random(in: 0...(.pi * 2))
    private let frequencyX: CGFloat = .random(in: 0.24...0.45)
    private let frequencyY: CGFloat = .random(in: 0.24...0.45)
    private let amplitudeX: CGFloat = .random(in: 0.2...0.35)
    private let amplitudeY: CGFloat = .random(in: 0.2...0.35)

    private let radiusPhaseX: CGFloat = .random(in: 0...(.pi * 2))
    private let radiusPhaseY: CGFloat = .random(in: 0...(.pi * 2))
    private let radiusFreqX: CGFloat = .random(in: 0.15...0.36)
    private let radiusFreqY: CGFloat = .random(in: 0.15...0.36)
    private let radiusAmplitude: CGFloat = .random(in: 0.3...0.5)

    init(color: Color) {
        super.init()

        type = .radial
        masksToBounds = false

        basePosition = CGPoint(
            x: CGFloat.random(in: 0.2...0.8),
            y: CGFloat.random(in: 0.2...0.8)
        )
        baseRadius = CGPoint(
            x: CGFloat.random(in: 0.15...0.3),
            y: CGFloat.random(in: 0.15...0.3)
        )

        startPoint = basePosition
        endPoint = basePosition.offset(by: baseRadius)

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

    func updateAnimation(time: CFTimeInterval, motionOffset: CGPoint) {
        let animOffsetX = sin(time * frequencyX + phaseX) * amplitudeX
        let animOffsetY = cos(time * frequencyY + phaseY) * amplitudeY

        let newPosition = CGPoint(
            x: basePosition.x + CGFloat(animOffsetX) + motionOffset.x,
            y: basePosition.y + CGFloat(animOffsetY) + motionOffset.y
        )

        let scaleX = 1.0 + sin(time * radiusFreqX + radiusPhaseX) * radiusAmplitude
        let scaleY = 1.0 + cos(time * radiusFreqY + radiusPhaseY) * radiusAmplitude

        let animatedRadius = CGPoint(
            x: baseRadius.x * scaleX,
            y: baseRadius.y * scaleY
        )

        startPoint = newPosition
        endPoint = newPosition.offset(by: animatedRadius)
    }
}

private extension CGPoint {
    func offset(by point: CGPoint) -> CGPoint {
        CGPoint(x: x + point.x, y: y + point.y)
    }
}
