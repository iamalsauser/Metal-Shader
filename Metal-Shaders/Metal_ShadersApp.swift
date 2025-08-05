//
//  Metal_ShadersApp.swift
//  Metal-Shaders
//
//  Created by Parth Sinh on 05/08/25.
//

import SwiftUI
import AVFoundation

@main
struct Metal_ShadersApp: App {
    init() {
        // Request camera permission on app launch
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if !granted {
                print("Camera access denied")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
