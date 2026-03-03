import Testing
import Foundation
@testable import NeoneDNS

@Suite("DNS Client")
struct DNSClientTests {

    @Test("Lookup queries all providers concurrently")
    func lookupQueriesAllProviders() async throws {
        let provider1 = MockDNSProvider(name: "Provider1")
        let provider2 = MockDNSProvider(name: "Provider2")

        let record = DNSRecord(name: "example.com.", type: .a, ttl: 300, data: "1.2.3.4")
        provider1.enqueueResult(DNSLookupResult(providerName: "Provider1", records: [record], status: 0))
        provider2.enqueueResult(DNSLookupResult(providerName: "Provider2", records: [record], status: 0))

        let config = DNSClientConfiguration(providers: [provider1, provider2], recordTypes: [.a])
        let client = DNSClient(configuration: config)

        let results = try await client.lookup(domain: "example.com")

        #expect(results.count == 2)
        #expect(provider1.lookupCount == 1)
        #expect(provider2.lookupCount == 1)
    }

    @Test("Lookup throws noProviders when empty")
    func lookupThrowsNoProviders() async {
        let config = DNSClientConfiguration(providers: [], recordTypes: [.a])
        let client = DNSClient(configuration: config)

        do {
            _ = try await client.lookup(domain: "example.com")
            Issue.record("Expected DNSError.noProviders")
        } catch let error as DNSError {
            guard case .noProviders = error else {
                Issue.record("Expected noProviders, got \(error)")
                return
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Lookup with custom record types overrides defaults")
    func lookupWithCustomRecordTypes() async throws {
        let provider = MockDNSProvider(name: "Test")
        provider.enqueueResult(DNSLookupResult(providerName: "Test", records: [], status: 3))

        let config = DNSClientConfiguration(providers: [provider], recordTypes: [.a, .aaaa])
        let client = DNSClient(configuration: config)

        _ = try await client.lookup(domain: "example.com", recordTypes: [.cname])

        #expect(provider.lookupCount == 1)
    }

    @Test("Google provider builds correct request URL")
    func googleProviderRequestURL() async throws {
        let mockHTTP = MockHTTPClient()
        mockHTTP.enqueueResponse(data: FixtureData.successARecord)

        let provider = GoogleDNSProvider(httpClient: mockHTTP)
        _ = try await provider.lookup(domain: "test.neone.cloud", recordTypes: [.a])

        #expect(mockHTTP.recordedRequests.count == 1)
        let url = mockHTTP.recordedRequests[0].url!
        #expect(url.host == "dns.google")
        #expect(url.path == "/resolve")
        #expect(url.query!.contains("name=test.neone.cloud"))
        #expect(url.query!.contains("type=1"))
    }

    @Test("Cloudflare provider builds correct request URL")
    func cloudflareProviderRequestURL() async throws {
        let mockHTTP = MockHTTPClient()
        mockHTTP.enqueueResponse(data: FixtureData.successARecord)

        let provider = CloudflareDNSProvider(httpClient: mockHTTP)
        _ = try await provider.lookup(domain: "test.neone.cloud", recordTypes: [.a])

        #expect(mockHTTP.recordedRequests.count == 1)
        let url = mockHTTP.recordedRequests[0].url!
        #expect(url.host == "cloudflare-dns.com")
        #expect(url.path == "/dns-query")
    }

    @Test("Provider sets Accept header for DNS JSON")
    func providerSetsAcceptHeader() async throws {
        let mockHTTP = MockHTTPClient()
        mockHTTP.enqueueResponse(data: FixtureData.successARecord)

        let provider = GoogleDNSProvider(httpClient: mockHTTP)
        _ = try await provider.lookup(domain: "test.com", recordTypes: [.a])

        let accept = mockHTTP.recordedRequests[0].value(forHTTPHeaderField: "Accept")
        #expect(accept == "application/dns-json")
    }

    @Test("Provider throws httpError on non-2xx response")
    func providerThrowsHTTPError() async {
        let mockHTTP = MockHTTPClient()
        mockHTTP.enqueueResponse(data: Data(), statusCode: 503)

        let provider = GoogleDNSProvider(httpClient: mockHTTP)

        do {
            _ = try await provider.lookup(domain: "test.com", recordTypes: [.a])
            Issue.record("Expected DNSError.httpError")
        } catch let error as DNSError {
            guard case .httpError(let code, let name) = error else {
                Issue.record("Expected httpError, got \(error)")
                return
            }
            #expect(code == 503)
            #expect(name == "Google")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Provider throws dnsServerError on SERVFAIL")
    func providerThrowsDNSServerError() async {
        let mockHTTP = MockHTTPClient()
        mockHTTP.enqueueResponse(data: FixtureData.servfailResponse)

        let provider = GoogleDNSProvider(httpClient: mockHTTP)

        do {
            _ = try await provider.lookup(domain: "test.com", recordTypes: [.a])
            Issue.record("Expected DNSError.dnsServerError")
        } catch let error as DNSError {
            guard case .dnsServerError(let status, _, _) = error else {
                Issue.record("Expected dnsServerError, got \(error)")
                return
            }
            #expect(status == 2)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Provider queries multiple record types")
    func providerQueriesMultipleTypes() async throws {
        let mockHTTP = MockHTTPClient()
        mockHTTP.enqueueResponse(data: FixtureData.successARecord)
        mockHTTP.enqueueResponse(data: FixtureData.noAnswerResponse)

        let provider = GoogleDNSProvider(httpClient: mockHTTP)
        let result = try await provider.lookup(domain: "test.com", recordTypes: [.a, .aaaa])

        #expect(mockHTTP.recordedRequests.count == 2)
        #expect(result.records.count == 1)
        #expect(result.records[0].type == .a)
    }
}
