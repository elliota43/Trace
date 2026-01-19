//
//  ScreenshotItem.swift
//  Trace
//
//  Created by Elliot Anderson on 1/19/26.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class ScreenshotItem {
    var id: UUID
    var timestamp: Date
    var appName: String
    var recognizedText: String
    
    @Attribute(.externalStorage) var imageData: Data?
    
    init(appName: String, text: String, imageData: Data) {
        self.id = UUID()
        self.timestamp = Date()
        self.appName = appName
        self.recognizedText = text
        self.imageData = imageData
    }
}
