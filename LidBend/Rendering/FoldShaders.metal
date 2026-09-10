#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

struct FoldRenderParameters {
    float progress;
    float perspective;
    float crease;
    float blur;
    float dim;
    float aspectRatio;
    float padding0;
    float padding1;
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

    float blurStep = parameters.blur * 0.0028;
    float4 color = float4(0.0);
    color += screenTexture.sample(screenSampler, sourceUV + float2(0, -4 * blurStep)) * 0.05;
    color += screenTexture.sample(screenSampler, sourceUV + float2(0, -3 * blurStep)) * 0.09;
    color += screenTexture.sample(screenSampler, sourceUV + float2(0, -2 * blurStep)) * 0.12;
    color += screenTexture.sample(screenSampler, sourceUV + float2(0, -1 * blurStep)) * 0.15;
    color += screenTexture.sample(screenSampler, sourceUV) * 0.18;
    color += screenTexture.sample(screenSampler, sourceUV + float2(0, 1 * blurStep)) * 0.15;
    color += screenTexture.sample(screenSampler, sourceUV + float2(0, 2 * blurStep)) * 0.12;
    color += screenTexture.sample(screenSampler, sourceUV + float2(0, 3 * blurStep)) * 0.09;
    color += screenTexture.sample(screenSampler, sourceUV + float2(0, 4 * blurStep)) * 0.05;

    float creaseDistance = abs(sourceUV.x - 0.5);
    float creaseShadow = exp(-creaseDistance * 85.0) * parameters.crease * 0.34;
    float creaseEdge = exp(-abs(creaseDistance - 0.018) * 120.0) * parameters.crease * 0.10;
    color.rgb = color.rgb * (1.0 - creaseShadow) + creaseEdge;

    float horizonShade = p * (1.0 - sourceUV.y) * 0.20;
    color.rgb *= 1.0 - horizonShade;
    color.rgb *= 1.0 - parameters.dim * 0.88;
    return float4(color.rgb, 1.0);
}
