#include <CoreImage/CoreImage.h>
#include <metal_stdlib>
using namespace metal;

// MARK: - Paint Finish Shader

/// Applies PBR-based paint finish effect to a masked car body region.
/// Simulates gloss, matte, satin, metallic, and chrome finishes.
extern "C" float4 paintFinish(
    coreimage::sampler inputImage,
    coreimage::sampler maskImage,
    float3 targetColor,
    float roughness,
    float metallic,
    float intensity,
    coreimage::destination dest
) {
    float2 coord = dest.coord();
    float4 original = inputImage.sample(coord);
    float4 mask = maskImage.sample(coord);

    // Extract luminance from original for lighting preservation
    float luminance = dot(original.rgb, float3(0.2126, 0.7152, 0.0722));

    // Compute specular highlight from original image
    float specular = pow(max(luminance, 0.0), 2.0) * (1.0 - roughness);

    // Metallic flake noise
    float flake = 0.0;
    if (metallic > 0.1) {
        // Pseudo-random noise at fine scale for metallic flakes
        float2 flakeCoord = coord * 300.0;
        float noise = sin(dot(flakeCoord, float2(12.9898, 78.233))) * 43758.5453;
        noise = fract(noise);
        // Threshold to create sparse flakes
        flake = smoothstep(0.85, 0.95, noise) * metallic * 0.2;
    }

    // Build tinted color modulated by luminance
    float3 baseColor = targetColor * luminance;

    // Apply metallic: shift color toward reflected environment (approximated by original)
    float3 metallicColor = mix(baseColor, original.rgb * targetColor, metallic);

    // Add specular highlight
    float3 specularColor = float3(1.0) * specular * (1.0 - roughness);

    // Combine with flake
    float3 tinted = metallicColor + specularColor + flake;

    // Blend with original based on mask and intensity
    float blendFactor = mask.r * intensity;
    float3 result = mix(original.rgb, tinted, blendFactor);

    return float4(result, original.a);
}

// MARK: - Blend Shaders

/// Soft light blend for highlight preservation.
extern "C" float4 softLightBlend(
    coreimage::sampler foreground,
    coreimage::sampler background,
    coreimage::destination dest
) {
    float2 coord = dest.coord();
    float4 fg = foreground.sample(coord);
    float4 bg = background.sample(coord);

    float3 result;
    for (int i = 0; i < 3; i++) {
        if (fg[i] <= 0.5) {
            result[i] = bg[i] - (1.0 - 2.0 * fg[i]) * bg[i] * (1.0 - bg[i]);
        } else {
            float d = (bg[i] <= 0.25) ? ((16.0 * bg[i] - 12.0) * bg[i] + 4.0) * bg[i] : sqrt(bg[i]);
            result[i] = bg[i] + (2.0 * fg[i] - 1.0) * (d - bg[i]);
        }
    }

    return float4(result, bg.a);
}

/// Shadow multiply blend — darkens the wheel area to simulate original shadows.
extern "C" float4 shadowBlend(
    coreimage::sampler wheelImage,
    coreimage::sampler shadowMask,
    float shadowStrength,
    coreimage::destination dest
) {
    float2 coord = dest.coord();
    float4 wheel = wheelImage.sample(coord);
    float4 shadow = shadowMask.sample(coord);

    // Darken the wheel based on shadow intensity
    float darkness = 1.0 - (shadow.r * shadowStrength);
    float3 result = wheel.rgb * darkness;

    return float4(result, wheel.a);
}
