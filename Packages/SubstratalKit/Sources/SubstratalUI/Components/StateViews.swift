import SwiftUI
import SubstratalCore

/// Loading / empty / error states every screen needs (README Definition of Done).
public enum LoadState<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(APIError)

    public var value: Value? { if case .loaded(let v) = self { v } else { nil } }
    public var isLoading: Bool { if case .loading = self { true } else { false } }
}

public struct ErrorStateView: View {
    let error: APIError
    let retry: (() -> Void)?

    public init(_ error: APIError, retry: (() -> Void)? = nil) {
        self.error = error
        self.retry = retry
    }

    public var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: symbol)
        } description: {
            Text(error.userMessage)
        } actions: {
            if let retry { Button("Try again", action: retry).buttonStyle(.borderedProminent) }
        }
    }

    private var title: String {
        switch error {
        case .forbidden: "No access"
        case .notFound: "Not found"
        case .transport: "You're offline"
        case .rateLimited: "Slow down"
        default: "Something went wrong"
        }
    }

    private var symbol: String {
        switch error {
        case .forbidden: "lock"
        case .notFound: "questionmark.folder"
        case .transport: "wifi.slash"
        case .rateLimited: "hourglass"
        default: "exclamationmark.triangle"
        }
    }
}

/// Wraps a screen's content in its load state.
public struct LoadStateView<Value, Content: View>: View {
    let state: LoadState<Value>
    let retry: () -> Void
    @ViewBuilder let content: (Value) -> Content

    public init(_ state: LoadState<Value>, retry: @escaping () -> Void, @ViewBuilder content: @escaping (Value) -> Content) {
        self.state = state
        self.retry = retry
        self.content = content
    }

    public var body: some View {
        switch state {
        case .idle, .loading: ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let error): ErrorStateView(error, retry: retry)
        case .loaded(let value): content(value)
        }
    }
}
