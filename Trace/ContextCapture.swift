//
//  ContextCapture.swift
//  Trace
//
//  Created by Elliot Anderson on 1/19/26.
//

import Foundation
import AppKit

class ContextCapture {
    static func captureAll(for appName: String) async -> CapturedContext {
        async let git = captureGitContext()
        async let browser = captureBrowserContext(appName: appName)
        async let ide = captureIDEContext(appName: appName)
        async let system = captureSystemContext()
        async let design = captureDesignContext(appName: appName)
        async let communication = captureCommunicationContext(appName: appName)
        async let development = captureDevelopmentContext()
        async let visual = captureVisualContext()
        async let temporal = captureTemporalContext()
        async let media = captureMediaContext()

        return await CapturedContext(
            git: git,
            browser: browser,
            ide: ide,
            system: system,
            design: design,
            communication: communication,
            development: development,
            visual: visual,
            temporal: temporal,
            media: media
        )
    }

    // MARK: - Git Context

    static func captureGitContext() async -> GitContext {
        guard let workingDir = findGitRepo() else {
            return GitContext(branch: nil, commit: nil, repo: nil, status: nil)
        }

        let branch = await shell("git rev-parse --abbrev-ref HEAD", in: workingDir)
        let commit = await shell("git rev-parse --short HEAD", in: workingDir)
        let repoURL = await shell("git config --get remote.origin.url", in: workingDir)
        let status = await shell("git status --porcelain", in: workingDir)
        let isClean = status?.isEmpty ?? true

        return GitContext(
            branch: branch,
            commit: commit,
            repo: repoURL,
            status: isClean ? "clean" : "dirty"
        )
    }

    private static func findGitRepo() -> String? {
        let fm = FileManager.default
        var currentPath = fm.currentDirectoryPath

        // Try common dev directories
        let devPaths = [
            NSHomeDirectory() + "/Desktop",
            NSHomeDirectory() + "/Documents",
            NSHomeDirectory() + "/Developer",
            NSHomeDirectory() + "/Projects"
        ]

        for path in devPaths {
            if let repo = findGitRepoRecursive(in: path, maxDepth: 3) {
                return repo
            }
        }

        return nil
    }

    private static func findGitRepoRecursive(in path: String, maxDepth: Int) -> String? {
        guard maxDepth > 0 else { return nil }

        let fm = FileManager.default
        let gitPath = path + "/.git"

        if fm.fileExists(atPath: gitPath) {
            return path
        }

        guard let contents = try? fm.contentsOfDirectory(atPath: path) else { return nil }

        for item in contents where !item.hasPrefix(".") {
            let itemPath = path + "/" + item
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: itemPath, isDirectory: &isDir), isDir.boolValue {
                if let repo = findGitRepoRecursive(in: itemPath, maxDepth: maxDepth - 1) {
                    return repo
                }
            }
        }

