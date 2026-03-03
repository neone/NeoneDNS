import Foundation

/// Configuration for the DNS client.
public struct DNSClientConfiguration: Sendable {
    /// The DNS providers to query. Defaults to Google and Cloudflare.
    public let providers: [any DNSProvider]

    /// The DNS record types to query. Defaults to `[.a, .aaaa, .cname]`.
    public let recordTypes: [DNSRecordType]

    /// The URLSession to use for requests. Defaults to `.shared`.
    public let session: URLSession

    /// Creates a DNS client configuration.
    /// - Parameters:
    ///   - providers: The DNS providers to use. If nil, defaults to Google and Cloudflare.
    ///   - recordTypes: The record types to query.
    ///   - session: The URLSession to use for HTTP requests.
    public init(
        providers: [any DNSProvider]? = nil,
        recordTypes: [DNSRecordType] = [.a, .aaaa, .cname],
        session: URLSession = .shared
    ) {
        self.session = session
        self.recordTypes = recordTypes
        self.providers = providers ?? [
            GoogleDNSProvider(session: session),
            CloudflareDNSProvider(session: session),
        ]
    }
}
