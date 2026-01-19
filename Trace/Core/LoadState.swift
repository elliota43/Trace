//
//  LoadState.swift
//  Trace
//
//  Created by Elliot Anderson on 1/19/26.
//

import Foundation

enum LoadState<T: Sendable>: Sendable {
    case idle
    case loading
    case success(T)
    case failure(SendableError)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var value: T? {
        if case .success(let value) = self { return value }
        return nil
    }

    var error: SendableError? {
        if case .failure(let error) = self { return error }
        return nil
    }
}

struct SendableError: Error, Sendable {
    let message: String
    let underlyingError: String

    init(error: Error) {
        self.message = error.localizedDescription
        self.underlyingError = String(describing: error)
    }

    var localizedDescription: String {
        message
    }
}
