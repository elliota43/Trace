//
//  ContextCaptureService.swift
//  Trace
//
//  Created by Elliot Anderson on 1/19/26.
//

import Foundation

// MARK: - Protocol

protocol ContextCaptureService: Sendable {
    func captureContext(for appName: String) async -> CapturedContext
}

// MARK: - Implementation

final class ContextCaptureServiceImpl: ContextCaptureService {
    private let gitProvider: GitContextProvider

    init(gitProvider: GitContextProvider = GitContextProviderImpl()) {
        self.gitProvider = gitProvider
    }

    func captureContext(for appName: String) async -> CapturedContext {
        // Run all providers in parallel with timeout protection
        async let git = gitProvider.captureContext()

        return await CapturedContext(
            git: git,
            // Defaults for other contexts (can be expanded later)
            browser: BrowserContext(),
            ide: IDEContext(),
            system: SystemContext(),
            design: DesignContext(),
            communication: CommunicationContext(),
            development: DevelopmentContext(),
            visual: VisualContext(),
            temporal: TemporalContext(),
            media: MediaContext()
        )
    }
}
