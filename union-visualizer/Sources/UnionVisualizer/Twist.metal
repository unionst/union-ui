#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Attempt at smooth interpolation
float2 smoothMix(float2 a, float2 b, float t) {
    // Smoothstep for easing
    float st = t * t * (3.0 - 2.0 * t);
    return mix(a, b, st);
}

// Attempt at catmull-rom / cubic
float2 cubicInterp(float2 p0, float2 p1, float2 p2, float2 p3, float t) {
    float t2 = t * t;
    float t3 = t2 * t;

    float2 a = -0.5 * p0 + 1.5 * p1 - 1.5 * p2 + 0.5 * p3;
    float2 b = p0 - 2.5 * p1 + 2.0 * p2 - 0.5 * p3;
    float2 c = -0.5 * p0 + 0.5 * p2;
    float2 d = p1;

    return a * t3 + b * t2 + c * t + d;
}

/// 9-point mesh distortion with smooth interpolation
[[stitchable]] float2 meshDistort(
    float2 position,
    float2 size,
    float2 p00, float2 p10, float2 p20,
    float2 p01, float2 p11, float2 p21,
    float2 p02, float2 p12, float2 p22
) {
    // Normalize position to 0-1
    float2 uv = position / size;

    // Clamp to valid range
    uv = clamp(uv, float2(0.0), float2(1.0));

    // Interpolation parameter across the grid
    float tx = uv.x;
    float ty = uv.y;

    // Cubic interpolation for each row, then interpolate between rows
    // Row 0 (top)
    float2 row0 = cubicInterp(p00, p00, p10, p20, tx) * (1.0 - tx) * 2.0
                + cubicInterp(p00, p10, p20, p20, tx) * tx * 2.0;
    // Simplified: use smoothstep blend across the 3 points per row
    float2 r0_01 = smoothMix(p00, p10, tx * 2.0);
    float2 r0_12 = smoothMix(p10, p20, tx * 2.0 - 1.0);
    float2 row0_final = tx < 0.5 ? smoothMix(p00, p10, tx * 2.0) : smoothMix(p10, p20, (tx - 0.5) * 2.0);

    float2 r1_01 = smoothMix(p01, p11, tx * 2.0);
    float2 r1_12 = smoothMix(p11, p21, tx * 2.0 - 1.0);
    float2 row1_final = tx < 0.5 ? smoothMix(p01, p11, tx * 2.0) : smoothMix(p11, p21, (tx - 0.5) * 2.0);

    float2 r2_01 = smoothMix(p02, p12, tx * 2.0);
    float2 r2_12 = smoothMix(p12, p22, tx * 2.0 - 1.0);
    float2 row2_final = tx < 0.5 ? smoothMix(p02, p12, tx * 2.0) : smoothMix(p12, p22, (tx - 0.5) * 2.0);

    // Now interpolate vertically between the 3 rows
    float2 col_final;
    if (ty < 0.5) {
        col_final = smoothMix(row0_final, row1_final, ty * 2.0);
    } else {
        col_final = smoothMix(row1_final, row2_final, (ty - 0.5) * 2.0);
    }

    return position + col_final;
}
