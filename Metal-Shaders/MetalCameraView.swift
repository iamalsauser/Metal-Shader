import SwiftUI
import MetalKit

struct MetalCameraView: UIViewRepresentable {
    @ObservedObject var renderer: Renderer
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.delegate = renderer
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false
        mtkView.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        // Update view if needed
    }
} 