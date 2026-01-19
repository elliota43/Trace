//
//  HotkeyService.swift
//  Trace
//
//  Created by Elliot Anderson on 1/19/26.
//

import Foundation
import Carbon
import AppKit

// MARK: - Protocol

protocol HotkeyService: AnyObject {
    var isRegistered: Bool { get }
    func register(
        keyCode: UInt32,
        modifiers: UInt32,
        handler: @escaping () -> Void
    ) -> Bool
    func unregister()
}

// MARK: - Implementation

final class CarbonHotkeyService: HotkeyService {
    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?
    private var handlerClosure: (() -> Void)?

    private(set) var isRegistered = false

    func register(
        keyCode: UInt32 = UInt32(kVK_ANSI_5),
        modifiers: UInt32 = UInt32(cmdKey | shiftKey),
        handler: @escaping () -> Void
    ) -> Bool {
        unregister() // Clean up first

        // Store handler (no retain cycle - we own it)
        handlerClosure = handler

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

        guard status == noErr else {
            print("❌ Failed to register hotkey (error: \(status))")
            return false
        }

        hotKeyRef = eventHotKey
        installEventHandler()
        isRegistered = true

        print("✅ Hotkey registered successfully")
        return true
    }

    func unregister() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }

        handlerClosure = nil
        isRegistered = false
    }

    private func installEventHandler() {
        let spec = [
            EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyPressed)
            )
        ]

        // Use unmanaged self to avoid retain cycle
        let handler: EventHandlerUPP = { _, _, userData in
            guard let userData = userData else { return noErr }

            let service = Unmanaged<CarbonHotkeyService>
                .fromOpaque(userData)
                .takeUnretainedValue()

            DispatchQueue.main.async {
                service.handlerClosure?()
            }

            return noErr
        }

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            handler,
            1,
            spec.withUnsafeBufferPointer { $0.baseAddress },
            selfPtr,
            &eventHandler
        )
    }

    deinit {
        print("🗑️ CarbonHotkeyService deallocated")
        unregister()
    }
}
