import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// DNS-over-HTTPS provider using Google Public DNS.
///
/// Endpoint: `https://dns.google/resolve`
public struct GoogleDNSProvider: DNSProvider {
    public let name = "Google"
    private let executor: DoHRequestExecutor

    /// Creates a Google DNS provider.
    /// - Parameter session: The URLSession to use. Defaults to `.shared`.
    public init(session: URLSession = .shared) {
        self.executor = DoHRequestExecutor(
            httpClient: URLSessionHTTPClient(session: session),
            baseURL: "https://dns.google/resolve",
            providerName: "Google"
        )
    }

    init(httpClient: any HTTPClient) {
        self.executor = DoHRequestExecutor(
            httpClient: httpClient,
            baseURL: "https://dns.google/resolve",
            providerName: "Google"
        )
    }

    public func lookup(domain: String, recordTypes: [DNSRecordType]) async throws -> DNSLookupResult {
        try await executor.lookup(domain: domain, recordTypes: recordTypes)
    }
}
