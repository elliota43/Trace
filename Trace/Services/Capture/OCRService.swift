//
//  OCRService.swift
//  Trace
//
//  Created by Elliot Anderson on 1/19/26.
//

import Foundation
import Vision
import AppKit

// MARK: - Protocol

protocol OCRService: Sendable {
    func recognizeText(in image: CGImage) async throws -> OCRResult
}

// MARK: - Models

struct OCRResult: Sendable {
    let fullText: String
    let textBounds: [TextBound]
}

struct TextBound: Codable, Sendable {
    let text: String
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}

// MARK: - Implementation

final class VisionOCRService: OCRService {
    func recognizeText(in image: CGImage) async throws -> OCRResult {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: OCRResult(fullText: "", textBounds: []))
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
                        x: x, y: y,
                        width: width, height: height
                    ))
                }

                let result = OCRResult(
                    fullText: recognizedStrings.joined(separator: "\n"),
                    textBounds: textBounds
                )
                continuation.resume(returning: result)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: image, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
