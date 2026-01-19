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
    var smartTitle: String
    var recognizedText: String
    var url: String?

    // Git Context
    var gitBranch: String?
    var gitCommit: String?
    var gitRepo: String?
    var gitStatus: String? // "clean" or "dirty"

    // Browser Context
    var pageTitle: String?
    var domain: String?
    var browserTab: String?

    // IDE Context
    var activeFile: String?
    var activeProject: String?
    var cursorLine: Int?
    var openFiles: String? // JSON array

    // System Context
    var workingDirectory: String?
    var runningProcesses: String? // JSON array
    var activeWindowTitle: String?
    var clipboardContent: String?

    // Design Tool Context
    var figmaFileId: String?
    var figmaFileName: String?
    var figmaFrameName: String?
    var designToolInfo: String? // JSON object

    // Communication Context
    var slackChannel: String?
    var slackThread: String?
    var emailSubject: String?

    // Development Context
    var localhostPorts: String? // JSON array
    var dockerContainers: String? // JSON array
    var npmScripts: String? // JSON array

    // Visual Context
    var dominantColors: String? // JSON array of hex colors
    var detectedObjects: String? // JSON array
    var textBoundsJSON: String? // JSON array of text regions with coordinates

    // Temporal Context
    var timeOfDay: String? // "morning", "afternoon", "evening", "night"
    var dayOfWeek: String?
    var calendarEvent: String?

    // Media Context
    var spotifyTrack: String?
    var spotifyArtist: String?
    var audioPlaying: String?

    @Attribute(.externalStorage) var imageData: Data?

    init(
        appName: String,
        text: String,
        imageData: Data,
        url: String? = nil,
        context: CapturedContext? = nil,
        textBounds: [TextBound]? = nil
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.appName = appName
        self.recognizedText = text
        self.imageData = imageData
        self.url = url

        // Git Context
        self.gitBranch = context?.git.branch
        self.gitCommit = context?.git.commit
        self.gitRepo = context?.git.repo
        self.gitStatus = context?.git.status

        // Browser Context
        self.pageTitle = context?.browser.pageTitle
        self.domain = context?.browser.domain
        self.browserTab = context?.browser.currentTab

        // IDE Context
        self.activeFile = context?.ide.activeFile
        self.activeProject = context?.ide.projectName
        self.cursorLine = context?.ide.cursorLine
        self.openFiles = context?.ide.openFiles

        // System Context
        self.workingDirectory = context?.system.workingDirectory
        self.runningProcesses = context?.system.runningProcesses
        self.activeWindowTitle = context?.system.activeWindowTitle
        self.clipboardContent = context?.system.clipboardContent

        // Design Context
        self.figmaFileId = context?.design.figmaFileId
        self.figmaFileName = context?.design.figmaFileName
        self.figmaFrameName = context?.design.figmaFrameName
        self.designToolInfo = context?.design.additionalInfo

        // Communication Context
        self.slackChannel = context?.communication.slackChannel
        self.slackThread = context?.communication.slackThread
        self.emailSubject = context?.communication.emailSubject

        // Development Context
        self.localhostPorts = context?.development.localhostPorts
        self.dockerContainers = context?.development.dockerContainers
        self.npmScripts = context?.development.npmScripts

        // Visual Context
        self.dominantColors = context?.visual.dominantColors
        self.detectedObjects = context?.visual.detectedObjects

        // Store text bounds as JSON
        if let textBounds = textBounds, !textBounds.isEmpty {
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(textBounds),
               let jsonString = String(data: encoded, encoding: .utf8) {
                self.textBoundsJSON = jsonString
            }
        }

        // Temporal Context
        self.timeOfDay = context?.temporal.timeOfDay
        self.dayOfWeek = context?.temporal.dayOfWeek
        self.calendarEvent = context?.temporal.calendarEvent

        // Media Context
        self.spotifyTrack = context?.media.spotifyTrack
        self.spotifyArtist = context?.media.spotifyArtist
        self.audioPlaying = context?.media.audioPlaying

        self.smartTitle = SmartNamer.generateTitle(from: text, appName: appName)
    }

    // Computed property to decode text bounds
    var textBounds: [TextBound] {
        guard let jsonString = textBoundsJSON,
              let data = jsonString.data(using: .utf8) else { return [] }

        let decoder = JSONDecoder()
        return (try? decoder.decode([TextBound].self, from: data)) ?? []
    }
}
