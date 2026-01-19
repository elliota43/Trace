//
//  BrowserIntegration.swift
//  Trace
//
//  Created by Elliot Anderson on 1/19/26.
//

import Foundation
import AppKit

class BrowserIntegration {
    
    static func getCurrentURL(for appName: String) -> String? {
        var scriptSource: String?
        
        // We have to customize the script for each browser because they are all divas.
        switch appName {
        case "Google Chrome", "Brave Browser", "Microsoft Edge", "Arc":
            scriptSource = "tell application \"\(appName)\" to return URL of active tab of front window"
        case "Safari":
            scriptSource = "tell application \"Safari\" to return URL of front document"
        default:
            return nil
        }
        
        guard let source = scriptSource else { return nil }
        
        // Run the script
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: source) {
            let output = scriptObject.executeAndReturnError(&error)
            if let string = output.stringValue {
                return string
            }
        }
        return nil
    }
}
