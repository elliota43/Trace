//
//  CaptureFlowViewModel.swift
//  Trace
//
//  Created by Elliot Anderson on 1/19/26.
//

import Foundation
import ScreenCaptureKit
import SwiftUI
import Combine

@MainActor
final class CaptureFlowViewModel: ObservableObject {
    // MARK: - Published State

    @Published private(set) var captureState: LoadState<CaptureResult> = .idle
    @Published private(set) var availableWindows: [SCWindow] = []

    // MARK: - Dependencies (Injected)

    private let screenCaptureService: ScreenCaptureService
    private let ocrService: OCRService
    private let contextService: ContextCaptureService
    private let imageProcessor: ImageProcessingService
    private let repository: ScreenshotRepository

    // MARK: - Task Management (Prevent Races)

    private var captureTask: Task<Void, Never>?
    private var windowLoadTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        screenCaptureService: ScreenCaptureService,
        ocrService: OCRService,
        contextService: ContextCaptureService,
        imageProcessor: ImageProcessingService,
        repository: ScreenshotRepository
    ) {
        self.screenCaptureService = screenCaptureService
        self.ocrService = ocrService
        self.contextService = contextService
        self.imageProcessor = imageProcessor
        self.repository = repository
    }

    // MARK: - Public Actions

    func capture(mode: CaptureMode, window: SCWindow? = nil) {
        // Cancel any in-flight capture to prevent race
        captureTask?.cancel()

        captureTask = Task { @MainActor in
            captureState = .loading

            do {
                print("🎬 Starting capture with mode: \(mode)")
                let result = try await performCapture(mode: mode, window: window)

                // Check cancellation before updating state
                try Task.checkCancellation()

                captureState = .success(result)
                print("✅ Capture completed successfully")

                // Save to repository
                try await repository.save(result)

            } catch is CancellationError {
                // Swallow cancellation, keep previous state
                print("⚠️ Capture cancelled")
            } catch {
                print("❌ Capture failed: \(error)")
                captureState = .failure(SendableError(error: error))
            }
        }
    }

    func loadAvailableWindows() {
        windowLoadTask?.cancel()

        windowLoadTask = Task { @MainActor in
            do {
                print("📱 Loading available windows...")
                let content = try await SCShareableContent.excludingDesktopWindows(
                    false,
                    onScreenWindowsOnly: true
                )

                try Task.checkCancellation()

                let filtered = content.windows.filter { window in
                    guard let app = window.owningApplication else { return false }
                    let systemApps = ["com.apple.dock", "com.apple.systemuiserver", "com.apple.WindowManager"]
                    return !systemApps.contains(app.bundleIdentifier)
                        && window.title?.isEmpty == false
                }

                availableWindows = filtered
                print("✓ Loaded \(filtered.count) windows")

            } catch is CancellationError {
                print("⚠️ Window load cancelled")
            } catch {
                print("❌ Failed to load windows: \(error)")
            }
        }
    }

    func cancelCapture() {
        captureTask?.cancel()
        captureTask = nil
        captureState = .idle
    }

    // MARK: - Private Helpers

    private func performCapture(
        mode: CaptureMode,
        window: SCWindow?
    ) async throws -> CaptureResult {
        // 1. Capture screen image
        print("📸 Capturing image...")
        let cgImage: CGImage
        switch mode {
        case .fullScreen:
            cgImage = try await screenCaptureService.captureFullScreen()
        case .window:
            guard let window = window else {
                throw CaptureError.noWindowProvided
            }
            cgImage = try await screenCaptureService.captureWindow(window)
        case .region:
            // TODO: Implement region picker
            print("⚠️ Region capture using full screen for now")
            cgImage = try await screenCaptureService.captureFullScreen()
        case .video:
            throw CaptureError.videoNotSupported
        }

        // 2. Run OCR and context capture in parallel
        print("🔤 Running OCR and context capture...")
        async let ocrResult = ocrService.recognizeText(in: cgImage)
        async let context = contextService.captureContext(
            for: NSWorkspace.shared.frontmostApplication?.localizedName ?? "Unknown"
        )

        let (ocr, capturedContext) = try await (ocrResult, context)
        print("✓ OCR found \(ocr.textBounds.count) text regions")

        // 3. Process image to PNG
        print("💾 Converting to PNG...")
        let imageData = try await imageProcessor.convertToPNG(cgImage)

        // 4. Build result
        return CaptureResult(
            imageData: imageData,
            recognizedText: ocr.fullText,
            textBounds: ocr.textBounds,
            appName: NSWorkspace.shared.frontmostApplication?.localizedName ?? "Unknown",
            context: capturedContext
        )
    }

    // MARK: - Cleanup

    deinit {
        print("🗑️ CaptureFlowViewModel deallocated")
        captureTask?.cancel()
        windowLoadTask?.cancel()
    }
}
