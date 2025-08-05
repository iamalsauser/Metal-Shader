import Metal
import MetalKit
import AVFoundation
import CoreVideo

class Renderer: NSObject, ObservableObject {
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var textureCache: CVMetalTextureCache!
    
    // Pipelines
    private var computePipelineState: MTLComputePipelineState!
    private var renderPipelineState: MTLRenderPipelineState!
    
    // Textures
    private var cameraTexture: MTLTexture?
    private var processedTexture: MTLTexture?
    private var tempTexture: MTLTexture?
    
    // Buffers
    private var uniformBuffer: MTLBuffer!
    private var timeBuffer: MTLBuffer!
    
    // Camera
    private var captureSession: AVCaptureSession!
    private var videoDataOutput: AVCaptureVideoDataOutput!
    
    // Settings
    @Published var blurRadius: Float = 5.0
    @Published var edgeDetectionEnabled: Bool = false
    @Published var edgeStrength: Float = 1.0
    @Published var waveFrequency: Float = 10.0
    @Published var waveAmplitude: Float = 0.02
    @Published var chromaticAberrationStrength: Float = 0.5
    @Published var exposure: Float = 1.0
    @Published var grainStrength: Float = 0.1
    @Published var vignetteStrength: Float = 0.5
    @Published var magnifyingGlassEnabled: Bool = false
    @Published var magnifyingGlassCenter: CGPoint = CGPoint(x: 0.5, y: 0.5)
    @Published var magnifyingGlassRadius: Float = 0.2
    @Published var magnifyingGlassStrength: Float = 0.5
    
    private var startTime: CFTimeInterval!
    private var currentTime: Float = 0.0
    
    override init() {
        super.init()
        setupMetal()
        setupCamera()
        startTime = CACurrentMediaTime()
    }
    
    private func setupMetal() {
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device.makeCommandQueue()
        
        // Create texture cache
        var textureCache: CVMetalTextureCache?
        CVMetalTextureCacheCreate(nil, nil, device, nil, &textureCache)
        self.textureCache = textureCache
        
        // Create compute pipeline
        let library = device.makeDefaultLibrary()
        let computeFunction = library?.makeFunction(name: "gaussianBlurHorizontal")
        computePipelineState = try! device.makeComputePipelineState(function: computeFunction!)
        
        // Create render pipeline
        let vertexFunction = library?.makeFunction(name: "sineDisplacementVertex")
        let fragmentFunction = library?.makeFunction(name: "filmGrainFragment")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        // Set up vertex descriptor
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = 12
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stride = 20
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        renderPipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        
        // Create buffers
        uniformBuffer = device.makeBuffer(length: MemoryLayout<Float>.size * 10, options: [])
        timeBuffer = device.makeBuffer(length: MemoryLayout<Float>.size, options: [])
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Failed to get camera")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            captureSession.addInput(input)
            
            videoDataOutput = AVCaptureVideoDataOutput()
            videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInteractive))
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            
            captureSession.addOutput(videoDataOutput)
            captureSession.startRunning()
        } catch {
            print("Failed to setup camera: \(error)")
        }
    }
    
    private func createTexture(from pixelBuffer: CVPixelBuffer) -> MTLTexture? {
        var textureRef: CVMetalTexture?
        let status = CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, pixelBuffer, nil, .bgra8Unorm, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer), 0, &textureRef)
        
        guard status == kCVReturnSuccess else { return nil }
        return CVMetalTextureGetTexture(textureRef!)
    }
    
    private func createTexture(width: Int, height: Int) -> MTLTexture? {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false)
        descriptor.usage = [.shaderRead, .shaderWrite]
        return device.makeTexture(descriptor: descriptor)
    }
    
    func updateTime() {
        currentTime = Float(CACurrentMediaTime() - startTime)
        let timeData = timeBuffer.contents().assumingMemoryBound(to: Float.self)
        timeData[0] = currentTime
    }
}

