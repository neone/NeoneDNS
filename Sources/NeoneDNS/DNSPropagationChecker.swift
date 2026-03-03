import Foundation

/// Internal type that implements the polling loop with exponential backoff.
struct DNSPropagationChecker: Sendable {
    private let client: DNSClient
    private let pollingConfiguration: PollingConfiguration

    init(client: DNSClient, pollingConfiguration: PollingConfiguration) {
        self.client = client
        self.pollingConfiguration = pollingConfiguration
    }

    func waitForPropagation(
        domain: String,
        recordTypes: [DNSRecordType]
    ) async throws -> DNSPropagationResult {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: pollingConfiguration.timeout)
        var currentInterval = pollingConfiguration.initialInterval
        var attempts = 0
        let startTime = clock.now

        while clock.now < deadline {
            try Task.checkCancellation()

            attempts += 1

            let results: [DNSLookupResult]
            do {
                results = try await client.lookup(
                    domain: domain,
                    recordTypes: recordTypes
                )
            } catch is CancellationError {
                throw DNSError.cancelled
            } catch {
                // On transient errors, continue polling rather than failing immediately
                if clock.now.advanced(by: currentInterval) >= deadline {
                    throw error
                }
                try await Task.sleep(for: currentInterval)
                currentInterval = nextInterval(currentInterval)
                continue
            }

            let allPropagated = results.allSatisfy(\.hasRecords)

            if allPropagated {
                let elapsed = clock.now - startTime
                return DNSPropagationResult(
                    providerResults: results,
                    isPropagated: true,
                    elapsed: elapsed,
                    attempts: attempts
                )
            }

            // Not yet propagated; check if we have time for another attempt
            if clock.now.advanced(by: currentInterval) >= deadline {
                let elapsed = clock.now - startTime
                throw DNSError.timeout(
                    partialResult: DNSPropagationResult(
                        providerResults: results,
                        isPropagated: false,
                        elapsed: elapsed,
                        attempts: attempts
                    )
                )
            }

            try await Task.sleep(for: currentInterval)
            currentInterval = nextInterval(currentInterval)
        }

        throw DNSError.timeout(
            partialResult: DNSPropagationResult(
                providerResults: [],
                isPropagated: false,
                elapsed: clock.now - startTime,
                attempts: attempts
            )
        )
    }

    private func nextInterval(_ current: Duration) -> Duration {
        let next = current * pollingConfiguration.backoffMultiplier
        return min(next, pollingConfiguration.maxInterval)
    }
}
