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
    @Published var isRecording = false
    private let logger = Logger()
    private var stream: SCStream?
    private var recordingFrames: [CGImage] = []

    func capture(mode: CaptureMode = .fullScreen, window: SCWindow? = nil) async -> (imageData: Data, text: String, appName: String, url: String?, context: CapturedContext?, textBounds: [TextBound])? {
        print("🎬 Starting capture with mode: \(mode)")
        isCapturing = true
        defer {
            isCapturing = false
            print("✅ Capture completed")
        }

        do {
            guard PermissionsManager.checkScreenRecordingPermission() else {
                print("⚠️ Screen recording permission not granted")
                PermissionsManager.requestPermission()
                return nil
            }

            print("📱 Getting shareable content...")
            let content = try await SCShareableContent.current
            guard let mainDisplay = content.displays.first else {
                print("❌ No display found")
                return nil
            }

            // Detect App
            var activeAppName = "Unknown"
            if let frontApp = NSWorkspace.shared.frontmostApplication {
                activeAppName = frontApp.localizedName ?? "Unknown"
            }
            print("🎯 Active app: \(activeAppName)")

            // Temporarily disable deep context capture to fix freezing issue
            print("⚠️ Skipping deep context capture (temporarily disabled)")
            let capturedContext = CapturedContext(
                git: GitContext(), browser: BrowserContext(), ide: IDEContext(),
                system: SystemContext(), design: DesignContext(), communication: CommunicationContext(),
                development: DevelopmentContext(), visual: VisualContext(),
                temporal: TemporalContext(), media: MediaContext()
            )

            print("🔗 Detecting URL...")
            let detectedUrl = await MainActor.run {
                return BrowserIntegration.getCurrentURL(for: activeAppName)
            }
            if let url = detectedUrl {
                print("✓ Captured Link: \(url)")
            } else {
                print("ℹ️ No URL detected")
            }

            // Print context summary
            print("📊 Generating context summary...")
            printContextSummary(capturedContext)

            // Capture based on mode
            print("📸 Capturing image with mode: \(mode)")
            let cgImage: CGImage
            switch mode {
            case .fullScreen:
                print("📺 Full screen capture")
                let filter = SCContentFilter(display: mainDisplay, excludingApplications: [], exceptingWindows: [])
                let config = SCStreamConfiguration()
                config.width = mainDisplay.width
                config.height = mainDisplay.height
                config.showsCursor = true
                cgImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
                print("✓ Full screen captured")

            case .window:
                print("🪟 Window capture")
                guard let window = window else {
                    print("❌ No window provided")
                    return nil
                }
                let filter = SCContentFilter(desktopIndependentWindow: window)
                let config = SCStreamConfiguration()
                config.width = Int(window.frame.width) * 2 // Retina
                config.height = Int(window.frame.height) * 2
                config.showsCursor = false
                cgImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
                print("✓ Window captured")

            case .region:
                print("✂️ Region capture (using full screen for now)")
                // TODO: Implement region selection
                let filter = SCContentFilter(display: mainDisplay, excludingApplications: [], exceptingWindows: [])
                let config = SCStreamConfiguration()
                config.width = mainDisplay.width
                config.height = mainDisplay.height
                config.showsCursor = true
                cgImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
                print("✓ Region captured")

            case .video:
                print("🎥 Video recording not implemented yet")
                // TODO: Implement video recording
                return nil
            }

            // OCR with text bounds
            print("🔤 Starting OCR...")
            let (extractedText, textBounds) = await recognizeTextWithBounds(from: cgImage)
            print("✓ OCR completed, found \(textBounds.count) text regions")

            // Convert to Data (PNG)
            print("💾 Converting to PNG...")
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            guard let tiffData = nsImage.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let pngData = bitmap.representation(using: .png, properties: [:]) else {
                print("❌ Failed to convert image to PNG")
                return nil
            }

            print("✅ Capture complete for: \(activeAppName)")
            return (pngData, extractedText, activeAppName, detectedUrl, capturedContext, textBounds)

        } catch {
            logger.error("Capture failed: \(error.localizedDescription)")
            return nil
        }
    }

    private func printContextSummary(_ context: CapturedContext) {
        var summary: [String] = []

        if let branch = context.git.branch {
            summary.append("📌 Git: \(branch)")
        }
        if let file = context.ide.activeFile {
            summary.append("📄 File: \(file)")
        }
        if let ports = context.development.localhostPorts {
            summary.append("🌐 Ports: \(ports)")
        }
        if let track = context.media.spotifyTrack {
            summary.append("🎵 Playing: \(track)")
        }
        if let timeOfDay = context.temporal.timeOfDay {
            summary.append("⏰ Time: \(timeOfDay)")
        }

        if !summary.isEmpty {
            print("📋 Context: \(summary.joined(separator: " | "))")
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

    nonisolated func recognizeTextWithBounds(from image: CGImage) async -> (String, [TextBound]) {
        return await withCheckedContinuation { continuation in

            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                    continuation.resume(returning: ("", []))
                    return
                }

                var recognizedStrings: [String] = []
                var textBounds: [TextBound] = []

                let imageWidth = Double(image.width)
                let imageHeight = Double(image.height)

                for observation in observations {
                    guard let candidate = observation.topCandidates(1).first else { continue }

                    recognizedStrings.append(candidate.string)

                    // Get bounding box (normalized coordinates)
                    let boundingBox = observation.boundingBox

                    // Convert to pixel coordinates
                    // Vision uses bottom-left origin, we need top-left
                    let x = boundingBox.origin.x * imageWidth
                    let y = (1 - boundingBox.origin.y - boundingBox.height) * imageHeight
                    let width = boundingBox.width * imageWidth
                    let height = boundingBox.height * imageHeight

                    textBounds.append(TextBound(
                        text: candidate.string,
                        x: x,
                        y: y,
                        width: width,
                        height: height
                    ))
                }

                continuation.resume(returning: (recognizedStrings.joined(separator: "\n"), textBounds))
            }

            // Configure for accuracy
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: image, options: [:])

            do {
                try handler.perform([request])
            } catch {
                print("OCR Error: \(error)")
                continuation.resume(returning: ("", []))
            }
        }
    }
}
