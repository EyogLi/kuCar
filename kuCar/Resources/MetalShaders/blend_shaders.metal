#include <CoreImage/CoreImage.h>
#include <metal_stdlib>
using namespace metal;

// MARK: - Matte Noise Generator

// Hash helper for noise generation
inline float noiseHash(float2 p, float t) {
    float h = dot(p, float2(127.1, 311.7));
    return fract(sin(h) * 43758.5453 + t * 0.1);
}

/// Generates procedural noise for matte paint texture.
extern "C" float4 matteNoise(
    float time,
    float scale,
    float amount,
    coreimage::destination dest
) {
    float2 coord = dest.coord() * scale;

    // Simple value noise
    float2 i = floor(coord);
    float2 f = fract(coord);
    f = f * f * (3.0 - 2.0 * f); // smoothstep

    float a = noiseHash(i, time);
    float b = noiseHash(i + float2(1.0, 0.0), time);
    float c = noiseHash(i + float2(0.0, 1.0), time);
    float d = noiseHash(i + float2(1.0, 1.0), time);

    float noise = mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
    noise = (noise - 0.5) * amount;

    return float4(noise, noise, noise, 1.0);
}

// MARK: - Carbon Fiber Texture (Phase 2)

/// Procedural carbon fiber pattern.
extern "C" float4 carbonFiberPattern(
    float2 coord,
    float scale,
    float contrast,
    coreimage::destination dest
) {
    float2 uv = coord * scale;

    float2 cell = floor(uv);
    float2 offset = fract(uv);

    // Alternate weave direction per cell
    float weaveDir = fmod(cell.x + cell.y, 2.0) * 2.0 - 1.0;

    // Herringbone pattern
    float pattern = sin(offset.x * 6.2832 + weaveDir * offset.y * 3.0);
    pattern = smoothstep(0.3, 0.7, pattern);

    float3 color = mix(float3(0.05), float3(0.15), pattern);
    return float4(color, 1.0);
}

// MARK: - Chrome Environment Map Approximation

/// Simple chrome reflection approximation using gradient sampling.
extern "C" float4 chromeReflection(
    coreimage::sampler inputImage,
    float reflectionStrength,
    coreimage::destination dest
) {
    float2 coord = dest.coord();
    float4 original = inputImage.sample(coord);

    // Boost contrast for chrome effect
    float luminance = dot(original.rgb, float3(0.2126, 0.7152, 0.0722));

    // Create gradient-based reflection approximation
    float gradient = smoothstep(0.0, 1.0, luminance);

    float3 skyColor = float3(0.6, 0.8, 1.0);
    float3 groundColor = float3(0.2, 0.2, 0.25);

    float3 reflected = mix(groundColor, skyColor, gradient);

    // Mix with original detail
    float3 result = mix(original.rgb, reflected * original.rgb, reflectionStrength);

    return float4(result, original.a);
}
