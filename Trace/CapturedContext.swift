//
//  CapturedContext.swift
//  Trace
//
//  Created by Elliot Anderson on 1/19/26.
//

import Foundation

// MARK: - Main Context Container

struct CapturedContext {
    var git: GitContext
    var browser: BrowserContext
    var ide: IDEContext
    var system: SystemContext
    var design: DesignContext
    var communication: CommunicationContext
    var development: DevelopmentContext
    var visual: VisualContext
    var temporal: TemporalContext
    var media: MediaContext
}

// MARK: - Individual Context Structures

struct GitContext {
    var branch: String?
    var commit: String?
    var repo: String?
    var status: String?
}

struct BrowserContext {
    var pageTitle: String?
    var domain: String?
    var currentTab: String?
}

struct IDEContext {
    var activeFile: String?
    var projectName: String?
    var cursorLine: Int?
    var openFiles: String?
}

struct SystemContext {
    var workingDirectory: String?
    var runningProcesses: String?
    var activeWindowTitle: String?
    var clipboardContent: String?
}

struct DesignContext {
    var figmaFileId: String?
    var figmaFileName: String?
    var figmaFrameName: String?
    var additionalInfo: String?
}

struct CommunicationContext {
    var slackChannel: String?
    var slackThread: String?
    var emailSubject: String?
}

struct DevelopmentContext {
    var localhostPorts: String?
    var dockerContainers: String?
    var npmScripts: String?
}

struct VisualContext {
    var dominantColors: String?
    var detectedObjects: String?
    var textBounds: String?
}

struct TemporalContext {
    var timeOfDay: String?
    var dayOfWeek: String?
    var calendarEvent: String?
}

struct MediaContext {
    var spotifyTrack: String?
    var spotifyArtist: String?
    var audioPlaying: String?
}
