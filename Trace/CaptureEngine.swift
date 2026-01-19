//
//  CaptureEngine.swift
//  Trace
//
//  Created by Elliot Anderson on 1/18/26.
//

import Foundation
import OSLog
import ScreenCaptureKit
import Combine
import AppKit
import Vision

@MainActor
class CaptureEngine: ObservableObject {
    
    @Published var isCapturing = false
    private let logger = Logger()
    
    func capture() async -> (imageData: Data, text: String, appName: String, url: String?)? {
        isCapturing = true
        defer { isCapturing = false}
        
        do {
            guard PermissionsManager.checkScreenRecordingPermission() else {
                PermissionsManager.requestPermission()
                return nil
            }

            let content = try await SCShareableContent.current
            guard let mainDisplay = content.displays.first else { return nil }
            
            // Detect App
            var activeAppName = "Unknown"
            if let frontApp = NSWorkspace.shared.frontmostApplication {
                activeAppName = frontApp.localizedName ?? "Unknown"
            }
            
            let detectedUrl = await MainActor.run {
                return BrowserIntegration.getCurrentURL(for: activeAppName)
            }
            if let url = detectedUrl {
                print("Captured Link: \(url)")
            }
            
            // Capture
            let filter = SCContentFilter(display: mainDisplay, excludingApplications: [], exceptingWindows: [])
            let config = SCStreamConfiguration()
            config.width = mainDisplay.width
            config.height = mainDisplay.height
            config.showsCursor = true
            
            let cgImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
            
            // OCR
            let extractedText = await recognizeText(from: cgImage)
            
            // Convert to Data (PNG)
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            guard let tiffData = nsImage.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let pngData = bitmap.representation(using: .png, properties: [:]) else {
                return nil
            }
            
            print("✅ Captured: \(activeAppName)")
            return (pngData, extractedText, activeAppName, detectedUrl)
            
        } catch {
            logger.error("Capture failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    nonisolated func recognizeText(from image: CGImage) async -> String {
        return await withCheckedContinuation { continuation in
            
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                    continuation.resume(returning: "")
                    return
                }
                
                // combine into paragraph
                let recognizedStrings = observations.compactMap { observation in
                    return observation.topCandidates(1).first?.string
                }
                
                continuation.resume(returning: recognizedStrings.joined(separator: "\n"))
            }
            
            // Configure for accuracy
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                print("OCR Error: \(error)")
                continuation.resume(returning: "")
            }
        }
    }
}
