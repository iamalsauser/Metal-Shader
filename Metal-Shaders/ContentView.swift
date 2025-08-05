//
//  ContentView.swift
//  Metal-Shaders
//
//  Created by Parth Sinh on 05/08/25.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var renderer = Renderer()
    
    var body: some View {
        ZStack {
            // Metal Camera View
            MetalCameraView(renderer: renderer)
                .ignoresSafeArea()
            // Control Panel
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    // Blur Controls
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Blur Radius")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack {
                            Slider(value: $renderer.blurRadius, in: 0...20)
                                .accentColor(.blue)
                            
                            Text("\(Int(renderer.blurRadius))")
                                .foregroundColor(.white)
                                .frame(width: 30)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    
                    // Edge Detection
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Toggle("Edge Detection", isOn: $renderer.edgeDetectionEnabled)
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        
                        if renderer.edgeDetectionEnabled {
                            HStack {
                                Slider(value: $renderer.edgeStrength, in: 0...5)
                                    .accentColor(.green)
                                
                                Text("\(String(format: "%.1f", renderer.edgeStrength))")
                                    .foregroundColor(.white)
                                    .frame(width: 40)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    
                    // Wave Effects
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Wave Effects")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack {
                            Text("Freq:")
                                .foregroundColor(.white)
                            Slider(value: $renderer.waveFrequency, in: 0...50)
                                .accentColor(.orange)
                            Text("\(Int(renderer.waveFrequency))")
                                .foregroundColor(.white)
                                .frame(width: 30)
                        }
                        
                        HStack {
                            Text("Amp:")
                                .foregroundColor(.white)
                            Slider(value: $renderer.waveAmplitude, in: 0...0.1)
                                .accentColor(.orange)
                            Text("\(String(format: "%.3f", renderer.waveAmplitude))")
                                .foregroundColor(.white)
                                .frame(width: 50)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    
                    // Color Effects
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color Effects")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack {
                            Text("Chromatic:")
                                .foregroundColor(.white)
                            Slider(value: $renderer.chromaticAberrationStrength, in: 0...2)
                                .accentColor(.purple)
                            Text("\(String(format: "%.1f", renderer.chromaticAberrationStrength))")
                                .foregroundColor(.white)
                                .frame(width: 40)
                        }
                        
                        HStack {
                            Text("Exposure:")
                                .foregroundColor(.white)
                            Slider(value: $renderer.exposure, in: 0...3)
                                .accentColor(.yellow)
                            Text("\(String(format: "%.1f", renderer.exposure))")
                                .foregroundColor(.white)
                                .frame(width: 40)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    
                    // Film Effects
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Film Effects")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack {
                            Text("Grain:")
                                .foregroundColor(.white)
                            Slider(value: $renderer.grainStrength, in: 0...0.5)
                                .accentColor(.brown)
                            Text("\(String(format: "%.2f", renderer.grainStrength))")
                                .foregroundColor(.white)
                                .frame(width: 40)
                        }
                        
                        HStack {
                            Text("Vignette:")
                                .foregroundColor(.white)
                            Slider(value: $renderer.vignetteStrength, in: 0...2)
                                .accentColor(.brown)
                            Text("\(String(format: "%.1f", renderer.vignetteStrength))")
                                .foregroundColor(.white)
                                .frame(width: 40)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    
                    // Magnifying Glass
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Toggle("Magnifying Glass", isOn: $renderer.magnifyingGlassEnabled)
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        
                        if renderer.magnifyingGlassEnabled {
                            HStack {
                                Text("Radius:")
                                    .foregroundColor(.white)
                                Slider(value: $renderer.magnifyingGlassRadius, in: 0.1...0.5)
                                    .accentColor(.red)
                                Text("\(String(format: "%.2f", renderer.magnifyingGlassRadius))")
                                    .foregroundColor(.white)
                                    .frame(width: 40)
                            }
                            
                            HStack {
                                Text("Strength:")
                                    .foregroundColor(.white)
                                Slider(value: $renderer.magnifyingGlassStrength, in: 0...1)
                                    .accentColor(.red)
                                Text("\(String(format: "%.1f", renderer.magnifyingGlassStrength))")
                                    .foregroundColor(.white)
                                    .frame(width: 40)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            // Request camera permission
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if !granted {
                    print("Camera access denied")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
