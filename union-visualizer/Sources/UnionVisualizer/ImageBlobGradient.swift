import SwiftUI
import UIKit

public struct ImageBlobGradient: View {
    private let primaryColor: Color
    private let secondaryColor: Color?
    private let imageURL: URL?
    private let image: UIImage?
    private let preExtractedColors: [Color]
    private let blur: CGFloat
    private let dithering: CGFloat
    private let particleSize: CGFloat
    private let fill: CGFloat
    private let blobSize: BlobSize
    private let speed: CGFloat

    @State private var extractedColors: [Color] = []

    public init(
        _ primaryColor: Color,
        secondary: Color? = nil,
        imageURL: URL? = nil,
        preExtractedColors: [Color] = [],
        blur: CGFloat = 0.75,
        dithering: CGFloat = 0.4,
        particleSize: CGFloat = 80,
        fill: CGFloat = 0.5,
        blobSize: BlobSize = .medium,
        speed: CGFloat = 1.5
    ) {
        self.primaryColor = primaryColor
        self.secondaryColor = secondary
        self.imageURL = imageURL
        self.image = nil
        self.preExtractedColors = preExtractedColors
        self.blur = blur
        self.dithering = dithering
        self.particleSize = particleSize
        self.fill = fill
        self.blobSize = blobSize
        self.speed = speed
    }

    public init(
        _ primaryColor: Color,
        secondary: Color? = nil,
        image: UIImage?,
        preExtractedColors: [Color] = [],
        blur: CGFloat = 0.75,
        dithering: CGFloat = 0.4,
        particleSize: CGFloat = 80,
        fill: CGFloat = 0.5,
        blobSize: BlobSize = .medium,
        speed: CGFloat = 1.5
    ) {
        self.primaryColor = primaryColor
        self.secondaryColor = secondary
        self.imageURL = nil
        self.image = image
        self.preExtractedColors = preExtractedColors
        self.blur = blur
        self.dithering = dithering
        self.particleSize = particleSize
        self.fill = fill
        self.blobSize = blobSize
        self.speed = speed
    }

    public var body: some View {
        MetalBlobGradient(
            primaryColor,
            highlights: computedHighlights,
            background: primaryColor.darkerVariant().darkerVariant(),
            blur: blur,
            dithering: dithering,
            particleSize: particleSize,
            fill: fill,
            blobSize: blobSize,
            speed: speed
        )
        .task(id: imageURL) {
            await loadImageColors()
        }
        .task(id: image) {
            await extractFromProvidedImage()
        }
    }

    private var computedHighlights: [Color] {
        var highlights: [Color] = []

        if let secondary = secondaryColor {
            highlights.append(secondary)
            highlights.append(secondary.opacity(0.7))
        }

        if !preExtractedColors.isEmpty {
            highlights.append(contentsOf: preExtractedColors)
        } else {
            highlights.append(contentsOf: extractedColors)
        }

        return highlights
    }

    private func loadImageColors() async {
        guard let url = imageURL else { return }

        guard let image = await loadImage(from: url) else { return }

        let colors = await ColorExtractor.extractColors(
            from: image,
            count: 3,
            excluding: primaryColor,
            excluding: secondaryColor
        )

        await MainActor.run {
            extractedColors = colors
        }
    }

    private func extractFromProvidedImage() async {
        guard let image = image else { return }

        let colors = await ColorExtractor.extractColors(
            from: image,
            count: 3,
            excluding: primaryColor,
            excluding: secondaryColor
        )

        await MainActor.run {
            extractedColors = colors
        }
    }

    private func loadImage(from url: URL) async -> UIImage? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
}

extension Color {
    @MainActor
    public func imageBlobGradient(
        secondary: Color? = nil,
        imageURL: URL? = nil,
        preExtractedColors: [Color] = [],
        blur: CGFloat = 0.75,
        dithering: CGFloat = 0.4,
        particleSize: CGFloat = 80,
        fill: CGFloat = 0.5,
        blobSize: BlobSize = .medium,
        speed: CGFloat = 1.5
    ) -> some View {
        ImageBlobGradient(
            self,
            secondary: secondary,
            imageURL: imageURL,
            preExtractedColors: preExtractedColors,
            blur: blur,
            dithering: dithering,
            particleSize: particleSize,
            fill: fill,
            blobSize: blobSize,
            speed: speed
        )
    }

    @MainActor
    public func imageBlobGradient(
        secondary: Color? = nil,
        image: UIImage?,
        preExtractedColors: [Color] = [],
        blur: CGFloat = 0.75,
        dithering: CGFloat = 0.4,
        particleSize: CGFloat = 80,
        fill: CGFloat = 0.5,
        blobSize: BlobSize = .medium,
        speed: CGFloat = 1.5
    ) -> some View {
        ImageBlobGradient(
            self,
            secondary: secondary,
            image: image,
            preExtractedColors: preExtractedColors,
            blur: blur,
            dithering: dithering,
            particleSize: particleSize,
            fill: fill,
            blobSize: blobSize,
            speed: speed
        )
    }
}
