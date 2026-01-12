import CoreMotion
import Metal
import MetalKit
import SwiftUI
import UIKit

public struct MetalBlobGradient: View {
    private let blobColors: [Color]
    private let highlightColors: [Color]
    private let backgroundColor: Color
    private let blur: CGFloat
    private let dithering: CGFloat
    private let particleSize: CGFloat
    private let fill: CGFloat
    private let blobSize: BlobSize
    private let speed: CGFloat

    public init(
        _ baseColor: Color,
        highlights: [Color] = [],
        background: Color = .black,
        blur: CGFloat = 0.75,
        dithering: CGFloat = 0.4,
        particleSize: CGFloat = 80,
        fill: CGFloat = 0.5,
        blobSize: BlobSize = .medium,
        speed: CGFloat = 1.5
    ) {
        self.blobColors = Self.generateBlobColors(baseColor: baseColor)
        self.highlightColors = highlights
        self.backgroundColor = background
        self.blur = blur
        self.dithering = dithering
        self.particleSize = particleSize
        self.fill = max(0, min(1, fill))
        self.blobSize = blobSize
        self.speed = max(0, speed)
    }

    public var body: some View {
        MetalBlobGradientRepresentable(
            colors: blobColors,
            highlights: highlightColors,
            background: backgroundColor,
            blur: blur,
            dithering: dithering,
            particleSize: particleSize,
            fill: fill,
            blobSize: blobSize,
            speed: speed
        )
        .ignoresSafeArea()
    }

    private static func generateBlobColors(baseColor: Color) -> [Color] {
        let darker = baseColor.darkerVariant()
        let lighter = baseColor.lighterVariant()

        return [
            baseColor,
            baseColor.opacity(0.8),
            darker,
            darker.opacity(0.8),
            lighter,
            lighter.opacity(0.8),
            baseColor.mix(with: lighter, by: 0.5)
        ]
    }
}

extension Color {
    @MainActor
    public func metalBlobGradient(
        highlights: [Color] = [],
        background: Color = .black,
        blur: CGFloat = 0.75,
        dithering: CGFloat = 0.4,
        particleSize: CGFloat = 80,
        fill: CGFloat = 0.5,
        blobSize: BlobSize = .medium,
        speed: CGFloat = 1.5
    ) -> some View {
        MetalBlobGradient(
            self,
            highlights: highlights,
            background: background,
            blur: blur,
            dithering: dithering,
            particleSize: particleSize,
            fill: fill,
            blobSize: blobSize,
            speed: speed
        )
    }
}

private struct MetalBlobGradientRepresentable: UIViewRepresentable {
    let colors: [Color]
    let highlights: [Color]
    let background: Color
    let blur: CGFloat
    let dithering: CGFloat
    let particleSize: CGFloat
    let fill: CGFloat
    let blobSize: BlobSize
    let speed: CGFloat

    func makeUIView(context: Context) -> MetalBlobGradientView {
        context.coordinator.view
    }

    func updateUIView(_ view: MetalBlobGradientView, context: Context) {
        context.coordinator.update(colors: colors, highlights: highlights, background: background, blur: blur, dithering: dithering, particleSize: particleSize, fill: fill, blobSize: blobSize, speed: speed)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(colors: colors, highlights: highlights, background: background, blur: blur, dithering: dithering, particleSize: particleSize, fill: fill, blobSize: blobSize, speed: speed)
    }

    @MainActor
    class Coordinator {
        var colors: [Color]
        var highlights: [Color]
        var background: Color
        var blur: CGFloat
        var dithering: CGFloat
        var particleSize: CGFloat
        var fill: CGFloat
        var blobSize: BlobSize
        var speed: CGFloat
        let view: MetalBlobGradientView

        init(colors: [Color], highlights: [Color], background: Color, blur: CGFloat, dithering: CGFloat, particleSize: CGFloat, fill: CGFloat, blobSize: BlobSize, speed: CGFloat) {
            self.colors = colors
            self.highlights = highlights
            self.background = background
            self.blur = blur
            self.dithering = dithering
            self.particleSize = particleSize
            self.fill = fill
            self.blobSize = blobSize
            self.speed = speed
            self.view = MetalBlobGradientView(colors: colors, highlights: highlights, background: background, blur: blur, dithering: dithering, particleSize: particleSize, fill: fill, blobSize: blobSize, speed: speed)
        }

