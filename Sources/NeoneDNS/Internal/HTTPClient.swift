import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Internal protocol abstracting HTTP data fetching for testability.
protocol HTTPClient: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

/// Default implementation using Foundation's URLSession.
struct URLSessionHTTPClient: HTTPClient, @unchecked Sendable {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}
