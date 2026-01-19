//
//  ShellExecutor.swift
//  Trace
//
//  Created by Elliot Anderson on 1/19/26.
//

import Foundation

/// Actor-isolated shell executor prevents data races and provides safe async execution
actor ShellExecutor {
    private let timeout: TimeInterval

    init(timeout: TimeInterval = 2.0) {
        self.timeout = timeout
    }

    /// Execute shell command asynchronously without blocking
    func execute(
        _ command: String,
        in directory: String? = nil
    ) async throws -> String {
        try await withThrowingTaskGroup(of: String?.self) { group in
            // Timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(self.timeout * 1_000_000_000))
                return nil // Timeout indicator
            }

            // Command execution task
            group.addTask {
                try await self.runProcess(command, in: directory)
            }

            // Return first result
            for try await result in group {
                group.cancelAll()
                if let output = result {
                    return output
                } else {
                    throw ShellError.timeout
                }
            }

            throw ShellError.unknown
        }
    }

    private func runProcess(_ command: String, in directory: String?) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")

        var fullCommand = command
        if let directory = directory {
            fullCommand = "cd '\(directory)' && \(command) 2>&1" // Capture stderr
        }

        process.arguments = ["-c", fullCommand]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        // Run process without blocking
        try process.run()

        // Wait asynchronously
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            process.terminationHandler = { _ in
                continuation.resume()
            }
        }

        let data = try pipe.fileHandleForReading.readToEnd() ?? Data()
        let output = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let output = output, !output.isEmpty else {
            throw ShellError.emptyOutput
        }

        return output
    }
}

// MARK: - Errors

enum ShellError: LocalizedError {
    case timeout
    case emptyOutput
    case executionFailed(Int32)
    case unknown

    var errorDescription: String? {
        switch self {
        case .timeout: return "Command timed out"
        case .emptyOutput: return "No output from command"
        case .executionFailed(let code): return "Process exited with code \(code)"
        case .unknown: return "Unknown shell error"
        }
    }
}
