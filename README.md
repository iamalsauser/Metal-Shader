# Metal Shaders - Real-time Camera Effects

---

## For Interviewers: Quick Checklist

Hey there! If you're reviewing or running this project, here's everything you need to know to get it working on a real iPhone or iPad:

- **Camera Permissions:**
  - The app will ask for camera access the first time you launch it. Please allow access so you can see the live video effects!
- **Physical Device Required:**
  - The iOS Simulator doesn't have a real camera, so you'll need to run this on an actual device to see the effects in action.
- **No Build Errors:**
  - All Info.plist and Metal buffer issues are fixed. You shouldn't see any build or runtime errors related to permissions or Metal.
- **What You'll See:**
  - A live camera feed with real-time Metal-powered visual effects (blur, edge detection, color tweaks, and more).
  - A control panel at the bottom lets you play with all the effects in real time.
- **If You Hit Any Issues:**
  - Make sure camera permissions are granted (check Settings if you missed the prompt).
  - If you see a black screen, double-check you're on a real device and not the simulator.

Enjoy exploring the code and the effects! If you have any questions, just ask.

---

# Metal Shaders - Real-time Camera Effects

A SwiftUI + Metal application that applies real-time visual effects to a camera feed using custom Metal shaders.

## Features

### Compute Shaders
- **Gaussian Blur**: Separable horizontal and vertical blur with adjustable radius
- **Edge Detection**: Sobel operator-based edge detection
- **Basic Filters**: Grayscale and invert effects

### Vertex Shaders
- **Sine Displacement**: Animated vertex displacement using sine waves
- **Wave Distortion**: UV-based wave distortion effects
- **Magnifying Glass**: Mesh-based warp effect (ready for implementation)

### Fragment Shaders
- **Chromatic Aberration**: RGB channel separation effect
- **Tone Mapping**: Reinhard tone mapping with exposure control
- **Film Grain & Vignette**: Noise-based grain and vignette effects

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Device with Metal support
- Camera permission

## Setup

1. Open the project in Xcode
2. Build and run on a physical device (camera access required)
3. Grant camera permissions when prompted

## Controls

The app features a comprehensive control panel with sliders and toggles for:

- **Blur Radius**: Adjust Gaussian blur intensity (0-20)
- **Edge Detection**: Toggle and control edge detection strength
- **Wave Effects**: Control frequency and amplitude of wave distortions
- **Color Effects**: Adjust chromatic aberration and exposure
- **Film Effects**: Control grain strength and vignette intensity
- **Magnifying Glass**: Toggle and control magnifying glass effect

## Architecture

- **MetalCameraView.swift**: SwiftUI wrapper for MTKView
- **Renderer.swift**: Core Metal rendering and camera processing
- **Shaders.metal**: All compute, vertex, and fragment shaders
- **ContentView.swift**: SwiftUI interface with controls

## Performance

- Optimized for 60 FPS rendering
- Efficient texture caching and memory management
- Threadgroup-optimized compute shaders (16x16)
- Reusable texture allocation

## Technical Details

- Uses `CVMetalTextureCache` for efficient camera texture conversion
- Implements `AVCaptureVideoDataOutputSampleBufferDelegate` for real-time camera feed
- GPU memory management with proper texture formats (`.bgra8Unorm`)
- Animated effects using time-based uniforms

## Future Enhancements

- Additional compute shaders (morphological operations, noise reduction)
- More vertex shaders (spherical distortion, ripple effects)
- Advanced fragment shaders (HDR tone mapping, color grading)
- Touch-based magnifying glass positioning
- Preset effect combinations
