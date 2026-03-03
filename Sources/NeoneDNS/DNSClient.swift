import Foundation

/// The primary entry point for performing DNS lookups and propagation checks.
///
/// `DNSClient` provides both single-check lookups and propagation polling
/// using DNS-over-HTTPS providers.
///
/// ## Usage
///
/// ```swift
/// let client = DNSClient()
///
/// // Single check
/// let results = try await client.lookup(domain: "example.neone.cloud")
///
/// // Wait for propagation
/// let propagation = try await client.waitForPropagation(
///     domain: "new-space.neone.cloud"
/// )
/// ```
public struct DNSClient: Sendable {
    private let configuration: DNSClientConfiguration

    /// Creates a DNS client with the default configuration (Google + Cloudflare providers).
    public init() {
        self.configuration = DNSClientConfiguration()
    }

    /// Creates a DNS client with a custom configuration.
    public init(configuration: DNSClientConfiguration) {
        self.configuration = configuration
    }

    // MARK: - Single-Check API

    /// Performs a one-off DNS lookup across all configured providers.
    ///
    /// Queries all providers concurrently and returns all results.
    ///
    /// - Parameters:
    ///   - domain: The domain name to look up.
    ///   - recordTypes: The record types to query. If nil, uses the configured defaults.
    /// - Returns: An array of ``DNSLookupResult``, one per provider.
    /// - Throws: ``DNSError`` if all providers fail.
    public func lookup(
        domain: String,
        recordTypes: [DNSRecordType]? = nil
    ) async throws -> [DNSLookupResult] {
        let types = recordTypes ?? configuration.recordTypes
        guard !configuration.providers.isEmpty else {
            throw DNSError.noProviders
        }

        return try await withThrowingTaskGroup(
            of: DNSLookupResult.self,
            returning: [DNSLookupResult].self
        ) { group in
            for provider in configuration.providers {
                group.addTask {
                    try await provider.lookup(domain: domain, recordTypes: types)
                }
            }
            var results: [DNSLookupResult] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
    }

    // MARK: - Propagation Check API

    /// Waits for DNS propagation by polling all providers until consensus is reached
    /// or the timeout is exceeded.
    ///
    /// "Propagated" means all providers return at least one matching record.
    ///
    /// - Parameters:
    ///   - domain: The domain name to check.
    ///   - recordTypes: The record types to query. If nil, uses the configured defaults.
    ///   - pollingConfiguration: The polling/backoff settings.
    /// - Returns: A ``DNSPropagationResult`` once propagation is confirmed.
    /// - Throws: ``DNSError/timeout(partialResult:)`` if propagation is not confirmed
    ///           within the timeout.
    public func waitForPropagation(
        domain: String,
        recordTypes: [DNSRecordType]? = nil,
        pollingConfiguration: PollingConfiguration = PollingConfiguration()
    ) async throws -> DNSPropagationResult {
        let checker = DNSPropagationChecker(
            client: self,
            pollingConfiguration: pollingConfiguration
        )
        return try await checker.waitForPropagation(
            domain: domain,
            recordTypes: recordTypes ?? configuration.recordTypes
        )
    }
}
