//
//  PermissionsManager.swift
//  Trace
//
//  Created by Elliot Anderson on 1/18/26.
//

import Foundation
import CoreGraphics

class PermissionsManager {
    static func checkScreenRecordingPermission() -> Bool {
        return CGPreflightScreenCaptureAccess()
    }
    
    static func requestPermission() {
        CGRequestScreenCaptureAccess()
    }
}
