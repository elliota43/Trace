//
//  PermissionsService.swift
//  Trace
//
//  Created by Elliot Anderson on 1/19/26.
//

import Foundation
import ScreenCaptureKit
import AppKit

// MARK: - Protocol

protocol PermissionsService: Sendable {
    func checkScreenRecording() -> Bool
    func checkAccessibility() -> Bool
    func requestScreenRecording()
    func needsOnboarding() -> Bool
}

// MARK: - Implementation

final class PermissionsServiceImpl: PermissionsService {
    func checkScreenRecording() -> Bool {
        CGPreflightScreenCaptureAccess()
    }

    func checkAccessibility() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    func requestScreenRecording() {
        CGRequestScreenCaptureAccess()
    }

    func needsOnboarding() -> Bool {
        let hasCompleted = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        return !hasCompleted || !checkScreenRecording() || !checkAccessibility()
    }
}
