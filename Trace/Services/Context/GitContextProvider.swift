//
//  GitContextProvider.swift
//  Trace
//
//  Created by Elliot Anderson on 1/19/26.
//

import Foundation

// MARK: - Protocol

protocol GitContextProvider: Sendable {
    func captureContext() async -> GitContext
}

// MARK: - Implementation

final class GitContextProviderImpl: GitContextProvider {
    private let shellExecutor: ShellExecutor

    init(shellExecutor: ShellExecutor = ShellExecutor(timeout: 2.0)) {
        self.shellExecutor = shellExecutor
    }

    func captureContext() async -> GitContext {
        // Use guard + early return pattern for safety
        guard let workingDir = await findGitRepo() else {
            return GitContext()
        }

        // Execute commands in parallel safely
        async let branch = try? await shellExecutor.execute(
            "git rev-parse --abbrev-ref HEAD",
            in: workingDir
        )
        async let commit = try? await shellExecutor.execute(
            "git rev-parse --short HEAD",
            in: workingDir
        )
        async let repoURL = try? await shellExecutor.execute(
            "git config --get remote.origin.url",
            in: workingDir
        )
        async let status = try? await shellExecutor.execute(
            "git status --porcelain",
            in: workingDir
        )

        return await GitContext(
            branch: branch,
            commit: commit,
            repo: repoURL,
            status: (status?.isEmpty ?? true) ? "clean" : "dirty"
        )
    }

    private func findGitRepo() async -> String? {
        // Non-blocking file system search
        await Task.detached {
            let fm = FileManager.default
            let devPaths = [
                NSHomeDirectory() + "/Desktop",
                NSHomeDirectory() + "/Documents",
                NSHomeDirectory() + "/Developer",
            ]

            for path in devPaths {
                if let repo = self.findGitRepoRecursive(in: path, maxDepth: 2) {
                    return repo
                }
            }
            return nil
        }.value
    }

    private func findGitRepoRecursive(in path: String, maxDepth: Int) -> String? {
        guard maxDepth > 0 else { return nil }

        let fm = FileManager.default
        let gitPath = path + "/.git"

        if fm.fileExists(atPath: gitPath) {
            return path
        }

        guard let contents = try? fm.contentsOfDirectory(atPath: path) else {
            return nil
        }

        for item in contents.prefix(10) where !item.hasPrefix(".") {
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
}