        return nil
    }

    // MARK: - Browser Context

    static func captureBrowserContext(appName: String) async -> BrowserContext {
        let browsers = ["Safari", "Google Chrome", "Brave Browser", "Arc"]

        guard browsers.contains(where: { appName.contains($0) }) else {
            return BrowserContext(pageTitle: nil, domain: nil, currentTab: nil)
        }

        var pageTitle: String?
        var domain: String?

        if appName.contains("Safari") {
            let script = """
            tell application "Safari"
                if (count of windows) > 0 then
                    set currentTab to current tab of front window
                    return {name of currentTab, URL of currentTab}
                end if
            end tell
            """
            if let result = await applescript(script) {
                let parts = result.components(separatedBy: ", ")
                pageTitle = parts.first
                if let urlString = parts.last, let url = URL(string: urlString) {
                    domain = url.host
                }
            }
        } else if appName.contains("Chrome") || appName.contains("Brave") {
            let appId = appName.contains("Chrome") ? "Google Chrome" : "Brave Browser"
            let script = """
            tell application "\(appId)"
                if (count of windows) > 0 then
                    set currentTab to active tab of front window
                    return {title of currentTab, URL of currentTab}
                end if
            end tell
            """
            if let result = await applescript(script) {
                let parts = result.components(separatedBy: ", ")
                pageTitle = parts.first
                if let urlString = parts.last, let url = URL(string: urlString) {
                    domain = url.host
                }
            }
        }

        return BrowserContext(pageTitle: pageTitle, domain: domain, currentTab: nil)
    }

    // MARK: - IDE Context

    static func captureIDEContext(appName: String) async -> IDEContext {
        let ides = ["Xcode", "Visual Studio Code", "Code", "Cursor", "IntelliJ", "WebStorm"]

        guard ides.contains(where: { appName.contains($0) }) else {
            return IDEContext(activeFile: nil, projectName: nil, cursorLine: nil, openFiles: nil)
        }

        var activeFile: String?
        var projectName: String?

        if appName.contains("Xcode") {
            let script = """
            tell application "Xcode"
                if (count of windows) > 0 then
                    set activeDoc to active workspace document
                    if activeDoc is not missing value then
                        return {path of activeDoc, name of activeDoc}
                    end if
                end if
            end tell
            """
            if let result = await applescript(script) {
                let parts = result.components(separatedBy: ", ")
                activeFile = parts.first
                projectName = parts.last
            }
        } else if appName.contains("Code") || appName.contains("Cursor") {
            // VS Code context can be gathered via window title
            if let windowTitle = await getActiveWindowTitle() {
                let parts = windowTitle.components(separatedBy: " - ")
                if parts.count > 1 {
                    activeFile = parts[0]
                    projectName = parts.last
                }
            }
        }

        return IDEContext(
            activeFile: activeFile,
            projectName: projectName,
            cursorLine: nil,
            openFiles: nil
        )
    }

    // MARK: - System Context

    static func captureSystemContext() async -> SystemContext {
        let workingDir = await shell("pwd", in: nil)
        let processes = await shell("ps aux | grep -v grep | awk '{print $11}' | sort | uniq", in: nil)
        let windowTitle = await getActiveWindowTitle()
        let clipboard = NSPasteboard.general.string(forType: .string)

        // Convert process list to JSON array
        var processArray: [String] = []
        if let processes = processes {
            processArray = processes.components(separatedBy: "\n")
                .filter { !$0.isEmpty }
                .prefix(20)
                .map { String($0) }
        }

        let processesJSON = try? JSONEncoder().encode(processArray)
        let processesString = processesJSON.flatMap { String(data: $0, encoding: .utf8) }

        return SystemContext(
            workingDirectory: workingDir,
            runningProcesses: processesString,
            activeWindowTitle: windowTitle,
            clipboardContent: clipboard?.prefix(200).description
        )
    }

    // MARK: - Design Context

    static func captureDesignContext(appName: String) async -> DesignContext {
        guard appName.contains("Figma") || appName.contains("Sketch") || appName.contains("Adobe") else {
            return DesignContext(figmaFileId: nil, figmaFileName: nil, figmaFrameName: nil, additionalInfo: nil)
        }

        // For Figma in browser, extract from URL
        if appName.contains("Figma") {
            let browser = await captureBrowserContext(appName: "Safari")
            if let url = browser.currentTab, url.contains("figma.com/file/") {
                let components = url.components(separatedBy: "/")
                if let fileIndex = components.firstIndex(of: "file"), fileIndex + 1 < components.count {
                    let fileId = components[fileIndex + 1]
                    let fileName = components.count > fileIndex + 2 ? components[fileIndex + 2] : nil
                    return DesignContext(
                        figmaFileId: fileId,
                        figmaFileName: fileName?.removingPercentEncoding,
                        figmaFrameName: nil,
                        additionalInfo: nil
                    )
                }
            }
        }

        return DesignContext(figmaFileId: nil, figmaFileName: nil, figmaFrameName: nil, additionalInfo: nil)
    }

    // MARK: - Communication Context

    static func captureCommunicationContext(appName: String) async -> CommunicationContext {
        var slackChannel: String?
        var slackThread: String?
        var emailSubject: String?

        if appName.contains("Slack") {
            if let windowTitle = await getActiveWindowTitle() {
                // Slack window titles are usually: "#channel-name | Workspace"
                let parts = windowTitle.components(separatedBy: " | ")
                slackChannel = parts.first?.trimmingCharacters(in: .whitespaces)
            }
        } else if appName.contains("Mail") || appName.contains("Outlook") {
            if let windowTitle = await getActiveWindowTitle() {
                emailSubject = windowTitle
            }
        }

        return CommunicationContext(
            slackChannel: slackChannel,
            slackThread: slackThread,
            emailSubject: emailSubject
        )
    }

    // MARK: - Development Context

    static func captureDevelopmentContext() async -> DevelopmentContext {
        // Find running localhost ports
        let lsofOutput = await shell("lsof -iTCP -sTCP:LISTEN -P -n | grep localhost", in: nil)
        var ports: [String] = []

        if let lsofOutput = lsofOutput {
            let lines = lsofOutput.components(separatedBy: "\n")
            for line in lines {
                if let portRange = line.range(of: "localhost:\\d+", options: .regularExpression) {
                    let portStr = String(line[portRange]).replacingOccurrences(of: "localhost:", with: "")
                    if !ports.contains(portStr) {
                        ports.append(portStr)
                    }
                }
            }
        }

        // Find running Docker containers
        let dockerOutput = await shell("docker ps --format '{{.Names}}'", in: nil)
        var containers: [String] = []
        if let dockerOutput = dockerOutput {
            containers = dockerOutput.components(separatedBy: "\n").filter { !$0.isEmpty }
        }

        let portsJSON = try? JSONEncoder().encode(ports)
        let containersJSON = try? JSONEncoder().encode(containers)

        return DevelopmentContext(
            localhostPorts: portsJSON.flatMap { String(data: $0, encoding: .utf8) },
            dockerContainers: containersJSON.flatMap { String(data: $0, encoding: .utf8) },
            npmScripts: nil
        )
    }

    // MARK: - Visual Context

    static func captureVisualContext() async -> VisualContext {
        // TODO: Implement color extraction from image
        // TODO: Implement object detection
        return VisualContext(
            dominantColors: nil,
            detectedObjects: nil,
            textBounds: nil
        )
    }

    // MARK: - Temporal Context

    static func captureTemporalContext() async -> TemporalContext {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)

        let timeOfDay: String
        switch hour {
        case 5..<12: timeOfDay = "morning"
        case 12..<17: timeOfDay = "afternoon"
        case 17..<21: timeOfDay = "evening"
        default: timeOfDay = "night"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let dayOfWeek = formatter.string(from: now)

        // TODO: Fetch current calendar event from EventKit
        return TemporalContext(
            timeOfDay: timeOfDay,
            dayOfWeek: dayOfWeek,
            calendarEvent: nil
        )
    }

    // MARK: - Media Context

    static func captureMediaContext() async -> MediaContext {
        let script = """
        tell application "Spotify"
            if player state is playing then
                return {name of current track, artist of current track}
            end if
        end tell
        """

        if let result = await applescript(script) {
            let parts = result.components(separatedBy: ", ")
            return MediaContext(
                spotifyTrack: parts.first,
                spotifyArtist: parts.last,
                audioPlaying: nil
            )
        }

        return MediaContext(spotifyTrack: nil, spotifyArtist: nil, audioPlaying: nil)
    }

    // MARK: - Helper Functions

    private static func shell(_ command: String, in directory: String?) async -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")

        var fullCommand = command
        if let directory = directory {
            fullCommand = "cd '\(directory)' && \(command)"
        }

        process.arguments = ["-c", fullCommand]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)

            return output?.isEmpty == false ? output : nil
        } catch {
            return nil
        }
    }

    private static func applescript(_ script: String) async -> String? {
        var error: NSDictionary?
        let appleScript = NSAppleScript(source: script)
        let output = appleScript?.executeAndReturnError(&error)

        if error != nil {
            return nil
        }

        return output?.stringValue
    }

    private static func getActiveWindowTitle() async -> String? {
        let script = """
        tell application "System Events"
            set frontApp to first application process whose frontmost is true
            set windowTitle to name of front window of frontApp
            return windowTitle
        end tell
        """
        return await applescript(script)
    }
}
