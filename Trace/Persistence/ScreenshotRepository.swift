//
//  ScreenshotRepository.swift
//  Trace
//
//  Created by Elliot Anderson on 1/19/26.
//

import Foundation
import SwiftData
import AppKit
import UniformTypeIdentifiers

// MARK: - Protocol

protocol ScreenshotRepository: Sendable {
    func save(_ result: CaptureResult) async throws
    func fetchAll() async throws -> [ScreenshotItem]
    func delete(_ item: ScreenshotItem) async throws
    func export(_ item: ScreenshotItem) async throws -> URL
}

// MARK: - Implementation

final class ScreenshotRepositoryImpl: ScreenshotRepository {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    @MainActor
    func save(_ result: CaptureResult) async throws {
        let newItem = ScreenshotItem(
            appName: result.appName,
            text: result.recognizedText,
            imageData: result.imageData,
            url: nil,
            context: result.context,
            textBounds: result.textBounds
        )

        modelContainer.mainContext.insert(newItem)
        try modelContainer.mainContext.save()
    }

    @MainActor
    func fetchAll() async throws -> [ScreenshotItem] {
        let descriptor = FetchDescriptor<ScreenshotItem>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try modelContainer.mainContext.fetch(descriptor)
    }

    @MainActor
    func delete(_ item: ScreenshotItem) async throws {
        modelContainer.mainContext.delete(item)
        try modelContainer.mainContext.save()
    }

    @MainActor
    func export(_ item: ScreenshotItem) async throws -> URL {
        guard let imageData = item.imageData,
              let nsImage = NSImage(data: imageData) else {
            throw RepositoryError.noImageData
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "\(item.smartTitle).png"

        let response = await panel.begin()
        guard response == .OK, let url = panel.url else {
            throw RepositoryError.exportCancelled
        }

        guard let tiffData = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw RepositoryError.conversionFailed
        }

        try pngData.write(to: url)
        return url
    }
}

// MARK: - Errors

enum RepositoryError: LocalizedError {
    case noImageData
    case exportCancelled
    case conversionFailed

    var errorDescription: String? {
        switch self {
        case .noImageData: return "No image data available"
        case .exportCancelled: return "Export was cancelled"
        case .conversionFailed: return "Failed to convert image"
        }
    }
}

// MARK: - Capture Result

struct CaptureResult: Sendable {
    let imageData: Data
    let recognizedText: String
    let textBounds: [TextBound]
    let appName: String
    let context: CapturedContext
}
