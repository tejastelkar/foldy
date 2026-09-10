#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

struct FoldRenderParameters {
    float progress;
    float perspective;
    float blur;
    float dim;
    float aspectRatio;
    float shadow;
    float styleMode;
    float frost;
};

vertex VertexOut foldVertex(uint vertexID [[vertex_id]]) {
    constexpr float2 positions[] = {
        float2(-1.0, -1.0), float2(1.0, -1.0),
        float2(-1.0, 1.0), float2(1.0, 1.0)
    };
    constexpr float2 coordinates[] = {
        float2(0.0, 1.0), float2(1.0, 1.0),
        float2(0.0, 0.0), float2(1.0, 0.0)
    };

    VertexOut output;
    output.position = float4(positions[vertexID], 0.0, 1.0);
    output.uv = coordinates[vertexID];
    return output;
}

fragment float4 foldFragment(
    VertexOut input [[stage_in]],
    texture2d<float> screenTexture [[texture(0)]],
    constant FoldRenderParameters &parameters [[buffer(0)]]) {
    constexpr sampler screenSampler(coord::normalized, address::clamp_to_edge, filter::linear);

    float p = clamp(parameters.progress, 0.0, 1.0);
    float planeHeight = mix(1.0, 0.10, p * p);
    float planeTop = (1.0 - planeHeight) * 0.62;
    float localY = (input.uv.y - planeTop) / planeHeight;

    if (localY < 0.0 || localY > 1.0) {
        return float4(0.006, 0.008, 0.014, 1.0);
    }

    float taper = p * 0.16 * (1.0 - localY);
    float halfWidth = 0.5 * (1.0 - taper);
    float centeredX = input.uv.x - 0.5;
    if (abs(centeredX) > halfWidth) {
        return float4(0.006, 0.008, 0.014, 1.0);
    }

    float2 sourceUV = float2(centeredX / (halfWidth * 2.0) + 0.5, localY);
    float bend = sin(sourceUV.y * M_PI_F) * parameters.perspective * 0.035;
    sourceUV.x += (sourceUV.x - 0.5) * bend;

    float frost = clamp(parameters.frost, 0.0, 1.0);
    float blurStep = parameters.blur * mix(0.0028, 0.0068, frost) * (0.28 + p * 0.72);
    float2 diagonal = float2(blurStep / max(parameters.aspectRatio, 1.0), blurStep);
    float4 color = float4(0.0);
    color += screenTexture.sample(screenSampler, sourceUV) * 0.28;
    color += screenTexture.sample(screenSampler, sourceUV + float2(0, -3 * blurStep)) * 0.10;
    color += screenTexture.sample(screenSampler, sourceUV + float2(0, -2 * blurStep)) * 0.12;
    color += screenTexture.sample(screenSampler, sourceUV + float2(0, -blurStep)) * 0.14;
    color += screenTexture.sample(screenSampler, sourceUV + float2(0, blurStep)) * 0.14;
    color += screenTexture.sample(screenSampler, sourceUV + float2(0, 2 * blurStep)) * 0.12;
    color += screenTexture.sample(screenSampler, sourceUV + float2(0, 3 * blurStep)) * 0.10;
    color += screenTexture.sample(screenSampler, sourceUV + diagonal * float2(-2, -2)) * (0.05 * frost);
    color += screenTexture.sample(screenSampler, sourceUV + diagonal * float2(2, -2)) * (0.05 * frost);
    color += screenTexture.sample(screenSampler, sourceUV + diagonal * float2(-2, 2)) * (0.05 * frost);
    color += screenTexture.sample(screenSampler, sourceUV + diagonal * float2(2, 2)) * (0.05 * frost);
    color.rgb /= 1.0 + 0.20 * frost;

    float horizonShade = p * (1.0 - sourceUV.y) * (0.08 + parameters.shadow * 0.24);
    color.rgb *= 1.0 - horizonShade;
    if (frost > 0.5) {
        float luminance = dot(color.rgb, float3(0.2126, 0.7152, 0.0722));
        color.rgb = mix(color.rgb, float3(luminance), 0.24 + p * 0.18);
        float glassStrength = (0.18 + parameters.blur * 0.20) * (0.30 + p * 0.70);
        color.rgb = mix(color.rgb, float3(0.69, 0.85, 1.0), glassStrength);
        float bloom = pow(1.0 - sourceUV.y, 2.0) * p * 0.12;
        color.rgb += float3(0.30, 0.64, 1.0) * bloom;
    } else if (parameters.styleMode > 0.5) {
        color.rgb *= 1.0 - p * parameters.shadow * 0.13;
    }
    color.rgb *= 1.0 - parameters.dim * 0.88;
    return float4(color.rgb, 1.0);
}
