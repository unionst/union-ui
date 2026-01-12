import CoreImage
import SwiftUI
import UIKit

public struct ColorExtractor {
    public static func extractColors(
        from image: UIImage,
        count: Int = 3,
        excluding primaryColor: Color? = nil,
        excluding secondaryColor: Color? = nil
    ) async -> [Color] {
        await Task.detached(priority: .userInitiated) {
            extractDominantColors(
                from: image,
                count: count,
                primary: primaryColor,
                secondary: secondaryColor
            )
        }.value
    }

    public static func extractColorsSync(
        from image: UIImage,
        count: Int = 3,
        excluding primaryColor: Color? = nil,
        excluding secondaryColor: Color? = nil
    ) -> [Color] {
        extractDominantColors(
            from: image,
            count: count,
            primary: primaryColor,
            secondary: secondaryColor
        )
    }

    private struct ColorSample {
        let r, g, b: CGFloat
        let oklch: (l: CGFloat, c: CGFloat, h: CGFloat)
        var weight: Int = 1
    }

    private static func extractDominantColors(
        from image: UIImage,
        count: Int,
        primary: Color?,
        secondary: Color?
    ) -> [Color] {
        guard let cgImage = image.cgImage else { return [] }

        let context = CIContext(options: [.useSoftwareRenderer: false])
        let ciImage = CIImage(cgImage: cgImage)

        var samples = [ColorSample]()
        let sampleSize = 20
        let xStep = max(1, cgImage.width / sampleSize)
        let yStep = max(1, cgImage.height / sampleSize)

        for y in stride(from: 0, to: cgImage.height, by: yStep) {
            for x in stride(from: 0, to: cgImage.width, by: xStep) {
                var bitmap = [UInt8](repeating: 0, count: 4)
                let rect = CGRect(x: x, y: y, width: 1, height: 1)

                context.render(
                    ciImage,
                    toBitmap: &bitmap,
                    rowBytes: 4,
                    bounds: rect,
                    format: .RGBA8,
                    colorSpace: nil
                )

                let r = CGFloat(bitmap[0]) / 255.0
                let g = CGFloat(bitmap[1]) / 255.0
                let b = CGFloat(bitmap[2]) / 255.0
                let a = CGFloat(bitmap[3]) / 255.0

                let brightness = (r + g + b) / 3
                let saturation = max(r, g, b) - min(r, g, b)

                if a > 0.5 && brightness > 0.15 && brightness < 0.85 && saturation > 0.1 {
                    let oklch = rgbToOKLCH(r: r, g: g, b: b)
                    samples.append(ColorSample(r: r, g: g, b: b, oklch: oklch))
                }
            }
        }

        let clustered = clusterColors(samples, targetClusters: 6)
        let selected = selectDiverseColors(clustered, count: count, primary: primary)
        let boosted = selected.map { boostVibrance(Color(red: $0.r, green: $0.g, blue: $0.b)) }

        return boosted.filter { color in
            (primary == nil || !colorsAreTooSimilar(color, primary!)) &&
            (secondary == nil || !colorsAreTooSimilar(color, secondary!))
        }
    }

    private static func colorsAreTooSimilar(_ color1: Color, _ color2: Color) -> Bool {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

        UIColor(color1).getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        UIColor(color2).getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        let oklch1 = rgbToOKLCH(r: r1, g: g1, b: b1)
        let oklch2 = rgbToOKLCH(r: r2, g: g2, b: b2)

        return oklchDistance(oklch1, oklch2) < 0.15
    }

    private static func rgbToOKLCH(r: CGFloat, g: CGFloat, b: CGFloat) -> (l: CGFloat, c: CGFloat, h: CGFloat) {
        let lr = r > 0.04045 ? pow((r + 0.055) / 1.055, 2.4) : r / 12.92
        let lg = g > 0.04045 ? pow((g + 0.055) / 1.055, 2.4) : g / 12.92
        let lb = b > 0.04045 ? pow((b + 0.055) / 1.055, 2.4) : b / 12.92

        let l_ = 0.4122214708 * lr + 0.5363325363 * lg + 0.0514459929 * lb
        let m_ = 0.2119034982 * lr + 0.6806995451 * lg + 0.1073969566 * lb
        let s_ = 0.0883024619 * lr + 0.2817188376 * lg + 0.6299787005 * lb

        let l = cbrt(l_)
        let m = cbrt(m_)
        let s = cbrt(s_)

        let okL = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s
        let okA = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s
        let okB = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s

        let c = sqrt(okA * okA + okB * okB)
        var h = atan2(okB, okA) * 180 / .pi
        if h < 0 { h += 360 }

        return (okL, c, h)
    }