        func update(colors: [Color], highlights: [Color], background: Color, blur: CGFloat, dithering: CGFloat, particleSize: CGFloat, fill: CGFloat, blobSize: BlobSize, speed: CGFloat) {
            if colors != self.colors || highlights != self.highlights || fill != self.fill || blobSize != self.blobSize {
                let highlightsAdded = highlights.count > self.highlights.count
                self.colors = colors
                self.highlights = highlights
                self.fill = fill
                self.blobSize = blobSize
                view.fill = fill
                view.blobSize = blobSize

                if highlightsAdded {
                    crossfadeColors(colors, highlights: highlights)
                } else {
                    view.updateColors(colors, highlights: highlights)
                }
            }
            if background != self.background {
                self.background = background
                view.setBackground(background)
            }
            if blur != self.blur {
                self.blur = blur
                view.blur = blur
            }
            if dithering != self.dithering {
                self.dithering = dithering
                view.dithering = dithering
            }
            if particleSize != self.particleSize {
                self.particleSize = particleSize
                view.particleSize = particleSize
            }
            if speed != self.speed {
                self.speed = speed
                view.speed = speed
            }
        }

        private func crossfadeColors(_ colors: [Color], highlights: [Color]) {
            let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
            let snapshot = renderer.image { _ in
                view.drawHierarchy(in: view.bounds, afterScreenUpdates: false)
            }

            let snapshotView = UIImageView(image: snapshot)
            snapshotView.frame = view.bounds
            snapshotView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(snapshotView)

            view.updateColors(colors, highlights: highlights)

            UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseInOut) {
                snapshotView.alpha = 0
            } completion: { _ in
                snapshotView.removeFromSuperview()
            }
        }
    }
}

private struct BlobData {
    var basePosition: SIMD2<Float>
    var baseRadius: SIMD2<Float>
    var color: SIMD4<Float>
    var phaseX: Float
    var phaseY: Float
    var frequencyX: Float
    var frequencyY: Float
    var amplitudeX: Float
    var amplitudeY: Float
    var radiusPhaseX: Float
    var radiusPhaseY: Float
    var radiusFreqX: Float
    var radiusFreqY: Float
    var radiusAmplitude: Float
    var aspectRatioMultiplier: Float
    var opacityPhase: Float
    var opacityFrequency: Float
    var isHighlight: Int32
}

private struct Uniforms {
    var time: Float
    var motionOffset: SIMD2<Float>
    var blobCount: Int32
    var bufferRatioX: Float
    var bufferRatioY: Float
    var viewRatio: Float
    var bgR: Float
    var bgG: Float
    var bgB: Float
    var padding: Float = 0
}


private struct BlurUniforms {
    var texelSize: SIMD2<Float>
    var horizontal: Int32
    var padding: Float = 0
}

private struct BlitUniforms {
    var time: Float
    var ditheringAmount: Float
    var particleSize: Float
    var padding: Float = 0
}

private class MetalBlobGradientView: UIView {
    private var metalView: MTKView!
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var blobPipelineState: MTLRenderPipelineState!
    private var blurPipelineState: MTLRenderPipelineState!
    private var blitPipelineState: MTLRenderPipelineState!
    private var blobBuffer: MTLBuffer!

    private var lowResTexture1: MTLTexture?
    private var lowResTexture2: MTLTexture?
    private var lowResSize: CGSize = .zero
    private var currentDrawableSize: CGSize = .zero

    private let motionManager = CMMotionManager()
    private var startTime: CFTimeInterval = 0
    private var currentOffset: CGPoint = .zero
    private let smoothing: CGFloat = 0.12

