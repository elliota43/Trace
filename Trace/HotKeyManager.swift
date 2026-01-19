//
//  HotKeyManager.swift
//  Trace
//
//  Created by Elliot Anderson on 1/19/26.
//

import Cocoa
import Carbon
import Combine

class HotKeyManager: ObservableObject {
    static let shared = HotKeyManager()

    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?

    @Published var isRegistered = false
    @Published var lastError: String?

    var onScreenshot: (() -> Void)?

    func registerHotKey(keyCode: UInt32 = UInt32(kVK_ANSI_5), modifiers: UInt32 = UInt32(cmdKey | shiftKey)) -> Bool {
        // Unregister existing hotkey if any
        unregisterHotKey()

        let hotKeyID = EventHotKeyID(signature: OSType(0x53574654), id: 1)

        var eventHotKey: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &eventHotKey
        )

        if status != noErr {
            let errorMsg = "Failed to register hotkey (error: \(status)). Another app may be using it."
            print("❌ \(errorMsg)")
            lastError = errorMsg
            isRegistered = false
            return false
        }

        hotKeyRef = eventHotKey
        installEventHandler()

        print("✅ Global Hotkey (Cmd+Shift+4) Registered")
        lastError = nil
        isRegistered = true
        return true
    }

    func unregisterHotKey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }

        isRegistered = false
    }

    private func installEventHandler() {
        let spec = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        ]

        let handler: EventHandlerUPP = { _, _, _ in
            DispatchQueue.main.async {
                print("🎯 Hotkey triggered!")
                HotKeyManager.shared.onScreenshot?()
            }
            return noErr
        }

        InstallEventHandler(
            GetApplicationEventTarget(),
            handler,
            1,
            spec.withUnsafeBufferPointer { $0.baseAddress },
            nil,
            &eventHandler
        )
    }

    func getHotkeyDescription() -> String {
        return "⌘⇧5 (Cmd+Shift+5)"
    }

    func getSystemConflictWarning() -> String? {
        // Check if we're trying to use a system hotkey
        return "Note: Cmd+Shift+3 and Cmd+Shift+4 are reserved by macOS. Using Cmd+Shift+5 instead."
    }
}