    private static func oklchDistance(
        _ a: (l: CGFloat, c: CGFloat, h: CGFloat),
        _ b: (l: CGFloat, c: CGFloat, h: CGFloat)
    ) -> CGFloat {
        let dL = a.l - b.l
        let dC = a.c - b.c
        var dH = abs(a.h - b.h)
        if dH > 180 { dH = 360 - dH }
        let dHNorm = dH / 180.0

        return sqrt(dL * dL + dC * dC * 2.0 + dHNorm * dHNorm * 0.5)
    }

    private static func clusterColors(_ samples: [ColorSample], targetClusters: Int) -> [ColorSample] {
        guard samples.count > targetClusters else { return samples }

        var clusters = [[ColorSample]]()
        let hueBuckets = 12
        let lightBuckets = 3

        for sample in samples {
            let hBucket = Int(sample.oklch.h / (360.0 / CGFloat(hueBuckets))) % hueBuckets
            let lBucket = min(lightBuckets - 1, Int(sample.oklch.l * CGFloat(lightBuckets)))
            let bucketIndex = hBucket * lightBuckets + lBucket

            while clusters.count <= bucketIndex {
                clusters.append([])
            }
            clusters[bucketIndex].append(sample)
        }

        var centroids = [ColorSample]()
        for cluster in clusters where !cluster.isEmpty {
            let avgR = cluster.reduce(0) { $0 + $1.r } / CGFloat(cluster.count)
            let avgG = cluster.reduce(0) { $0 + $1.g } / CGFloat(cluster.count)
            let avgB = cluster.reduce(0) { $0 + $1.b } / CGFloat(cluster.count)
            let oklch = rgbToOKLCH(r: avgR, g: avgG, b: avgB)
            centroids.append(ColorSample(r: avgR, g: avgG, b: avgB, oklch: oklch, weight: cluster.count))
        }

        return centroids
    }

    private static func selectDiverseColors(
        _ candidates: [ColorSample],
        count: Int,
        primary: Color?
    ) -> [ColorSample] {
        guard !candidates.isEmpty else { return [] }

        var primaryOKLCH: (l: CGFloat, c: CGFloat, h: CGFloat)?
        if let primary = primary {
            var pr: CGFloat = 0, pg: CGFloat = 0, pb: CGFloat = 0, pa: CGFloat = 0
            UIColor(primary).getRed(&pr, green: &pg, blue: &pb, alpha: &pa)
            primaryOKLCH = rgbToOKLCH(r: pr, g: pg, b: pb)
        }

        let sorted = candidates.sorted { a, b in
            let aScore = a.oklch.c * 2.0 + CGFloat(a.weight) * 0.01
            let bScore = b.oklch.c * 2.0 + CGFloat(b.weight) * 0.01
            return aScore > bScore
        }

        var result = [ColorSample]()
        let minHueSeparation: CGFloat = 30.0

        for candidate in sorted {
            if result.count >= count { break }

            let tooCloseToExisting = result.contains { existing in
                oklchDistance(candidate.oklch, existing.oklch) < 0.15
            }

            var tooCloseToPrimary = false
            var tooSimilarHueToPrimary = false
            if let primaryOKLCH = primaryOKLCH {
                tooCloseToPrimary = oklchDistance(candidate.oklch, primaryOKLCH) < 0.12
                var hueDiff = abs(candidate.oklch.h - primaryOKLCH.h)
                if hueDiff > 180 { hueDiff = 360 - hueDiff }
                tooSimilarHueToPrimary = hueDiff < minHueSeparation && candidate.oklch.c > 0.05
            }

            let hueTooCloseToExisting = result.contains { existing in
                var hDiff = abs(candidate.oklch.h - existing.oklch.h)
                if hDiff > 180 { hDiff = 360 - hDiff }
                return hDiff < minHueSeparation && candidate.oklch.c > 0.05 && existing.oklch.c > 0.05
            }

            if !tooCloseToExisting && !tooCloseToPrimary && !tooSimilarHueToPrimary && !hueTooCloseToExisting {
                result.append(candidate)
            }
        }

        if result.isEmpty, let best = sorted.first {
            result.append(best)
        }

        return result
    }

    private static func boostVibrance(_ color: Color) -> Color {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getHue(&h, saturation: &s, brightness: &b, alpha: &a)

        let boostedSaturation = min(1.0, s * 1.15 + 0.05)
        let adjustedBrightness = min(1.0, max(0.3, b * 1.05))

        return Color(hue: h, saturation: boostedSaturation, brightness: adjustedBrightness, opacity: a)
    }
}
