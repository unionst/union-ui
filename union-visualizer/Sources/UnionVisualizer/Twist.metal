#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Smooth interpolation using smoothstep
float2 smoothMix(float2 a, float2 b, float t) {
    float st = t * t * (3.0 - 2.0 * t);
    return mix(a, b, st);
}

/// 16-point mesh distortion (4x4 grid) with smooth interpolation
[[stitchable]] float2 meshDistort(
    float2 position,
    float2 size,
    // Row 0
    float2 p00, float2 p10, float2 p20, float2 p30,
    // Row 1
    float2 p01, float2 p11, float2 p21, float2 p31,
    // Row 2
    float2 p02, float2 p12, float2 p22, float2 p32,
    // Row 3
    float2 p03, float2 p13, float2 p23, float2 p33
) {
    // Normalize position to 0-1
    float2 uv = clamp(position / size, float2(0.0), float2(1.0));

    float tx = uv.x;
    float ty = uv.y;

    // Determine which cell (0, 1, or 2) and local t within that cell
    int cellX = int(tx * 3.0);
    int cellY = int(ty * 3.0);
    cellX = clamp(cellX, 0, 2);
    cellY = clamp(cellY, 0, 2);

    float localTx = fract(tx * 3.0);
    float localTy = fract(ty * 3.0);

    // Get the 4 corner points for this cell
    float2 corners[4][4] = {
        {p00, p10, p20, p30},
        {p01, p11, p21, p31},
        {p02, p12, p22, p32},
        {p03, p13, p23, p33}
    };

    float2 tl = corners[cellY][cellX];
    float2 tr = corners[cellY][cellX + 1];
    float2 bl = corners[cellY + 1][cellX];
    float2 br = corners[cellY + 1][cellX + 1];

    // Bilinear interpolation with smoothstep
    float2 top = smoothMix(tl, tr, localTx);
    float2 bottom = smoothMix(bl, br, localTx);
    float2 displacement = smoothMix(top, bottom, localTy);

    return position + displacement;
}
