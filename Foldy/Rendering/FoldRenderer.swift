import Metal
import MetalKit
import CoreVideo

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
    private var parameters = FoldRenderParameters(state: .hidden, appearance: .silk, viewportSize: .zero)

    init(view: MTKView) throws {
        guard let device = view.device ?? MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue()
        else { throw RendererError.metalUnavailable }

        view.device = device
        guard let library = try? device.makeLibrary(source: Self.shaderSource, options: nil),
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
        parameters = FoldRenderParameters(state: state, appearance: appearance, viewportSize: viewportSize)
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
        parameters.aspectRatio = size.height > 0 ? Float(size.width / size.height) : 1
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let pass = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass)
        else { return }

        encoder.setRenderPipelineState(pipelineState)
        encoder.setFragmentTexture(texture, index: 0)
        encoder.setFragmentBytes(&parameters, length: MemoryLayout<FoldRenderParameters>.stride, index: 0)
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
        float crease;
        float blur;
        float dim;
        float aspectRatio;
        float shadow;
        float styleMode;
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
        float creaseShadow = exp(-creaseDistance * 85.0) * parameters.crease * (0.18 + parameters.shadow * 0.34);
        float creaseEdge = exp(-abs(creaseDistance - 0.018) * 120.0) * parameters.crease * 0.10;
        color.rgb = color.rgb * (1.0 - creaseShadow) + creaseEdge;

        float horizonShade = p * (1.0 - sourceUV.y) * (0.08 + parameters.shadow * 0.24);
        color.rgb *= 1.0 - horizonShade;
        if (parameters.styleMode > 1.5) {
            color.rgb = mix(color.rgb, float3(0.72, 0.84, 1.0), p * 0.16);
        } else if (parameters.styleMode > 0.5) {
            color.rgb *= 1.0 - p * parameters.shadow * 0.13;
        }
        color.rgb *= 1.0 - parameters.dim * 0.88;
        return float4(color.rgb, 1.0);
    }
    """#
}
