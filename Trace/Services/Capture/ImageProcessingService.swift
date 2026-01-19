//
//  ImageProcessingService.swift
//  Trace
//
//  Created by Elliot Anderson on 1/19/26.
//

import Foundation
import AppKit

// MARK: - Protocol

protocol ImageProcessingService: Sendable {
    func convertToPNG(_ image: CGImage) async throws -> Data
}

// MARK: - Implementation

final class ImageProcessingServiceImpl: ImageProcessingService {
    func convertToPNG(_ image: CGImage) async throws -> Data {
        // Run image conversion on background thread
        try await Task.detached {
            let nsImage = NSImage(
                cgImage: image,
                size: NSSize(width: image.width, height: image.height)
            )

            guard let tiffData = nsImage.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let pngData = bitmap.representation(using: .png, properties: [:]) else {
                throw ImageProcessingError.conversionFailed
            }

            return pngData
        }.value
    }
}

// MARK: - Errors

enum ImageProcessingError: LocalizedError {
    case conversionFailed

    var errorDescription: String? {
        switch self {
        case .conversionFailed:
            return "Failed to convert image to PNG format"
        }
    }
}
