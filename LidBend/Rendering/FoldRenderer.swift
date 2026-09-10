import Metal
import MetalKit

final class FoldRenderer: NSObject, MTKViewDelegate {
    enum RendererError: Error {
        case metalUnavailable
        case shaderUnavailable
        case pipelineCreationFailed
    }

    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private var texture: MTLTexture
    private var parameters = FoldRenderParameters(state: .hidden, viewportSize: .zero)

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
        super.init()
    }

    func update(state: FoldState, viewportSize: CGSize) {
        parameters = FoldRenderParameters(state: state, viewportSize: viewportSize)
    }

    func update(texture: MTLTexture) {
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
                let tile = ((x / 64) + (y / 64)) % 2
                pixels[index] = UInt8(tile == 0 ? 70 : 118)
                pixels[index + 1] = UInt8(tile == 0 ? 42 : 74)
                pixels[index + 2] = UInt8(tile == 0 ? 24 : 45)
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
}
