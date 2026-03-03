import Testing
import Foundation
@testable import NeoneDNS

@Suite("DNS Propagation Checker")
struct DNSPropagationCheckerTests {

    @Test("Returns immediately when all providers have records")
    func returnsImmediatelyOnPropagation() async throws {
        let provider1 = MockDNSProvider(name: "Provider1")
        let provider2 = MockDNSProvider(name: "Provider2")

        let record = DNSRecord(name: "space.neone.cloud.", type: .a, ttl: 300, data: "1.2.3.4")
        provider1.enqueueResult(DNSLookupResult(providerName: "Provider1", records: [record], status: 0))
        provider2.enqueueResult(DNSLookupResult(providerName: "Provider2", records: [record], status: 0))

        let config = DNSClientConfiguration(providers: [provider1, provider2], recordTypes: [.a])
        let client = DNSClient(configuration: config)

        let result = try await client.waitForPropagation(
            domain: "space.neone.cloud",
            pollingConfiguration: .fast
        )

        #expect(result.isPropagated == true)
        #expect(result.attempts == 1)
        #expect(result.allRecords.count == 1)
    }

    @Test("Polls until propagation is complete")
    func pollsUntilPropagated() async throws {
        let provider1 = MockDNSProvider(name: "Provider1")
        let provider2 = MockDNSProvider(name: "Provider2")

        let record = DNSRecord(name: "space.neone.cloud.", type: .a, ttl: 300, data: "1.2.3.4")

        // First attempt: provider1 has records, provider2 does not
        provider1.enqueueResult(DNSLookupResult(providerName: "Provider1", records: [record], status: 0))
        provider2.enqueueResult(DNSLookupResult(providerName: "Provider2", records: [], status: 3))

        // Second attempt: both have records
        provider1.enqueueResult(DNSLookupResult(providerName: "Provider1", records: [record], status: 0))
        provider2.enqueueResult(DNSLookupResult(providerName: "Provider2", records: [record], status: 0))

        let config = DNSClientConfiguration(providers: [provider1, provider2], recordTypes: [.a])
        let client = DNSClient(configuration: config)

        let polling = PollingConfiguration(
            initialInterval: .milliseconds(50),
            maxInterval: .milliseconds(100),
            timeout: .seconds(5),
            backoffMultiplier: 1.0
        )

        let result = try await client.waitForPropagation(
            domain: "space.neone.cloud",
            pollingConfiguration: polling
        )

        #expect(result.isPropagated == true)
        #expect(result.attempts == 2)
    }

    @Test("Throws timeout with partial result")
    func throwsTimeoutWithPartialResult() async {
        let provider = MockDNSProvider(name: "SlowProvider")

        // Always returns no records
        for _ in 0..<100 {
            provider.enqueueResult(DNSLookupResult(providerName: "SlowProvider", records: [], status: 3))
        }

        let config = DNSClientConfiguration(providers: [provider], recordTypes: [.a])
        let client = DNSClient(configuration: config)

        let polling = PollingConfiguration(
            initialInterval: .milliseconds(10),
            maxInterval: .milliseconds(50),
            timeout: .milliseconds(200),
            backoffMultiplier: 1.0
        )

        do {
            _ = try await client.waitForPropagation(
                domain: "nonexistent.neone.cloud",
                pollingConfiguration: polling
            )
            Issue.record("Expected DNSError.timeout")
        } catch let error as DNSError {
            guard case .timeout(let partialResult) = error else {
                Issue.record("Expected timeout, got \(error)")
                return
            }
            #expect(partialResult.isPropagated == false)
            #expect(partialResult.attempts > 0)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Propagation result deduplicates records")
    func deduplicatesRecords() {
        let record = DNSRecord(name: "test.com.", type: .a, ttl: 300, data: "1.2.3.4")

        let result = DNSPropagationResult(
            providerResults: [
                DNSLookupResult(providerName: "A", records: [record], status: 0),
                DNSLookupResult(providerName: "B", records: [record], status: 0),
            ],
            isPropagated: true,
            elapsed: .seconds(1),
            attempts: 1
        )

        #expect(result.allRecords.count == 1)
    }

    @Test("DNSLookupResult status descriptions")
    func statusDescriptions() {
        let noerror = DNSLookupResult(providerName: "T", records: [], status: 0)
        #expect(noerror.statusDescription == "NOERROR")

        let nxdomain = DNSLookupResult(providerName: "T", records: [], status: 3)
        #expect(nxdomain.statusDescription == "NXDOMAIN")

        let servfail = DNSLookupResult(providerName: "T", records: [], status: 2)
        #expect(servfail.statusDescription == "SERVFAIL")

        let unknown = DNSLookupResult(providerName: "T", records: [], status: 99)
        #expect(unknown.statusDescription == "UNKNOWN(99)")
    }
}
