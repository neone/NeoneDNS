import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// DNS-over-HTTPS provider using Cloudflare DNS.
///
/// Endpoint: `https://cloudflare-dns.com/dns-query`
public struct CloudflareDNSProvider: DNSProvider {
    public let name = "Cloudflare"
    private let executor: DoHRequestExecutor

    /// Creates a Cloudflare DNS provider.
    /// - Parameter session: The URLSession to use. Defaults to `.shared`.
    public init(session: URLSession = .shared) {
        self.executor = DoHRequestExecutor(
            httpClient: URLSessionHTTPClient(session: session),
            baseURL: "https://cloudflare-dns.com/dns-query",
            providerName: "Cloudflare"
        )
    }

    init(httpClient: any HTTPClient) {
        self.executor = DoHRequestExecutor(
            httpClient: httpClient,
            baseURL: "https://cloudflare-dns.com/dns-query",
            providerName: "Cloudflare"
        )
    }

    public func lookup(domain: String, recordTypes: [DNSRecordType]) async throws -> DNSLookupResult {
        try await executor.lookup(domain: domain, recordTypes: recordTypes)
    }
}
