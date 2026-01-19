//
//  DependencyContainer.swift
//  Trace
//
//  Created by Elliot Anderson on 1/19/26.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
final class DependencyContainer: ObservableObject {
    // MARK: - Singletons (Stateful Services)

    let modelContainer: ModelContainer
    let hotkeyService: HotkeyService

    // MARK: - Stateless Services (Lazy initialized)

    private lazy var screenCaptureService: ScreenCaptureService = {
        ScreenCaptureServiceImpl()
    }()

    private lazy var ocrService: OCRService = {
        VisionOCRService()
    }()

    private lazy var contextService: ContextCaptureService = {
        ContextCaptureServiceImpl()
    }()

    private lazy var imageProcessor: ImageProcessingService = {
        ImageProcessingServiceImpl()
    }()

    private lazy var repository: ScreenshotRepository = {
        ScreenshotRepositoryImpl(modelContainer: modelContainer)
    }()

    private lazy var permissionsService: PermissionsService = {
        PermissionsServiceImpl()
    }()

    // MARK: - Initialization

    init() {
        print("🔧 Initializing DependencyContainer...")

        // Setup SwiftData
        let schema = Schema([ScreenshotItem.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            self.modelContainer = try ModelContainer(for: schema, configurations: [config])
            print("✓ ModelContainer initialized")
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        // Initialize hotkey service
        self.hotkeyService = CarbonHotkeyService()
        print("✓ HotkeyService initialized")
    }

    // MARK: - Factory Methods

    func makeCaptureFlowViewModel() -> CaptureFlowViewModel {
        CaptureFlowViewModel(
            screenCaptureService: screenCaptureService,
            ocrService: ocrService,
            contextService: contextService,
            imageProcessor: imageProcessor,
            repository: repository
        )
    }

    func makeGalleryViewModel() -> GalleryViewModel {
        GalleryViewModel(repository: repository)
    }

    func makeOnboardingViewModel() -> OnboardingViewModel {
        OnboardingViewModel(
            permissionsService: permissionsService,
            hotkeyService: hotkeyService
        )
    }

    deinit {
        print("🗑️ DependencyContainer deallocated")
    }
}
