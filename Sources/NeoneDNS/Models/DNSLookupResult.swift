import Foundation

/// The result of a DNS lookup from a single provider.
public struct DNSLookupResult: Sendable {
    /// The provider that performed this lookup.
    public let providerName: String
    /// The DNS records returned. Empty if the domain was not found.
    public let records: [DNSRecord]
    /// The DNS response status code (0 = NOERROR, 3 = NXDOMAIN, etc.).
    public let status: Int

    /// Whether this lookup returned at least one record.
    public var hasRecords: Bool { !records.isEmpty }

    /// A human-readable description of the DNS status code.
    public var statusDescription: String {
        switch status {
        case 0: "NOERROR"
        case 1: "FORMERR"
        case 2: "SERVFAIL"
        case 3: "NXDOMAIN"
        case 5: "REFUSED"
        default: "UNKNOWN(\(status))"
        }
    }

    public init(providerName: String, records: [DNSRecord], status: Int) {
        self.providerName = providerName
        self.records = records
        self.status = status
    }
}
