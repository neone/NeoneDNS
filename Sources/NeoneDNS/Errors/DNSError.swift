import Foundation

/// Errors that can occur during DNS operations.
public enum DNSError: Error, Sendable {
    /// A network request failed.
    case networkError(underlying: any Error & Sendable)
    /// The DNS provider returned an HTTP error status code.
    case httpError(statusCode: Int, providerName: String)
    /// The response body could not be decoded.
    case decodingError(underlying: any Error & Sendable, providerName: String)
    /// The DNS server returned a non-zero status (e.g., SERVFAIL, REFUSED).
    case dnsServerError(status: Int, statusDescription: String, providerName: String)
    /// The propagation check timed out before all providers returned records.
    case timeout(partialResult: DNSPropagationResult)
    /// The task was cancelled.
    case cancelled
    /// No providers were configured.
    case noProviders
    /// An invalid domain name was provided.
    case invalidDomain(String)
}

extension DNSError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .networkError(let underlying):
            "DNS network error: \(underlying.localizedDescription)"
        case .httpError(let statusCode, let provider):
            "DNS HTTP error \(statusCode) from \(provider)"
        case .decodingError(_, let provider):
            "Failed to decode DNS response from \(provider)"
        case .dnsServerError(_, let desc, let provider):
            "DNS server error \(desc) from \(provider)"
        case .timeout:
            "DNS propagation check timed out"
        case .cancelled:
            "DNS operation was cancelled"
        case .noProviders:
            "No DNS providers configured"
        case .invalidDomain(let domain):
            "Invalid domain name: \(domain)"
        }
    }
}
