import Foundation

/// A protocol for DNS-over-HTTPS providers.
///
/// Conform to this protocol to add custom DoH providers or to create
/// mock implementations for testing.
public protocol DNSProvider: Sendable {
    /// A human-readable name for this provider (e.g., "Google", "Cloudflare").
    var name: String { get }

    /// Perform a DNS lookup for the given domain and record types.
    ///
    /// - Parameters:
    ///   - domain: The domain name to look up.
    ///   - recordTypes: The DNS record types to query.
    /// - Returns: A ``DNSLookupResult`` containing all matching records.
    /// - Throws: ``DNSError`` on failure.
    func lookup(domain: String, recordTypes: [DNSRecordType]) async throws -> DNSLookupResult
}
