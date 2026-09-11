import Metal
import MetalKit
import CoreVideo
import QuartzCore

@MainActor
final class FoldRenderer: NSObject, MTKViewDelegate {
    enum RendererError: Error {
        case metalUnavailable
        case shaderUnavailable
        case pipelineCreationFailed
    }

    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private var texture: MTLTexture
    private var textureCache: CVMetalTextureCache?
    private var targetParameters = FoldRenderParameters(state: .hidden, appearance: .silk, viewportSize: .zero)
    private var parameterSmoother = FoldParameterSmoother(
        initial: FoldRenderParameters(state: .hidden, appearance: .silk, viewportSize: .zero)
    )
    private var lastDrawTime: CFTimeInterval?

    init(view: MTKView) throws {
        guard let device = view.device ?? MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue()
        else { throw RendererError.metalUnavailable }

        view.device = device
        guard let library = device.makeDefaultLibrary(),
              let vertex = library.makeFunction(name: "foldVertex"),
              let fragment = library.makeFunction(name: "foldFragment")
        else { throw RendererError.shaderUnavailable }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertex
        descriptor.fragmentFunction = fragment
        descriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            throw RendererError.pipelineCreationFailed
        }

        self.commandQueue = commandQueue
        self.texture = Self.makeFallbackTexture(device: device)
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache)
        super.init()
    }

    func update(state: FoldState, appearance: FoldAppearance, viewportSize: CGSize) {
        targetParameters = FoldRenderParameters(state: state, appearance: appearance, viewportSize: viewportSize)
    }

    func update(texture: MTLTexture) {
        self.texture = texture
    }

    func update(pixelBuffer: CVPixelBuffer) {
        guard let textureCache else { return }
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        var metalTexture: CVMetalTexture?
        let status = CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureCache,
            pixelBuffer,
            nil,
            .bgra8Unorm,
            width,
            height,
            0,
            &metalTexture
        )
        guard status == kCVReturnSuccess,
              let metalTexture,
              let texture = CVMetalTextureGetTexture(metalTexture)
        else { return }
        self.texture = texture
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        targetParameters.aspectRatio = size.height > 0 ? Float(size.width / size.height) : 1
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let pass = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass)
        else { return }

        let now = CACurrentMediaTime()
        let elapsed = lastDrawTime.map { min(max(now - $0, 1.0 / 240.0), 0.1) } ?? (1.0 / 60.0)
        lastDrawTime = now
        var presentedParameters = parameterSmoother.step(
            toward: targetParameters,
            elapsed: elapsed
        )

        encoder.setRenderPipelineState(pipelineState)
        encoder.setFragmentTexture(texture, index: 0)
        encoder.setFragmentBytes(
            &presentedParameters,
            length: MemoryLayout<FoldRenderParameters>.stride,
            index: 0
        )
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    private static func makeFallbackTexture(device: MTLDevice) -> MTLTexture {
        let width = 512
        let height = 320
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        descriptor.usage = [.shaderRead]
        let texture = device.makeTexture(descriptor: descriptor)!

        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        for y in 0..<height {
            for x in 0..<width {
                let index = (y * width + x) * 4
                let nx = Double(x) / Double(width)
                let ny = Double(y) / Double(height)
                let wave = sin(nx * 8 + ny * 3) * 0.5 + 0.5
                pixels[index] = UInt8(150 + 45 * wave)
                pixels[index + 1] = UInt8(92 + 75 * (1 - ny))
                pixels[index + 2] = UInt8(38 + 85 * nx)
                pixels[index + 3] = 255
            }
        }

        texture.replace(
            region: MTLRegionMake2D(0, 0, width, height),
            mipmapLevel: 0,
            withBytes: pixels,
            bytesPerRow: width * 4
        )
        return texture
    }

    // Runtime compilation keeps local and CI builds independent of Xcode's optional
    // Metal Toolchain component. The source mirrors FoldShaders.metal for IDE editing.
    private static let shaderSource = #"""
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

    static inline float sdRoundedBox(float2 p, float2 b, float4 r) {
        r.xy = (p.x > 0.0) ? r.xy : r.zw;
        r.x  = (p.y > 0.0) ? r.x  : r.y;
        float2 q = abs(p) - b + r.x;
        return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r.x;
    }

    fragment float4 foldFragment(
        VertexOut input [[stage_in]],
        texture2d<float> screenTexture [[texture(0)]],
        constant FoldRenderParameters &parameters [[buffer(0)]]) {
        constexpr sampler screenSampler(coord::normalized, address::clamp_to_edge, filter::linear);

        float p = clamp(parameters.progress, 0.0, 1.0);
        if (p <= 0.0001) {
            return screenTexture.sample(screenSampler, input.uv);
        }

        float aspect = max(parameters.aspectRatio, 0.1);

        // Subtle Apple dark graphite ambient vignette backdrop
        float2 bgCenter = input.uv - float2(0.5, 0.5);
        float bgDist = length(float2(bgCenter.x * aspect, bgCenter.y));
        float3 bgColor = mix(float3(0.018, 0.020, 0.026), float3(0.004, 0.005, 0.008), smoothstep(0.25, 0.88, bgDist));

        // Grounded at the bottom hinge (uv.y = 1.0).
        // As lid closes (p -> 1.0), the top edge tilts down toward the bottom hinge.
        float panelHeight = mix(1.0, 0.10, p * (0.80 + 0.20 * parameters.perspective));
        float panelBottom = 1.0;
        float panelTop = panelBottom - panelHeight;

        // Contact drop shadow cast onto the background behind the tilting top edge
        float shadowDist = abs(input.uv.y - panelTop);
        if (input.uv.y < panelTop && shadowDist < 0.16) {
            float shadowIntensity = (1.0 - shadowDist / 0.16) * p * (0.50 + 0.50 * parameters.shadow);
            bgColor *= (1.0 - shadowIntensity * 0.75);
        }

        if (input.uv.y < panelTop || input.uv.y > panelBottom) {
            return float4(bgColor, 1.0);
        }

        // localY runs from 0.0 at the top edge of the panel to 1.0 at the bottom hinge
        float localY = (input.uv.y - panelTop) / panelHeight;
        float tiltFactor = 1.0 - localY; // 1.0 at top edge, 0.0 at hinge

        // 3D Perspective Pitch: top edge recedes into the distance (Z), narrowing the top
        float distanceZ = tiltFactor * p * parameters.perspective;
        float perspectiveScale = 1.0 / (1.0 + distanceZ * 0.95);
        float halfWidth = 0.5 * perspectiveScale;
        float centeredX = input.uv.x - 0.5;

        if (abs(centeredX) > halfWidth) {
            return float4(bgColor, 1.0);
        }

        float2 panelUV = float2(centeredX / (halfWidth * 2.0) + 0.5, localY);

        // Continuous squircle corner clipping
        float cornerRadius = 0.024;
        float2 boxSize = float2(0.5 - cornerRadius, 0.5 - cornerRadius);
        float dBox = sdRoundedBox(panelUV - float2(0.5, 0.5), boxSize, float4(cornerRadius));
        float edgeAA = smoothstep(0.003, -0.003, dBox);

        // Top edge progressive feather softening along with the bend
        float topFeather = smoothstep(0.0, 0.08 * p, localY);
        edgeAA *= mix(1.0, topFeather, p * 0.85);

        if (edgeAA <= 0.0) {
            return float4(bgColor, 1.0);
        }

        // Organic cylindrical curvature roll near the hinge
        float roll = sin(localY * M_PI_F) * 0.012 * parameters.perspective * p;
        panelUV.y += roll * (1.0 - localY);

        // Isotropic 2D Poisson disc depth-of-field bokeh (top edge defocuses progressively)
        constexpr float2 poisson[12] = {
            float2(-0.326, -0.406), float2(-0.840, -0.074),
            float2(-0.696,  0.457), float2(-0.203,  0.621),
            float2( 0.962, -0.195), float2( 0.473, -0.480),
            float2( 0.519,  0.767), float2( 0.185, -0.893),
            float2( 0.507,  0.064), float2( 0.896,  0.412),
            float2(-0.322, -0.933), float2(-0.792, -0.598)
        };

        float dofBlur = parameters.blur * (0.0015 + 0.010 * tiltFactor) * p;
        float2 blurRadius = float2(dofBlur / aspect, dofBlur);

        float4 color = screenTexture.sample(screenSampler, panelUV) * 0.22;
        for (int i = 0; i < 12; i++) {
            float2 sampleOffset = poisson[i] * blurRadius;
            color += screenTexture.sample(screenSampler, panelUV + sampleOffset) * 0.065;
        }

        // Glass chromatic dispersion (subtle optical prism along the fold)
        if (parameters.frost > 0.5) {
            float disp = 0.0035 * p * parameters.blur * tiltFactor;
            float rSample = screenTexture.sample(screenSampler, panelUV + float2(disp, 0.0)).r;
            float bSample = screenTexture.sample(screenSampler, panelUV - float2(disp, 0.0)).b;
            color.r = mix(color.r, rSample, 0.35);
            color.b = mix(color.b, bSample, 0.35);

            // Apple liquid glass sheen
            float sheen = pow(tiltFactor, 2.2) * p * 0.18;
            color.rgb += float3(0.85, 0.92, 1.0) * sheen;
        }

        // Specular ridge glint catching ambient lighting along the top edge
        float specularGlint = pow(max(0.0, 1.0 - abs(localY - 0.04)), 24.0) * p * 0.20;
        color.rgb += float3(1.0, 1.0, 1.0) * specularGlint;

        // Contact ambient shadow & horizon falloff (darkens towards the top as it tilts away)
        float horizonFalloff = p * tiltFactor * (0.08 + parameters.shadow * 0.26);
        color.rgb *= (1.0 - horizonFalloff);

        // Style mode shading
        if (parameters.styleMode > 0.5 && parameters.styleMode < 1.5) {
            color.rgb *= (1.0 - p * parameters.shadow * 0.18);
        }

        // Micro-specular glass bevel rim
        float bevel = smoothstep(-0.012, 0.0, dBox) * (1.0 - smoothstep(0.0, 0.008, dBox));
        color.rgb += float3(0.92, 0.96, 1.0) * bevel * 0.25 * (1.0 + p);

        // Dimming near complete close
        color.rgb *= (1.0 - parameters.dim * 0.85);

        // Anti-aliased composite over background
        float3 finalRgb = mix(bgColor, color.rgb, edgeAA);
        return float4(finalRgb, 1.0);
    }
    """#
}
