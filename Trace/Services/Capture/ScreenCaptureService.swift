//
//  ScreenCaptureService.swift
//  Trace
//
//  Created by Elliot Anderson on 1/19/26.
//

import Foundation
import ScreenCaptureKit
import AppKit

// MARK: - Protocol

protocol ScreenCaptureService: Sendable {
    func captureFullScreen() async throws -> CGImage
    func captureWindow(_ window: SCWindow) async throws -> CGImage
}

// MARK: - Implementation

final class ScreenCaptureServiceImpl: ScreenCaptureService {
    func captureFullScreen() async throws -> CGImage {
        let content = try await SCShareableContent.current
        guard let mainDisplay = content.displays.first else {
            throw CaptureError.noDisplayFound
        }

        let filter = SCContentFilter(
            display: mainDisplay,
            excludingApplications: [],
            exceptingWindows: []
        )
        let config = SCStreamConfiguration()
        config.width = mainDisplay.width
        config.height = mainDisplay.height
        config.showsCursor = true

        return try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: config
        )
    }

    func captureWindow(_ window: SCWindow) async throws -> CGImage {
        let filter = SCContentFilter(desktopIndependentWindow: window)
        let config = SCStreamConfiguration()
        config.width = Int(window.frame.width) * 2 // Retina
        config.height = Int(window.frame.height) * 2
        config.showsCursor = false

        return try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: config
        )
    }
}

// MARK: - Errors

enum CaptureError: LocalizedError {
    case noDisplayFound
    case capturePermissionDenied
    case noWindowProvided
    case videoNotSupported
    case captureFailed(Error)

    var errorDescription: String? {
        switch self {
        case .noDisplayFound:
            return "No display available for capture"
        case .capturePermissionDenied:
            return "Screen recording permission not granted"
        case .noWindowProvided:
            return "No window selected for capture"
        case .videoNotSupported:
            return "Video capture not yet supported"
        case .captureFailed(let error):
            return "Capture failed: \(error.localizedDescription)"
        }
    }
}
