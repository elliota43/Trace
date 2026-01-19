//
//  TraceApp.swift
//  Trace
//
//  Created by Elliot Anderson on 1/18/26.
//

import SwiftUI
import AppKit
import SwiftData

@main
struct TraceApp: App {
    
    @StateObject var captureEngine = CaptureEngine()
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some Scene {
        MenuBarExtra("Trace", systemImage: "camera.fill") {
            Button(captureEngine.isCapturing ? "Capturing..." : "Capture Screen") {
                Task {
                    if let result = await captureEngine.capture() {
                        let newItem = ScreenshotItem(
                            appName: result.appName,
                            text: result.text,
                            imageData: result.imageData
                        )
                        
                        Task { @MainActor in
                            modelContext.insert(newItem)
                            try? modelContext.save()
                            print("💾 Saved to Database!")
                        }
                    }
                }
            }
            .disabled(captureEngine.isCapturing)
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .menuBarExtraStyle(.menu)
        .modelContainer(for: ScreenshotItem.self)
    }
}
