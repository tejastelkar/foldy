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

static inline float materialNoise(float2 uv) {
    float2 cell = floor(uv * float2(820.0, 520.0));
    return fract(sin(dot(cell, float2(12.9898, 78.233))) * 43758.5453) - 0.5;
}

fragment float4 foldFragment(
    VertexOut input [[stage_in]],
    texture2d<float> screenTexture [[texture(0)]],
    constant FoldRenderParameters &parameters [[buffer(0)]]) {
    constexpr sampler screenSampler(coord::normalized, address::clamp_to_edge, filter::linear);

    float p = clamp(parameters.progress, 0.0, 1.0);
    if (p < 0.0005) {
        return screenTexture.sample(screenSampler, input.uv);
    }

    float aspect = max(parameters.aspectRatio, 0.1);
    float2 bgCenter = input.uv - float2(0.5, 0.5);
    float bgDist = length(float2(bgCenter.x * aspect, bgCenter.y));
    float3 bgColor = mix(
        float3(0.020, 0.024, 0.034),
        float3(0.003, 0.005, 0.010),
        smoothstep(0.18, 0.92, bgDist)
    );

    // The desktop recedes toward a fixed bottom hinge, like a physical display.
    float eased = p * p * (3.0 - 2.0 * p);
    float panelHeight = mix(1.0, 0.075, eased * (0.84 + 0.16 * parameters.perspective));
    float panelBottom = 1.0;
    float panelTop = panelBottom - panelHeight;

    float shadowDistance = max(panelTop - input.uv.y, 0.0);
    float contactShadow = exp2(-shadowDistance * 42.0) * p * parameters.shadow;
    bgColor *= 1.0 - contactShadow * 0.58;

    if (input.uv.y < panelTop || input.uv.y > panelBottom) {
        return float4(bgColor, 1.0);
    }

    float localY = (input.uv.y - panelTop) / panelHeight;
    float depth = 1.0 - localY;
    float perspectiveScale = 1.0 / (1.0 + depth * p * parameters.perspective * 0.88);
    float halfWidth = 0.5 * perspectiveScale;
    float centeredX = input.uv.x - 0.5;

    if (abs(centeredX) > halfWidth) {
        return float4(bgColor, 1.0);
    }

    float2 panelUV = float2(centeredX / (halfWidth * 2.0) + 0.5, localY);
    float edgeDistance = min(min(panelUV.x, 1.0 - panelUV.x), min(panelUV.y, 1.0 - panelUV.y));
    float edgeAA = smoothstep(0.0, 0.0035, edgeDistance);

    if (edgeAA <= 0.0) {
        return float4(bgColor, 1.0);
    }

    // A shallow cylindrical roll creates pliable glass without a center crease.
    float roll = sin(localY * M_PI_F) * 0.009 * p * parameters.perspective;
    panelUV.y += roll * depth;

    // Five fixed samples replace the previous 13–15 tap bokeh kernel.
    float blurRadius = parameters.blur * p * (0.0012 + 0.0068 * depth);
    float2 vertical = float2(0.0, blurRadius);
    float2 horizontal = float2(blurRadius * 0.42 / aspect, 0.0);
    float4 color = screenTexture.sample(screenSampler, panelUV) * 0.36;
    color += screenTexture.sample(screenSampler, panelUV + vertical) * 0.18;
    color += screenTexture.sample(screenSampler, panelUV - vertical) * 0.18;
    color += screenTexture.sample(screenSampler, panelUV + horizontal) * 0.14;
    color += screenTexture.sample(screenSampler, panelUV - horizontal) * 0.14;

    float luminance = dot(color.rgb, float3(0.2126, 0.7152, 0.0722));
    float frostStrength = parameters.frost * p;
    color.rgb = mix(color.rgb, float3(luminance), frostStrength * 0.16);
    color.rgb = mix(color.rgb, float3(0.68, 0.82, 1.0), frostStrength * (0.08 + depth * 0.10));

    // Duo-inspired blue/violet refraction and a soft traveling silk highlight.
    float3 blueEdge = mix(float3(0.20, 0.56, 1.0), float3(0.48, 0.34, 1.0), panelUV.x);
    float refraction = depth * depth * p * (0.045 + 0.08 * parameters.perspective);
    color.rgb += blueEdge * refraction;

    float sweepPosition = panelUV.x * 0.34 + panelUV.y - (0.20 + eased * 0.46);
    float silkSheen = exp2(-sweepPosition * sweepPosition * 150.0) * p;
    color.rgb += float3(0.72, 0.86, 1.0) * silkSheen * (0.025 + frostStrength * 0.08);

    // Fine stable grain gives the closing surface a physical glass texture.
    float grain = materialNoise(panelUV);
    color.rgb += grain * p * (0.010 + frostStrength * 0.022) * (0.35 + 0.65 * depth);

    float topRim = exp2(-localY * localY * 1400.0) * p;
    color.rgb += float3(0.78, 0.90, 1.0) * topRim * (0.10 + parameters.shadow * 0.08);

    float horizonFalloff = p * depth * (0.06 + parameters.shadow * 0.22);
    color.rgb *= 1.0 - horizonFalloff;
    if (parameters.styleMode > 0.5 && parameters.styleMode < 1.5) {
        color.rgb *= 1.0 - p * parameters.shadow * 0.16;
    }
    color.rgb *= (1.0 - parameters.dim * 0.85);
    return float4(mix(bgColor, color.rgb, edgeAA), 1.0);
}
