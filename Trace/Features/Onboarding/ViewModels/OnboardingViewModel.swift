//
//  OnboardingViewModel.swift
//  Trace
//
//  Created by Elliot Anderson on 1/19/26.
//

import Foundation
import SwiftUI
import AppKit
import Combine
import Carbon

@MainActor
final class OnboardingViewModel: ObservableObject {
    // MARK: - Published State

    @Published var currentStep: OnboardingStep = .welcome
    @Published var screenRecordingGranted = false
    @Published var accessibilityGranted = false
    @Published var automationGranted = false
    @Published var hotkeyRegistered = false
    @Published var hotkeyTested = false

    // MARK: - Dependencies

    private let permissionsService: PermissionsService
    private let hotkeyService: HotkeyService

    // MARK: - Computed Properties

    var allPermissionsGranted: Bool {
        screenRecordingGranted && accessibilityGranted && automationGranted
    }

    var canProceed: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .screenRecording:
            return screenRecordingGranted
        case .accessibility:
            return accessibilityGranted
        case .automation:
            return automationGranted
        case .hotkey:
            return hotkeyRegistered && hotkeyTested
        case .complete:
            return true
        }
    }

    // MARK: - Initialization

    init(
        permissionsService: PermissionsService,
        hotkeyService: HotkeyService
    ) {
        self.permissionsService = permissionsService
        self.hotkeyService = hotkeyService
    }

    // MARK: - Actions

    func checkPermissions() {
        screenRecordingGranted = permissionsService.checkScreenRecording()
        accessibilityGranted = permissionsService.checkAccessibility()
    }

    func nextStep() {
        if currentStep == .hotkey {
            currentStep = .complete
        } else if let next = OnboardingStep(rawValue: currentStep.rawValue + 1) {
            currentStep = next
        }
    }

    func previousStep() {
        if let previous = OnboardingStep(rawValue: currentStep.rawValue - 1),
           previous != .welcome {
            currentStep = previous
        }
    }

    func registerHotkey() {
        hotkeyRegistered = hotkeyService.register(
            keyCode: UInt32(kVK_ANSI_5),
            modifiers: UInt32(cmdKey | shiftKey)
        ) { [weak self] in
            Task { @MainActor in
                self?.hotkeyTested = true
            }
        }
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        closeOnboardingWindow()
    }

    func openScreenRecordingSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
    }

    func openAccessibilitySettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }

    func openAutomationSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!)
    }

    // MARK: - Private Helpers

    private func closeOnboardingWindow() {
        DispatchQueue.main.async {
            if let window = NSApp.windows.first(where: { window in
                window.contentView?.subviews.contains(where: { view in
                    String(describing: type(of: view)).contains("OnboardingView")
                }) ?? false
            }) {
                window.close()
            }
        }
    }

    deinit {
        print("🗑️ OnboardingViewModel deallocated")
    }
}

// MARK: - Onboarding Step

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case screenRecording
    case accessibility
    case automation
    case hotkey
    case complete
}
