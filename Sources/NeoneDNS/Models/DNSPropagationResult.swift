import Foundation

/// The aggregated result of checking DNS propagation across multiple providers.
public struct DNSPropagationResult: Sendable {
    /// Individual results from each provider.
    public let providerResults: [DNSLookupResult]
    /// Whether propagation is considered complete (all providers returned records).
    public let isPropagated: Bool
    /// The total time elapsed during the propagation check.
    public let elapsed: Duration
    /// The number of polling attempts made.
    public let attempts: Int

    /// All unique records found across all providers.
    public var allRecords: [DNSRecord] {
        var seen = Set<DNSRecord>()
        return providerResults.flatMap(\.records).filter { seen.insert($0).inserted }
    }

    public init(
        providerResults: [DNSLookupResult],
        isPropagated: Bool,
        elapsed: Duration,
        attempts: Int
    ) {
        self.providerResults = providerResults
        self.isPropagated = isPropagated
        self.elapsed = elapsed
        self.attempts = attempts
    }
}
