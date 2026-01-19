//
//  OnboardingView.swift
//  Trace
//
//  Created by Elliot Anderson on 1/19/26.
//

import SwiftUI
import AppKit

struct OnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var allPermissionsGranted: Bool {
        viewModel.allPermissionsGranted
    }

    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.09, blue: 0.15),
                    Color(red: 0.25, green: 0.1, blue: 0.35),
                    Color(red: 0.07, green: 0.09, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress Indicator
                if viewModel.currentStep != .welcome && viewModel.currentStep != .complete {
                    progressIndicator
                        .padding(.top, 60)
                        .padding(.horizontal, 60)
                        .padding(.bottom, 20)
                } else {
                    // Spacer for welcome/complete screens
                    Spacer()
                        .frame(height: 60)
                }

                // Content
                ScrollView {
                    Group {
                        switch viewModel.currentStep {
                        case .welcome:
                            welcomeView
                        case .screenRecording:
                            screenRecordingView
                        case .accessibility:
                            accessibilityView
                        case .automation:
                            automationView
                        case .hotkey:
                            hotkeyView
                        case .complete:
                            completeView
                        }
                    }
                    .frame(maxWidth: 600)
                    .padding(.vertical, 20)
                }

                Spacer()
                    .frame(minHeight: 20)

                // Navigation Buttons
                navigationButtons
                    .padding(.bottom, 40)
            }
        }
        .frame(width: 800, height: 650)
        .onAppear {
            checkPermissions()
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 12) {
            ForEach([OnboardingStep.screenRecording, .accessibility, .automation, .hotkey], id: \.self) { step in
                HStack(spacing: 8) {
                    // Dot
                    Circle()
                        .fill(viewModel.currentStep.rawValue >= step.rawValue ? Color.purple : Color.white.opacity(0.3))
                        .frame(width: 12, height: 12)

                    // Label
                    if step != .hotkey {
                        Rectangle()
                            .fill(viewModel.currentStep.rawValue > step.rawValue ? Color.purple : Color.white.opacity(0.2))
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    // MARK: - Welcome View

    private var welcomeView: some View {
        VStack(spacing: 32) {
            // Logo/Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple, Color.pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.purple.opacity(0.5), radius: 30)

                Image(systemName: "camera.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }

            VStack(spacing: 16) {
                Text("Welcome to Trace")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)

                Text("The intelligent screenshot manager that captures context, not just pixels")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 500)
            }

            VStack(spacing: 16) {
                FeatureRow(icon: "brain", title: "Smart Context Capture", description: "Automatically captures git branches, browser tabs, and active files")
                FeatureRow(icon: "magnifyingglass", title: "Powerful Search", description: "Find screenshots by content, app, or project")
                FeatureRow(icon: "lock.shield", title: "Privacy First", description: "Smart redaction keeps sensitive data safe")
            }
            .padding(.top, 24)
        }
    }

    // MARK: - Screen Recording View

    private var screenRecordingView: some View {
        VStack(spacing: 32) {
            PermissionHeader(
                icon: "rectangle.on.rectangle",
                title: "Screen Recording",
                description: "Required to capture screenshots",
                isGranted: viewModel.screenRecordingGranted
            )

            if !viewModel.screenRecordingGranted {
                VStack(spacing: 24) {
                    InstructionStep(
                        number: 1,
                        text: "Click 'Open System Settings' below"
                    )
                    InstructionStep(
                        number: 2,
                        text: "Find 'Trace' in the list and toggle it ON"
                    )
                    InstructionStep(
                        number: 3,
                        text: "Return here and click 'Check Permission'"
                    )

                    Button(action: openScreenRecordingSettings) {
                        HStack {
                            Image(systemName: "gear")
                            Text("Open System Settings")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.purple)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    Button(action: checkPermissions) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Check Permission")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: 400)
            } else {
                PermissionGrantedView()
            }
        }
    }

    // MARK: - Accessibility View

    private var accessibilityView: some View {
        VStack(spacing: 32) {
            PermissionHeader(
                icon: "hand.point.up.left",
                title: "Accessibility",
                description: "Required to capture window titles and active applications",
                isGranted: viewModel.accessibilityGranted
            )

            if !viewModel.accessibilityGranted {
                VStack(spacing: 24) {
                    InstructionStep(
                        number: 1,
                        text: "Click 'Open System Settings' below"
                    )
                    InstructionStep(
                        number: 2,
                        text: "Find 'Trace' in the list and toggle it ON"
                    )
                    InstructionStep(
                        number: 3,
                        text: "You may need to restart Trace"
                    )

                    Button(action: openAccessibilitySettings) {
                        HStack {
                            Image(systemName: "gear")
                            Text("Open System Settings")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.purple)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    Button(action: checkPermissions) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Check Permission")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: 400)
            } else {
                PermissionGrantedView()
            }
        }
    }

    // MARK: - Automation View

    private var automationView: some View {
        VStack(spacing: 32) {
            PermissionHeader(
                icon: "applescript",
                title: "Automation",
                description: "Required to capture context from browsers and IDEs",
                isGranted: viewModel.automationGranted
            )

            if !viewModel.automationGranted {
                VStack(spacing: 24) {
                    InstructionStep(
                        number: 1,
                        text: "Click 'Open System Settings' below"
                    )
                    InstructionStep(
                        number: 2,
                        text: "Find 'Trace' in the list and enable apps like Safari, Chrome, VS Code"
                    )
                    InstructionStep(
                        number: 3,
                        text: "Return here when done"
                    )

                    Button(action: openAutomationSettings) {
                        HStack {
                            Image(systemName: "gear")
                            Text("Open System Settings")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.purple)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        viewModel.automationGranted = true
                    }) {
                        HStack {
                            Image(systemName: "checkmark")
                            Text("I've Enabled Automation")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: 400)
            } else {
                PermissionGrantedView()
            }
        }
    }

    // MARK: - Hotkey View

    private var hotkeyView: some View {
        VStack(spacing: 32) {
            PermissionHeader(
                icon: "command",
                title: "Global Hotkey",
                description: "Quickly capture screenshots from anywhere",
                isGranted: viewModel.hotkeyRegistered && viewModel.hotkeyTested
            )

            if !viewModel.hotkeyRegistered {
                VStack(spacing: 24) {
                    Text("We'll register ⌘⇧5 (Cmd+Shift+5) as your global hotkey")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)

                    Button(action: {
                        let success = HotKeyManager.shared.registerHotKey()
                        viewModel.hotkeyRegistered = success
                    }) {
                        HStack {
                            Image(systemName: "keyboard")
                            Text("Register Hotkey")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.purple)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: 400)
            } else if !viewModel.hotkeyTested {
                VStack(spacing: 24) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.green)

                        Text("Hotkey registered successfully!")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(12)

                    VStack(spacing: 16) {
                        Text("Test it out!")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)

                        Text("Press ⌘⇧5 on your keyboard now")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.7))

                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                                .frame(height: 60)

                            HStack(spacing: 8) {
                                KeyCap(symbol: "⌘")
                                Text("+")
                                    .foregroundColor(.white.opacity(0.5))
                                KeyCap(symbol: "⇧")
                                Text("+")
                                    .foregroundColor(.white.opacity(0.5))
                                KeyCap(symbol: "5")
                            }
                        }
                        .frame(maxWidth: 300)

                        Button(action: {
                            viewModel.hotkeyTested = true
                        }) {
                            Text("I tested it, continue →")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: 400)
            } else {
                PermissionGrantedView()
            }
        }
        .onAppear {
            // Set up hotkey handler to mark as tested
            HotKeyManager.shared.onScreenshot = {
                Task { @MainActor in
                    viewModel.hotkeyTested = true
                }
            }
        }
    }

    // MARK: - Complete View

    private var completeView: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.green.opacity(0.5), radius: 30)

                Image(systemName: "checkmark")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 16) {
                Text("All Set!")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)

                Text("Trace is ready to capture intelligent screenshots with rich context")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 500)
            }

            VStack(spacing: 12) {
                QuickTipRow(icon: "command", text: "Press ⌘⇧5 anywhere to capture")
                QuickTipRow(icon: "folder", text: "Browse captures in Smart Folders")
                QuickTipRow(icon: "magnifyingglass", text: "Search by content or context")
                QuickTipRow(icon: "sparkles", text: "Deep context captured automatically")
            }
            .padding(.top, 24)
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if viewModel.currentStep != .welcome && viewModel.currentStep != .complete {
                Button(action: previousStep) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if viewModel.currentStep == .complete {
                Button(action: completeOnboarding) {
                    HStack {
                        Text("Get Started")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.purple)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            } else {
                Button(action: nextStep) {
                    HStack {
                        Text(viewModel.currentStep == .welcome ? "Get Started" : "Continue")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(canProceed ? Color.purple : Color.white.opacity(0.2))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .disabled(!canProceed)
            }
        }
        .padding(.horizontal, 60)
    }

    // MARK: - Helper Functions

    private var canProceed: Bool {
        switch viewModel.currentStep {
        case .welcome:
            return true
        case .screenRecording:
            return viewModel.screenRecordingGranted
        case .accessibility:
            return viewModel.accessibilityGranted
        case .automation:
            return viewModel.automationGranted
        case .hotkey:
            return viewModel.hotkeyRegistered && viewModel.hotkeyTested
        case .complete:
            return true
        }
    }

    private func nextStep() {
        if viewModel.currentStep == .hotkey {
            viewModel.currentStep = .complete
        } else if let nextStep = OnboardingStep(rawValue: viewModel.currentStep.rawValue + 1) {
            viewModel.currentStep = nextStep
        }
    }

    private func previousStep() {
        if let previousStep = OnboardingStep(rawValue: viewModel.currentStep.rawValue - 1),
           previousStep != .welcome {
            viewModel.currentStep = previousStep
        }
    }

    private func checkPermissions() {
        viewModel.screenRecordingGranted = PermissionsManager.checkScreenRecordingPermission()
        viewModel.accessibilityGranted = PermissionsManager.checkAccessibilityPermission()
        // Automation is checked manually
    }

    private func openScreenRecordingSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
    }

    private func openAccessibilitySettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }

    private func openAutomationSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!)
    }

    private func completeOnboarding() {
        // Save completion to UserDefaults
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")

        // Close the actual window
        DispatchQueue.main.async {
            // Find and close the onboarding window
            if let window = NSApp.windows.first(where: { window in
                // Check if this is the onboarding window by looking for our view
                window.contentView?.subviews.contains(where: { view in
                    String(describing: type(of: view)).contains("OnboardingView")
                }) ?? false
            }) {
                window.close()
            }
        }
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.purple)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
            }
            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct PermissionHeader: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isGranted ? [Color.green, Color.green.opacity(0.6)] : [Color.purple, Color.pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: (isGranted ? Color.green : Color.purple).opacity(0.5), radius: 20)

                Image(systemName: isGranted ? "checkmark" : icon)
                    .font(.system(size: 36, weight: isGranted ? .bold : .regular))
                    .foregroundColor(.white)
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 450)
            }
        }
    }
}

struct InstructionStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 36, height: 36)

                Text("\(number)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.purple)
            }

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))

            Spacer()
        }
    }
}

struct PermissionGrantedView: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.green)

            Text("Permission granted!")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.green.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

struct QuickTipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.purple)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))

            Spacer()
        }
    }
}

struct KeyCap: View {
    let symbol: String

    var body: some View {
        Text(symbol)
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 44, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 4, y: 2)
    }
}
