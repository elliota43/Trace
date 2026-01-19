//
//  CaptureOptionsView.swift
//  Trace
//
//  Created by Elliot Anderson on 1/19/26.
//

import SwiftUI
import ScreenCaptureKit

enum CaptureMode {
    case fullScreen
    case window
    case region
    case video
}

struct CaptureOptionsView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: CaptureFlowViewModel
    let onCapture: (CaptureMode, SCWindow?) -> Void

    @State private var selectedWindow: SCWindow?
    @State private var showWindowPicker = false

    var body: some View {
        VStack(spacing: 8) {
            // Window Picker (if showing)
            if showWindowPicker && !viewModel.availableWindows.isEmpty {
                windowPickerView
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Floating Bar
            HStack(spacing: 0) {
                // Capture Options
                CaptureButton(
                    icon: "camera.fill",
                    label: "Screen",
                    isActive: false
                ) {
                    isPresented = false
                    onCapture(.fullScreen, nil)
                }

                Divider()
                    .frame(height: 30)
                    .background(Color.white.opacity(0.2))

                CaptureButton(
                    icon: "macwindow",
                    label: "Window",
                    isActive: showWindowPicker
                ) {
                    if showWindowPicker {
                        withAnimation(.spring(response: 0.3)) {
                            showWindowPicker = false
                        }
                    } else {
                        viewModel.loadAvailableWindows()
                        withAnimation(.spring(response: 0.3)) {
                            showWindowPicker = true
                        }
                    }
                }

                Divider()
                    .frame(height: 30)
                    .background(Color.white.opacity(0.2))

                CaptureButton(
                    icon: "crop",
                    label: "Region",
                    isActive: false
                ) {
                    isPresented = false
                    onCapture(.region, nil)
                }

                Divider()
                    .frame(height: 30)
                    .background(Color.white.opacity(0.2))

                CaptureButton(
                    icon: "video.fill",
                    label: "Video",
                    isActive: false
                ) {
                    isPresented = false
                    onCapture(.video, nil)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.85))
                    .background(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.5), radius: 20, y: 10)
        }
        .fixedSize()
    }

    private var windowPickerView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Select Window")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))

                Spacer()

                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        showWindowPicker = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(Color.black.opacity(0.5))

            Divider()
                .background(Color.white.opacity(0.1))

            // Window List
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(viewModel.availableWindows, id: \.windowID) { window in
                        WindowPickerRow(
                            window: window,
                            isSelected: selectedWindow?.windowID == window.windowID
                        ) {
                            selectedWindow = window
                            isPresented = false
                            showWindowPicker = false
                            onCapture(.window, window)
                        }
                    }
                }
                .padding(8)
            }
            .frame(maxHeight: 250)
        }
        .frame(width: 350)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.85))
                .background(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.5), radius: 20, y: 10)
        .padding(.bottom, 8)
    }

}

struct CaptureButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isActive ? Color.blue.opacity(0.3) : (isHovered ? Color.white.opacity(0.15) : Color.clear))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(isActive ? .blue : .white)
                }

                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
            .frame(width: 70)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct WindowPickerRow: View {
    let window: SCWindow
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "macwindow")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(window.title ?? "Unknown")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    if let app = window.owningApplication {
                        Text(app.applicationName)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.white.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct WindowRow: View {
    let window: SCWindow
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "macwindow")
                    .font(.system(size: 16))
                    .foregroundColor(.purple)

                VStack(alignment: .leading, spacing: 2) {
                    Text(window.title ?? "Unknown")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    if let app = window.owningApplication {
                        Text(app.applicationName)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.white.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
