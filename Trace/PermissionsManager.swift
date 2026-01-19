//
//  PermissionsManager.swift
//  Trace
//
//  Created by Elliot Anderson on 1/18/26.
//

import Foundation
import CoreGraphics
import ApplicationServices

class PermissionsManager {
    static func checkScreenRecordingPermission() -> Bool {
        return CGPreflightScreenCaptureAccess()
    }

    static func requestPermission() {
        CGRequestScreenCaptureAccess()
    }

    static func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    static func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    static func checkAllPermissions() -> (screenRecording: Bool, accessibility: Bool) {
        return (
            screenRecording: checkScreenRecordingPermission(),
            accessibility: checkAccessibilityPermission()
        )
    }

    static func needsOnboarding() -> Bool {
        let hasCompleted = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        let permissions = checkAllPermissions()
        return !hasCompleted || !permissions.screenRecording || !permissions.accessibility
    }
}
