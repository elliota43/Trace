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
    
    var sharedModelContainer: ModelContainer = {
        // DEV FLAG
        let storedInMemory = true

        let schema = Schema([
            ScreenshotItem.self,
        ])
        
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: storedInMemory)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        MenuBarExtra("Trace", systemImage: "camera.fill") {
            MenuBarView(captureEngine: captureEngine, sharedModelContainer: sharedModelContainer)
        }
        .menuBarExtraStyle(.menu)
        
        WindowGroup(id: "gallery") {
            GalleryView()
                .modelContainer(sharedModelContainer)
        }
    }
}

struct MenuBarView: View {
    @ObservedObject var captureEngine: CaptureEngine
    let sharedModelContainer: ModelContainer
    
    @Environment(\.openWindow) var openWindow
    
    var body: some View {
        Button(captureEngine.isCapturing ? "Capturing..." : "Capture Screen") {
            Task {
                if let result = await captureEngine.capture() {
                    let newItem = ScreenshotItem(
                        appName: result.appName,
                        text: result.text,
                        imageData: result.imageData,
                        url: result.url
                    )
                    
                    Task { @MainActor in
                        sharedModelContainer.mainContext.insert(newItem)
                    }
                }
            }
        }
        .disabled(captureEngine.isCapturing)
        
        Divider()
        
        Button("Open Gallery") {
            openWindow(id: "gallery")
        }
        .keyboardShortcut("o")
        
        Divider()
        
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}
