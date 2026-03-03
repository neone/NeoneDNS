import Foundation

/// A single DNS record returned from a lookup.
public struct DNSRecord: Sendable, Codable, Hashable {
    /// The domain name this record belongs to.
    public let name: String
    /// The record type.
    public let type: DNSRecordType
    /// Time-to-live in seconds.
    public let ttl: Int
    /// The record data (e.g., IP address for A/AAAA, hostname for CNAME).
    public let data: String

    public init(name: String, type: DNSRecordType, ttl: Int, data: String) {
        self.name = name
        self.type = type
        self.ttl = ttl
        self.data = data
    }
}
