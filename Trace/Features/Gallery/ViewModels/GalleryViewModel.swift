//
//  GalleryViewModel.swift
//  Trace
//
//  Created by Elliot Anderson on 1/19/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class GalleryViewModel: ObservableObject {
    // MARK: - Published State

    @Published var searchText: String = ""
    @Published var selectedFolder: SmartFolder?
    @Published private(set) var screenshots: [ScreenshotItem] = []
    @Published private(set) var loadState: LoadState<Void> = .idle

    // MARK: - Dependencies

    private let repository: ScreenshotRepository

    // MARK: - Task Management

    private var loadTask: Task<Void, Never>?

    // MARK: - Computed Properties

    var filteredScreenshots: [ScreenshotItem] {
        var results = screenshots

        // Apply folder filter
        if let folder = selectedFolder {
            results = results.filter(folder.filter)
        }

        // Apply search filter
        if !searchText.isEmpty {
            results = results.filter { item in
                item.recognizedText.localizedStandardContains(searchText)
                    || item.appName.localizedStandardContains(searchText)
            }
        }

        return results
    }

    // MARK: - Initialization

    init(repository: ScreenshotRepository) {
        self.repository = repository
    }

    // MARK: - Actions

    func load() {
        // Prevent multiple simultaneous loads
        guard loadTask == nil else {
            print("⚠️ Load already in progress")
            return
        }

        loadTask = Task { @MainActor in
            defer { loadTask = nil }

            loadState = .loading

            do {
                print("📂 Loading screenshots...")
                let items = try await repository.fetchAll()

                try Task.checkCancellation()

                screenshots = items
                loadState = .success(())
                print("✓ Loaded \(items.count) screenshots")

            } catch is CancellationError {
                print("⚠️ Load cancelled")
            } catch {
                print("❌ Load failed: \(error)")
                loadState = .failure(SendableError(error: error))
            }
        }
    }

    func delete(_ item: ScreenshotItem) async throws {
        print("🗑️ Deleting screenshot: \(item.id)")
        try await repository.delete(item)
        screenshots.removeAll { $0.id == item.id }
    }

    func exportImage(_ item: ScreenshotItem) async throws -> URL {
        print("💾 Exporting screenshot: \(item.smartTitle)")
        return try await repository.export(item)
    }

    deinit {
        print("🗑️ GalleryViewModel deallocated")
        loadTask?.cancel()
    }
}
