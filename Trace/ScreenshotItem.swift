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
final class ScreenshotItem: Identifiable {
    var id: UUID
    var timestamp: Date
    var appName: String
    var recognizedText: String
    var url: String?
    
    @Attribute(.externalStorage) var imageData: Data?
    
    init(appName: String, text: String, imageData: Data, url: String? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.appName = appName
        self.recognizedText = text
        self.imageData = imageData
        self.url = url
    }
}