    private var blobs: [BlobData] = []
    private var bufferRatioX: Float = 0.15
    private var bufferRatioY: Float = 0.15
    private var bgColor: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    var blur: CGFloat = 0.75
    var dithering: CGFloat = 0.4
    var particleSize: CGFloat = 80
    var fill: CGFloat = 0.5
    var blobSize: BlobSize = .medium
    var speed: CGFloat = 1.5

    init(colors: [Color] = [], highlights: [Color] = [], background: Color = .black, blur: CGFloat = 0.75, dithering: CGFloat = 0.4, particleSize: CGFloat = 80, fill: CGFloat = 0.5, blobSize: BlobSize = .medium, speed: CGFloat = 1.5) {
        self.blur = blur
        self.dithering = dithering
        self.particleSize = particleSize
        self.fill = fill
        self.blobSize = blobSize
        self.speed = speed
        super.init(frame: .zero)

        setupMetal()
        setBackground(background)
        updateColors(colors, highlights: highlights)
        setupMotion()

        startTime = CACurrentMediaTime()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setBackground(_ color: Color) {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        bgColor = SIMD3<Float>(Float(r), Float(g), Float(b))
        metalView?.clearColor = MTLClearColor(red: Double(r), green: Double(g), blue: Double(b), alpha: 1)
    }

    private func setupMetal() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            return
        }
        self.device = device
        self.commandQueue = device.makeCommandQueue()

        metalView = MTKView(frame: .zero, device: device)
        metalView.delegate = self
        metalView.framebufferOnly = false
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.preferredFramesPerSecond = 60
        metalView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(metalView)

