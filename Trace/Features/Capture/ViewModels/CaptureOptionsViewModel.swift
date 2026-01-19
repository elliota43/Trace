//
//  CaptureOptionsViewModel.swift
//  Trace
//
//  Created by Elliot Anderson on 1/19/26.
//

import Foundation
import SwiftUI
import AppKit
import Combine

@MainActor
final class CaptureOptionsViewModel: ObservableObject {
    @Published var isPresented: Bool = true
    @Published var showWindowPicker: Bool = false

    private var eventMonitor: Any?

    func setupEscapeKeyHandler() {
        // Store monitor and ensure cleanup
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }

            if event.keyCode == 53 { // Esc
                self.isPresented = false
                return nil
            }
            return event
        }
    }

    func cleanup() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    deinit {
        print("🗑️ CaptureOptionsViewModel deallocated")
        // Cleanup happens automatically when ARC releases the monitor
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
