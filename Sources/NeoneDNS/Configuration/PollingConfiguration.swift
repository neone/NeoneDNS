import Foundation

/// Configuration for the polling/backoff mechanism used during propagation checks.
public struct PollingConfiguration: Sendable {
    /// The initial interval between polls. Default: 2 seconds.
    public let initialInterval: Duration

    /// The maximum interval between polls (backoff cap). Default: 30 seconds.
    public let maxInterval: Duration

    /// The total timeout for the propagation check. Default: 5 minutes.
    public let timeout: Duration

    /// The multiplier applied to the interval after each poll. Default: 1.5.
    public let backoffMultiplier: Double

    /// Creates a polling configuration.
    public init(
        initialInterval: Duration = .seconds(2),
        maxInterval: Duration = .seconds(30),
        timeout: Duration = .seconds(300),
        backoffMultiplier: Double = 1.5
    ) {
        self.initialInterval = initialInterval
        self.maxInterval = maxInterval
        self.timeout = timeout
        self.backoffMultiplier = backoffMultiplier
    }

    /// A fast configuration suitable for testing or impatient callers.
    public static let fast = PollingConfiguration(
        initialInterval: .seconds(1),
        maxInterval: .seconds(5),
        timeout: .seconds(60),
        backoffMultiplier: 1.2
    )

    /// A patient configuration for production use with longer timeouts.
    public static let patient = PollingConfiguration(
        initialInterval: .seconds(5),
        maxInterval: .seconds(60),
        timeout: .seconds(600),
        backoffMultiplier: 2.0
    )
}
