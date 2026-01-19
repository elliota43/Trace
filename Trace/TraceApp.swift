//
//  TraceApp.swift
//  Trace
//
//  Created by Elliot Anderson on 1/18/26.
//

import SwiftUI
import AppKit
import SwiftData
import Combine
import ScreenCaptureKit

@main
struct TraceApp: App {

    @StateObject var captureEngine = CaptureEngine()
    @StateObject var appState = AppState()
    @StateObject var hotKeyManager = HotKeyManager.shared

    var sharedModelContainer: ModelContainer = {
        // DEV FLAG
        let storedInMemory = true

        let schema = Schema([
            ScreenshotItem.self,
        ])


        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: storedInMemory)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        MenuBarExtra("Trace", systemImage: "camera.fill") {
            MenuBarView(
                captureEngine: captureEngine,
                sharedModelContainer: sharedModelContainer,
                appState: appState,
                hotKeyManager: hotKeyManager
            )
            .onAppear {
                setupHotKey()
            }
        }
        .menuBarExtraStyle(.menu)

        WindowGroup(id: "gallery") {
            GalleryView()
                .modelContainer(sharedModelContainer)
        }

        WindowGroup(id: "onboarding") {
            OnboardingView(viewModel: OnboardingViewModel(
                permissionsService: PermissionsServiceImpl(),
                hotkeyService: CarbonHotkeyService()
            ))
                .onAppear {
                    // Ensure window settings
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
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .windowStyle(.hiddenTitleBar)

        WindowGroup(id: "captureOptions") {
            CaptureOptionsWindow(
                captureEngine: captureEngine,
                sharedModelContainer: sharedModelContainer
            )
        }
    }

    private func setupHotKey() {
        // Register the global hotkey
        let success = hotKeyManager.registerHotKey()

        if success {
            print("✅ Hotkey setup complete")
        } else {
            print("⚠️ Hotkey registration failed: \(hotKeyManager.lastError ?? "Unknown error")")
        }

        // Connect hotkey to capture options trigger
        hotKeyManager.onScreenshot = {
            // Notify AppState to show capture options
            Task { @MainActor in
                appState.triggerCaptureFromHotkey()
            }
        }
    }
}

// MARK: - App State

class AppState: ObservableObject {
    @Published var showOnboarding: Bool = false
    @Published var showCaptureOptionsFromHotkey: Bool = false
    var hasCheckedOnboarding = false

    init() {
        // Check if onboarding is needed on app launch
        self.showOnboarding = PermissionsManager.needsOnboarding()
    }

    func openOnboardingIfNeeded() {
        guard !hasCheckedOnboarding else { return }
        hasCheckedOnboarding = true

        if showOnboarding {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Open onboarding window via NSApplication
                if let onboardingItem = NSApp.windows.first(where: { $0.identifier?.rawValue.contains("onboarding") ?? false }) {
                    onboardingItem.makeKeyAndOrderFront(nil)
                }
            }
        }
    }

    func triggerCaptureFromHotkey() {
        showCaptureOptionsFromHotkey = true
    }
}

struct MenuBarView: View {
    @ObservedObject var captureEngine: CaptureEngine
    let sharedModelContainer: ModelContainer
    @ObservedObject var appState: AppState
    @ObservedObject var hotKeyManager: HotKeyManager

    @Environment(\.openWindow) var openWindow

    var body: some View {
        Group {
            menuContent
        }
        .onAppear {
            appState.openOnboardingIfNeeded()
            if appState.showOnboarding {
                openWindow(id: "onboarding")
            }
        }
        .onChange(of: appState.showCaptureOptionsFromHotkey) { _, shouldShow in
            if shouldShow {
                openWindow(id: "captureOptions")
                appState.showCaptureOptionsFromHotkey = false
            }
        }
    }

    private var menuContent: some View {
        Group {
            Button(captureEngine.isCapturing ? "Capturing..." : "Capture Screen...") {
                print("🔘 Capture Screen button clicked")
                openWindow(id: "captureOptions")
            }
            .disabled(captureEngine.isCapturing)

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
    }

    private func performCapture(mode: CaptureMode, window: SCWindow?) async {
        if let result = await captureEngine.capture(mode: mode, window: window) {
            let newItem = ScreenshotItem(
                appName: result.appName,
                text: result.text,
                imageData: result.imageData,
                url: result.url,
                context: result.context,
                textBounds: result.textBounds
            )

            Task { @MainActor in
                sharedModelContainer.mainContext.insert(newItem)
            }
        }
    }
}

// MARK: - Capture Options Window

struct CaptureOptionsWindow: View {
    @ObservedObject var captureEngine: CaptureEngine
    let sharedModelContainer: ModelContainer
    @State private var isPresented = true
    @State private var eventMonitor: Any?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        CaptureOptionsView(
            isPresented: $isPresented,
            viewModel: CaptureFlowViewModel(
                screenCaptureService: ScreenCaptureServiceImpl(),
                ocrService: VisionOCRService(),
                contextService: ContextCaptureServiceImpl(),
                imageProcessor: ImageProcessingServiceImpl(),
                repository: ScreenshotRepositoryImpl(modelContainer: sharedModelContainer)
            )
        ) { mode, window in
            print("📸 Capture mode selected: \(mode)")
            Task {
                await performCapture(mode: mode, window: window)
                // Close window after capture
                closeWindow()
            }
        }
        .background(Color.clear)
        .onChange(of: isPresented) { _, newValue in
            if !newValue {
                closeWindow()
            }
        }
        .onAppear {
            setupWindow()
            setupEscapeKeyHandler()
        }
        .onDisappear {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
            }
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

                // Position at bottom center of screen (like QuickTime)
                let screenFrame = screen.visibleFrame
                let x = screenFrame.midX - 175 // Half of bar width
                let y = screenFrame.minY + 60 // 60 points from bottom
                window.setFrameOrigin(NSPoint(x: x, y: y))

                window.makeKeyAndOrderFront(nil)
            }
        }
    }

    private func setupEscapeKeyHandler() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // Esc key
                closeWindow()
                return nil
            }
            return event
        }
    }

    private func performCapture(mode: CaptureMode, window: SCWindow?) async {
        if let result = await captureEngine.capture(mode: mode, window: window) {
            let newItem = ScreenshotItem(
                appName: result.appName,
                text: result.text,
                imageData: result.imageData,
                url: result.url,
                context: result.context,
                textBounds: result.textBounds
            )

            await MainActor.run {
                sharedModelContainer.mainContext.insert(newItem)
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