        setupPipelines()
    }

    private func setupPipelines() {
        let shaderSource = """
        #include <metal_stdlib>
        using namespace metal;

        struct VertexOut {
            float4 position [[position]];
            float2 uv;
        };

        struct BlobData {
            float2 basePosition;
            float2 baseRadius;
            float4 color;
            float phaseX;
            float phaseY;
            float frequencyX;
            float frequencyY;
            float amplitudeX;
            float amplitudeY;
            float radiusPhaseX;
            float radiusPhaseY;
            float radiusFreqX;
            float radiusFreqY;
            float radiusAmplitude;
            float aspectRatioMultiplier;
            float opacityPhase;
            float opacityFrequency;
            int isHighlight;
        };

        struct Uniforms {
            float time;
            float2 motionOffset;
            int blobCount;
            float bufferRatioX;
            float bufferRatioY;
            float viewRatio;
            float bgR;
            float bgG;
            float bgB;
            float padding;
        };

        vertex VertexOut vertexShader(uint vertexID [[vertex_id]]) {
            float2 positions[6] = {
                float2(-1, -1), float2(1, -1), float2(-1, 1),
                float2(-1, 1), float2(1, -1), float2(1, 1)
            };

            float2 uvs[6] = {
                float2(0, 1), float2(1, 1), float2(0, 0),
                float2(0, 0), float2(1, 1), float2(1, 0)
            };

            VertexOut out;
            out.position = float4(positions[vertexID], 0, 1);
            out.uv = uvs[vertexID];
            return out;
        }

        fragment float4 blobFragmentShader(
            VertexOut in [[stage_in]],
            constant BlobData* blobs [[buffer(0)]],
            constant Uniforms& uniforms [[buffer(1)]]
        ) {
            float2 expandedUV = float2(
                uniforms.bufferRatioX + in.uv.x * (1.0 - 2.0 * uniforms.bufferRatioX),
                uniforms.bufferRatioY + in.uv.y * (1.0 - 2.0 * uniforms.bufferRatioY)
            );

            float3 baseResult = float3(uniforms.bgR, uniforms.bgG, uniforms.bgB);
            float3 highlightResult = float3(0);
            float highlightAlpha = 0;

            float safeRatio = max(uniforms.viewRatio, 1.0);

            for (int i = 0; i < uniforms.blobCount; i++) {
                BlobData blob = blobs[i];

                float animOffsetX = sin(uniforms.time * blob.frequencyX + blob.phaseX) * blob.amplitudeX;
                float animOffsetY = cos(uniforms.time * blob.frequencyY + blob.phaseY) * blob.amplitudeY;

                float2 position = blob.basePosition + float2(animOffsetX, animOffsetY) + uniforms.motionOffset;

                float scaleX = 1.0 + sin(uniforms.time * blob.radiusFreqX + blob.radiusPhaseX) * blob.radiusAmplitude;
                float scaleY = 1.0 + cos(uniforms.time * blob.radiusFreqY + blob.radiusPhaseY) * blob.radiusAmplitude;

                float2 radius = float2(
                    blob.baseRadius.x * scaleX,
                    blob.baseRadius.y * scaleY * safeRatio * blob.aspectRatioMultiplier
                );

                float2 diff = expandedUV - position;
                diff.x /= max(radius.x, 0.001);
                diff.y /= max(radius.y, 0.001);
                float dist = length(diff);

                float blobOpacity = 0.75 + 0.25 * sin(uniforms.time * blob.opacityFrequency + blob.opacityPhase);

                float alpha = 0;
                if (dist < 0.9) {
                    alpha = blob.color.a * blobOpacity;
                } else if (dist < 1.0) {
                    alpha = blob.color.a * blobOpacity * (1.0 - (dist - 0.9) / 0.1);
                }

                if (blob.isHighlight == 1) {
                    highlightResult = highlightResult * (1.0 - alpha) + blob.color.rgb * alpha;
                    highlightAlpha = highlightAlpha * (1.0 - alpha) + alpha;
                } else {
                    baseResult = baseResult * (1.0 - alpha) + blob.color.rgb * alpha;
                }
            }

            float3 finalResult = baseResult;
            if (highlightAlpha > 0) {
                float3 overlay = float3(
                    baseResult.r < 0.5 ? 2.0 * baseResult.r * highlightResult.r : 1.0 - 2.0 * (1.0 - baseResult.r) * (1.0 - highlightResult.r),
                    baseResult.g < 0.5 ? 2.0 * baseResult.g * highlightResult.g : 1.0 - 2.0 * (1.0 - baseResult.g) * (1.0 - highlightResult.g),
                    baseResult.b < 0.5 ? 2.0 * baseResult.b * highlightResult.b : 1.0 - 2.0 * (1.0 - baseResult.b) * (1.0 - highlightResult.b)
                );
                finalResult = mix(finalResult, overlay, highlightAlpha);
            }

            return float4(finalResult, 1.0);
        }

        struct BlurUniforms {
            float2 texelSize;
            int horizontal;
            float padding;
        };

        fragment float4 blurFragmentShader(
            VertexOut in [[stage_in]],
            texture2d<float> inputTexture [[texture(0)]],
            constant BlurUniforms& uniforms [[buffer(0)]]
        ) {
            constexpr sampler textureSampler(mag_filter::linear, min_filter::linear, address::clamp_to_edge);

            float offsets[5] = { 0.0, 1.4, 3.3, 5.2, 7.1 };
            float weights[5] = { 0.17, 0.16, 0.13, 0.085, 0.043 };

            float2 direction = uniforms.horizontal == 1
                ? float2(uniforms.texelSize.x, 0)
                : float2(0, uniforms.texelSize.y);

            float3 result = inputTexture.sample(textureSampler, in.uv).rgb * weights[0];

            for (int i = 1; i < 5; i++) {
                float offset = offsets[i];
                result += inputTexture.sample(textureSampler, in.uv + direction * offset).rgb * weights[i];
                result += inputTexture.sample(textureSampler, in.uv - direction * offset).rgb * weights[i];
            }

            return float4(result, 1.0);
        }

        struct BlitUniforms {
            float time;
            float ditheringAmount;
            float particleSize;
            float padding;
        };

        float random(float2 st) {
            return fract(sin(dot(st, float2(12.9898, 78.233))) * 43758.5453);
        }

        fragment float4 blitFragmentShader(
            VertexOut in [[stage_in]],
            texture2d<float> inputTexture [[texture(0)]],
            constant BlitUniforms& uniforms [[buffer(0)]]
        ) {
            constexpr sampler textureSampler(mag_filter::linear, min_filter::linear, address::clamp_to_edge);

            float4 color = inputTexture.sample(textureSampler, in.uv);

            float2 noiseCoord = in.uv * uniforms.particleSize;
            float noise = random(noiseCoord) - 0.5;

            float spread = 0.08;
            float3 colorL = inputTexture.sample(textureSampler, in.uv - float2(spread, 0)).rgb;
            float3 colorR = inputTexture.sample(textureSampler, in.uv + float2(spread, 0)).rgb;
            float3 colorU = inputTexture.sample(textureSampler, in.uv - float2(0, spread)).rgb;
            float3 colorD = inputTexture.sample(textureSampler, in.uv + float2(0, spread)).rgb;

            float gradX = length(colorR - colorL);
            float gradY = length(colorD - colorU);
            float edgeFactor = saturate((gradX + gradY) * 2.0);

            float dither = noise * uniforms.ditheringAmount * edgeFactor;
            color.rgb += dither;

            return color;
        }
        """

        do {
            let library = try device.makeLibrary(source: shaderSource, options: nil)

            let blobDescriptor = MTLRenderPipelineDescriptor()
            blobDescriptor.vertexFunction = library.makeFunction(name: "vertexShader")
            blobDescriptor.fragmentFunction = library.makeFunction(name: "blobFragmentShader")
            blobDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            blobPipelineState = try device.makeRenderPipelineState(descriptor: blobDescriptor)

            let blurDescriptor = MTLRenderPipelineDescriptor()
            blurDescriptor.vertexFunction = library.makeFunction(name: "vertexShader")
            blurDescriptor.fragmentFunction = library.makeFunction(name: "blurFragmentShader")
            blurDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            blurPipelineState = try device.makeRenderPipelineState(descriptor: blurDescriptor)

            let blitDescriptor = MTLRenderPipelineDescriptor()
            blitDescriptor.vertexFunction = library.makeFunction(name: "vertexShader")
            blitDescriptor.fragmentFunction = library.makeFunction(name: "blitFragmentShader")
            blitDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            blitPipelineState = try device.makeRenderPipelineState(descriptor: blitDescriptor)
        } catch {
            print("Failed to create pipeline: \(error)")
        }
    }

    private func createTextures(drawableSize: CGSize) {
        guard drawableSize.width > 0 && drawableSize.height > 0 else { return }
        guard bounds.width > 0 && bounds.height > 0 else { return }

        let blurAmount = blur > 0.01 ? pow(Float(min(bounds.width, bounds.height)), Float(blur)) : 0
        let scale = blurAmount > 1 ? max(8, Int(blurAmount / 4)) : 1
        let lowResWidth = max(1, Int(drawableSize.width) / scale)
        let lowResHeight = max(1, Int(drawableSize.height) / scale)

        let lowResDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: lowResWidth,
            height: lowResHeight,
            mipmapped: false
        )
        lowResDescriptor.usage = [.renderTarget, .shaderRead]
        lowResDescriptor.storageMode = .private

        lowResTexture1 = device.makeTexture(descriptor: lowResDescriptor)
        lowResTexture2 = device.makeTexture(descriptor: lowResDescriptor)
        lowResSize = CGSize(width: lowResWidth, height: lowResHeight)

        currentDrawableSize = drawableSize
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

        let sensitivity: CGFloat = 0.68
        let maxOffset: CGFloat = 0.45
        let targetX = max(-maxOffset, min(maxOffset, CGFloat(roll) * sensitivity))
        let targetY = max(-maxOffset, min(maxOffset, CGFloat(pitch) * sensitivity))

        currentOffset = CGPoint(
            x: currentOffset.x + (targetX - currentOffset.x) * smoothing,
            y: currentOffset.y + (targetY - currentOffset.y) * smoothing
        )
    }

    override func removeFromSuperview() {
        super.removeFromSuperview()
        motionManager.stopDeviceMotionUpdates()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        metalView.frame = bounds

        let buffer: CGFloat = 100
        if bounds.width > 0 && bounds.height > 0 {
            let expandedWidth = bounds.width + buffer * 2
            let expandedHeight = bounds.height + buffer * 2
            bufferRatioX = Float(buffer / expandedWidth)
            bufferRatioY = Float(buffer / expandedHeight)
        }
    }

    func updateColors(_ colors: [Color], highlights: [Color]) {
        let radiusRange = blobSize.radiusRange
        let minRadius = Float(radiusRange.min)
        let maxRadius = Float(max(radiusRange.min + 0.01, radiusRange.max))
        let blobCount = max(5, Int(CGFloat(blobSize.baseBlobCount) * fill))

        let baseColors = (0..<blobCount).map { colors[$0 % colors.count] }
        let highlightColors = highlights.isEmpty ? [] : (0..<max(3, blobCount / 3)).map { highlights[$0 % highlights.count] }

        blobs = baseColors.map { color in
            createBlobData(color: color, minRadius: minRadius, maxRadius: maxRadius, isHighlight: false)
        } + highlightColors.map { color in
            createBlobData(color: color, minRadius: minRadius, maxRadius: maxRadius, isHighlight: true)
        }

        blobBuffer = device.makeBuffer(
            bytes: &blobs,
            length: MemoryLayout<BlobData>.stride * max(blobs.count, 1),
            options: .storageModeShared
        )
    }

    private func createBlobData(color: Color, minRadius: Float, maxRadius: Float, isHighlight: Bool) -> BlobData {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        return BlobData(
            basePosition: SIMD2<Float>(
                Float.random(in: 0.0...1.0),
                Float.random(in: 0.0...1.0)
            ),
            baseRadius: SIMD2<Float>(
                Float.random(in: minRadius...maxRadius),
                Float.random(in: minRadius...maxRadius)
            ),
            color: SIMD4<Float>(Float(r), Float(g), Float(b), Float(a)),
            phaseX: Float.random(in: 0...(.pi * 2)),
            phaseY: Float.random(in: 0...(.pi * 2)),
            frequencyX: Float.random(in: 0.24...0.45),
            frequencyY: Float.random(in: 0.24...0.45),
            amplitudeX: Float.random(in: 0.2...0.35),
            amplitudeY: Float.random(in: 0.2...0.35),
            radiusPhaseX: Float.random(in: 0...(.pi * 2)),
            radiusPhaseY: Float.random(in: 0...(.pi * 2)),
            radiusFreqX: Float.random(in: 0.15...0.36),
            radiusFreqY: Float.random(in: 0.15...0.36),
            radiusAmplitude: Float.random(in: 0.3...0.5),
            aspectRatioMultiplier: Float.random(in: 0.6...1.4),
            opacityPhase: Float.random(in: 0...(.pi * 2)),
            opacityFrequency: Float.random(in: 0.2...0.4),
            isHighlight: isHighlight ? 1 : 0
        )
    }
}

