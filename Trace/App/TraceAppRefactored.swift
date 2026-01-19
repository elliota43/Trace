//
//  TraceAppRefactored.swift
//  Trace
//
//  Created by Elliot Anderson on 1/19/26.
//

import SwiftUI
import SwiftData
import Carbon

struct TraceAppRefactored: App {
    // Single source of truth for dependencies
    @StateObject private var container = DependencyContainer()
    @State private var showCaptureOptions = false

    var body: some Scene {
        MenuBarExtra("Trace", systemImage: "camera.fill") {
            MenuBarRootView()
                .withDependencies(container)
                .modelContainer(container.modelContainer)
        }
        .menuBarExtraStyle(.menu)

        WindowGroup(id: "gallery") {
            GalleryRootView()
                .withDependencies(container)
                .modelContainer(container.modelContainer)
        }

        WindowGroup(id: "onboarding") {
            OnboardingRootView()
                .withDependencies(container)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .windowStyle(.hiddenTitleBar)

        WindowGroup(id: "captureOptions") {
            CaptureOptionsRootView()
                .withDependencies(container)
        }
    }
}

// MARK: - Menu Bar Root

struct MenuBarRootView: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Group {
            Button("Capture Screen...") {
                openWindow(id: "captureOptions")
            }

            Divider()

            Button("Open Gallery") {
                openWindow(id: "gallery")
            }
            .keyboardShortcut("o")

            Button("Setup & Permissions...") {
                openWindow(id: "onboarding")
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .onAppear {
            setupHotkey()
            checkOnboarding()
        }
    }

    private func setupHotkey() {
        guard let deps = dependencies else { return }

        _ = deps.hotkeyService.register(
            keyCode: UInt32(kVK_ANSI_5),
            modifiers: UInt32(cmdKey | shiftKey)
        ) { [openWindow] in
            Task { @MainActor in
                openWindow(id: "captureOptions")
            }
        }
    }

    private func checkOnboarding() {
        guard let deps = dependencies else { return }

        let viewModel = deps.makeOnboardingViewModel()
        viewModel.checkPermissions()

        if !viewModel.allPermissionsGranted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                openWindow(id: "onboarding")
            }
        }
    }
}

// MARK: - Gallery Root

struct GalleryRootView: View {
    @Environment(\.dependencies) private var dependencies
    @StateObject private var viewModel: GalleryViewModel

    init() {
        // Temporary - will be replaced when dependencies are available
        let tempContainer = DependencyContainer()
        _viewModel = StateObject(wrappedValue: tempContainer.makeGalleryViewModel())
    }

    var body: some View {
        if let deps = dependencies {
            GalleryContentView(viewModel: deps.makeGalleryViewModel())
        }
    }
}

struct GalleryContentView: View {
    @StateObject var viewModel: GalleryViewModel

    var body: some View {
        GalleryView()
            .task {
                viewModel.load()
            }
    }
}

// MARK: - Onboarding Root

struct OnboardingRootView: View {
    @Environment(\.dependencies) private var dependencies
    @StateObject private var viewModel: OnboardingViewModel

    init() {
        // Temporary - will be replaced when dependencies are available
        let tempContainer = DependencyContainer()
        _viewModel = StateObject(wrappedValue: tempContainer.makeOnboardingViewModel())
    }

    var body: some View {
        if let deps = dependencies {
            OnboardingContentView(viewModel: deps.makeOnboardingViewModel())
        }
    }
}

struct OnboardingContentView: View {
    @StateObject var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingView(viewModel: viewModel)
            .onAppear {
                // Configure window
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let window = NSApp.windows.first(where: { $0.title == "" || $0.title.isEmpty }) {
                        window.level = .floating
                        window.center()
                        window.titlebarAppearsTransparent = true
                        window.titleVisibility = .hidden
                        window.styleMask.insert(.fullSizeContentView)
                        window.isMovableByWindowBackground = true
                        window.makeKeyAndOrderFront(nil)
                    }
                }
            }
    }
}

// MARK: - Capture Options Root

struct CaptureOptionsRootView: View {
    @Environment(\.dependencies) private var dependencies
    @StateObject private var viewModel: CaptureFlowViewModel

    init() {
        // Temporary - will be replaced when dependencies are available
        let tempContainer = DependencyContainer()
        _viewModel = StateObject(wrappedValue: tempContainer.makeCaptureFlowViewModel())
    }

    var body: some View {
        if let deps = dependencies {
            CaptureOptionsContentView(viewModel: deps.makeCaptureFlowViewModel())
        }
    }
}

struct CaptureOptionsContentView: View {
    @StateObject var viewModel: CaptureFlowViewModel
    @State private var isPresented = true

    var body: some View {
        CaptureOptionsView(
            isPresented: $isPresented,
            viewModel: viewModel
        ) { mode, window in
            viewModel.capture(mode: mode, window: window)
            closeWindow()
        }
        .background(Color.clear)
        .onChange(of: isPresented) { _, newValue in
            if !newValue {
                closeWindow()
            }
        }
        .onAppear {
            setupWindow()
            viewModel.loadAvailableWindows()
        }
    }

    private func setupWindow() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if let window = NSApp.windows.last(where: { $0.isVisible }),
               let screen = NSScreen.main {
                // Make window frameless and transparent
                window.styleMask = [.borderless, .fullSizeContentView]
                window.level = .floating
                window.backgroundColor = .clear
                window.isOpaque = false
                window.hasShadow = true
                window.isMovableByWindowBackground = false
                window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

                // Remove any default content insets
                window.contentView?.wantsLayer = true
                window.contentView?.layer?.backgroundColor = .clear

                // Fit content size
                window.setContentSize(NSSize(width: 350, height: 120))

                // Position at bottom center of screen
                let screenFrame = screen.visibleFrame
                let x = screenFrame.midX - 175
                let y = screenFrame.minY + 60
                window.setFrameOrigin(NSPoint(x: x, y: y))

                window.makeKeyAndOrderFront(nil)
            }
        }
    }

    private func closeWindow() {
        DispatchQueue.main.async {
            if let window = NSApp.windows.last(where: { window in
                window.isVisible && window.level == .floating
            }) {
                window.close()
            }
        }
    }
}