// MARK: - MTKViewDelegate
extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle size changes if needed
    }
    
    func draw(in view: MTKView) {
        updateTime()
        
        guard let drawable = view.currentDrawable,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor else {
            return
        }
        
        // Apply compute shaders if we have camera texture
        if let cameraTexture = cameraTexture {
            applyComputeEffects(commandBuffer: commandBuffer, inputTexture: cameraTexture)
        }
        
        // Render to screen
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoder?.setRenderPipelineState(renderPipelineState)
        
        // Set vertex buffer
        let vertexData: [Float] = [
            -1.0, -1.0, 0.0, 0.0, 1.0,  // position, texCoord
             1.0, -1.0, 0.0, 1.0, 1.0,
            -1.0,  1.0, 0.0, 0.0, 0.0,
             1.0,  1.0, 0.0, 1.0, 0.0
        ]
        
        let vertexBuffer = device.makeBuffer(bytes: vertexData, length: vertexData.count * MemoryLayout<Float>.size, options: [])
        renderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        // Set fragment texture
        let textureToRender = processedTexture ?? cameraTexture
        renderEncoder?.setFragmentTexture(textureToRender, index: 0)
        
        // Set uniform buffers
        renderEncoder?.setVertexBuffer(timeBuffer, offset: 0, index: 0)
        renderEncoder?.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        renderEncoder?.setFragmentBuffer(uniformBuffer, offset: 0, index: 0)
        
        // Update uniform buffer with current settings
        updateUniformBuffer()
        
        renderEncoder?.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder?.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    private func applyComputeEffects(commandBuffer: MTLCommandBuffer, inputTexture: MTLTexture) {
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
        
        computeEncoder.setComputePipelineState(computePipelineState)
        
        // Create output texture if needed
        if processedTexture == nil || processedTexture!.width != inputTexture.width || processedTexture!.height != inputTexture.height {
            processedTexture = createTexture(width: inputTexture.width, height: inputTexture.height)
            tempTexture = createTexture(width: inputTexture.width, height: inputTexture.height)
        }
        
        // Apply Gaussian blur
        if blurRadius > 0 {
            // Horizontal pass
            computeEncoder.setTexture(inputTexture, index: 0)
            computeEncoder.setTexture(tempTexture, index: 1)
            computeEncoder.setBytes(&blurRadius, length: MemoryLayout<Float>.size, index: 0)
            
            let threadGroupSize = MTLSize(width: 16, height: 16, depth: 1)
            let threadGroups = MTLSize(width: (inputTexture.width + threadGroupSize.width - 1) / threadGroupSize.width,
                                     height: (inputTexture.height + threadGroupSize.height - 1) / threadGroupSize.height,
                                     depth: 1)
            computeEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
            
            // Vertical pass
            computeEncoder.setTexture(tempTexture, index: 0)
            computeEncoder.setTexture(processedTexture, index: 1)
            computeEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        } else {
            // Just copy input to output
            let blitEncoder = commandBuffer.makeBlitCommandEncoder()
            blitEncoder?.copy(from: inputTexture, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0), sourceSize: MTLSize(width: inputTexture.width, height: inputTexture.height, depth: 1), to: processedTexture!, destinationSlice: 0, destinationLevel: 0, destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
            blitEncoder?.endEncoding()
        }
        
        computeEncoder.endEncoding()
    }
    
    private func updateUniformBuffer() {
        let uniformData = uniformBuffer.contents().assumingMemoryBound(to: Float.self)
        
        // Vertex shader uniforms
        uniformData[0] = currentTime
        uniformData[1] = waveFrequency
        uniformData[2] = waveAmplitude
        
        // Fragment shader uniforms
        uniformData[3] = chromaticAberrationStrength
        uniformData[4] = exposure
        uniformData[5] = grainStrength
        uniformData[6] = vignetteStrength
        uniformData[7] = Float(magnifyingGlassCenter.x)
        uniformData[8] = Float(magnifyingGlassCenter.y)
        uniformData[9] = magnifyingGlassRadius
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension Renderer: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        DispatchQueue.main.async {
            self.cameraTexture = self.createTexture(from: pixelBuffer)
        }
    }
} 
