import Foundation

/// DNS record types supported by NeoneDNS.
public enum DNSRecordType: Int, Sendable, Codable, CaseIterable {
    case a = 1
    case aaaa = 28
    case cname = 5

    /// The string representation used in DNS queries (e.g., "A", "AAAA", "CNAME").
    public var stringValue: String {
        switch self {
        case .a: "A"
        case .aaaa: "AAAA"
        case .cname: "CNAME"
        }
    }
}