extension MetalBlobGradientView: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        createTextures(drawableSize: size)
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              blobs.count > 0,
              let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }

        let drawableSize = view.drawableSize
        if currentDrawableSize != drawableSize || lowResTexture1 == nil {
            createTextures(drawableSize: drawableSize)
        }

        let time = Float((CACurrentMediaTime() - startTime) * speed)
        let viewRatio = bounds.width > 0 && bounds.height > 0 ? Float(bounds.width / bounds.height) : 1.0
        var blobUniforms = Uniforms(
            time: time,
            motionOffset: SIMD2<Float>(Float(currentOffset.x), Float(currentOffset.y)),
            blobCount: Int32(blobs.count),
            bufferRatioX: bufferRatioX,
            bufferRatioY: bufferRatioY,
            viewRatio: viewRatio,
            bgR: bgColor.x,
            bgG: bgColor.y,
            bgB: bgColor.z
        )

        let useBlur = blur > 0.01 && lowResTexture1 != nil && lowResTexture2 != nil
        var blitUniforms = BlitUniforms(time: time, ditheringAmount: Float(dithering), particleSize: Float(particleSize))

        if useBlur {
            guard let texture1 = lowResTexture1,
                  let texture2 = lowResTexture2 else {
                return
            }

            let blobPassDescriptor = MTLRenderPassDescriptor()
            blobPassDescriptor.colorAttachments[0].texture = texture1
            blobPassDescriptor.colorAttachments[0].loadAction = .clear
            blobPassDescriptor.colorAttachments[0].storeAction = .store
            blobPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: Double(bgColor.x), green: Double(bgColor.y), blue: Double(bgColor.z), alpha: 1)

            if let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: blobPassDescriptor) {
                encoder.setRenderPipelineState(blobPipelineState)
                encoder.setFragmentBuffer(blobBuffer, offset: 0, index: 0)
                encoder.setFragmentBytes(&blobUniforms, length: MemoryLayout<Uniforms>.size, index: 1)
                encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
                encoder.endEncoding()
            }

            let texelSize = SIMD2<Float>(1.0 / Float(lowResSize.width), 1.0 / Float(lowResSize.height))
            let blurPasses = 4

            var sourceTexture = texture1
            var destTexture = texture2

            for _ in 0..<blurPasses {
                var horizontalUniforms = BlurUniforms(texelSize: texelSize, horizontal: 1)
                let hPassDescriptor = MTLRenderPassDescriptor()
                hPassDescriptor.colorAttachments[0].texture = destTexture
                hPassDescriptor.colorAttachments[0].loadAction = .dontCare
                hPassDescriptor.colorAttachments[0].storeAction = .store

                if let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: hPassDescriptor) {
                    encoder.setRenderPipelineState(blurPipelineState)
                    encoder.setFragmentTexture(sourceTexture, index: 0)
                    encoder.setFragmentBytes(&horizontalUniforms, length: MemoryLayout<BlurUniforms>.size, index: 0)
                    encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
                    encoder.endEncoding()
                }

                swap(&sourceTexture, &destTexture)

                var verticalUniforms = BlurUniforms(texelSize: texelSize, horizontal: 0)
                let vPassDescriptor = MTLRenderPassDescriptor()
                vPassDescriptor.colorAttachments[0].texture = destTexture
                vPassDescriptor.colorAttachments[0].loadAction = .dontCare
                vPassDescriptor.colorAttachments[0].storeAction = .store

                if let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: vPassDescriptor) {
                    encoder.setRenderPipelineState(blurPipelineState)
                    encoder.setFragmentTexture(sourceTexture, index: 0)
                    encoder.setFragmentBytes(&verticalUniforms, length: MemoryLayout<BlurUniforms>.size, index: 0)
                    encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
                    encoder.endEncoding()
                }

                swap(&sourceTexture, &destTexture)
            }

            let finalPassDescriptor = MTLRenderPassDescriptor()
            finalPassDescriptor.colorAttachments[0].texture = drawable.texture
            finalPassDescriptor.colorAttachments[0].loadAction = .dontCare
            finalPassDescriptor.colorAttachments[0].storeAction = .store

            if let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: finalPassDescriptor) {
                encoder.setRenderPipelineState(blitPipelineState)
                encoder.setFragmentTexture(sourceTexture, index: 0)
                encoder.setFragmentBytes(&blitUniforms, length: MemoryLayout<BlitUniforms>.size, index: 0)
                encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
                encoder.endEncoding()
            }
        } else {
            let blobPassDescriptor = MTLRenderPassDescriptor()
            blobPassDescriptor.colorAttachments[0].texture = drawable.texture
            blobPassDescriptor.colorAttachments[0].loadAction = .clear
            blobPassDescriptor.colorAttachments[0].storeAction = .store
            blobPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: Double(bgColor.x), green: Double(bgColor.y), blue: Double(bgColor.z), alpha: 1)

            if let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: blobPassDescriptor) {
                encoder.setRenderPipelineState(blobPipelineState)
                encoder.setFragmentBuffer(blobBuffer, offset: 0, index: 0)
                encoder.setFragmentBytes(&blobUniforms, length: MemoryLayout<Uniforms>.size, index: 1)
                encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
                encoder.endEncoding()
            }
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
