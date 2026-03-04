import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Shared logic for building and executing DoH requests.
/// Both Google and Cloudflare providers delegate to this.
struct DoHRequestExecutor: Sendable {
    let httpClient: any HTTPClient
    let baseURL: String
    let providerName: String

    func lookup(domain: String, recordTypes: [DNSRecordType]) async throws -> DNSLookupResult {
        var allRecords: [DNSRecord] = []
        var lastStatus = 0

        for recordType in recordTypes {
            let request = try buildRequest(domain: domain, recordType: recordType)
            let (data, response) = try await execute(request)
            try validateHTTP(response)
            let dohResponse = try decode(data)

            if dohResponse.status != 0 && dohResponse.status != 3 {
                throw DNSError.dnsServerError(
                    status: dohResponse.status,
                    statusDescription: statusDescription(dohResponse.status),
                    providerName: providerName
                )
            }
            lastStatus = dohResponse.status
            allRecords.append(contentsOf: dohResponse.toDNSRecords())
        }

        return DNSLookupResult(
            providerName: providerName,
            records: allRecords,
            status: lastStatus
        )
    }

    private func buildRequest(domain: String, recordType: DNSRecordType) throws -> URLRequest {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "name", value: domain),
            URLQueryItem(name: "type", value: String(recordType.rawValue)),
        ]
        guard let url = components.url else {
            throw DNSError.invalidDomain(domain)
        }
        var request = URLRequest(url: url)
        request.setValue("application/dns-json", forHTTPHeaderField: "Accept")
        return request
    }

    private func execute(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await httpClient.data(for: request)
        } catch let error as DNSError {
            throw error
        } catch {
            throw DNSError.networkError(underlying: error)
        }
    }

    private func validateHTTP(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else { return }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw DNSError.httpError(statusCode: httpResponse.statusCode, providerName: providerName)
        }
    }

    private func decode(_ data: Data) throws -> DoHResponse {
        do {
            return try JSONDecoder().decode(DoHResponse.self, from: data)
        } catch {
            throw DNSError.decodingError(underlying: error, providerName: providerName)
        }
    }

    private func statusDescription(_ status: Int) -> String {
        switch status {
        case 0: "NOERROR"
        case 1: "FORMERR"
        case 2: "SERVFAIL"
        case 3: "NXDOMAIN"
        case 5: "REFUSED"
        default: "UNKNOWN(\(status))"
        }
    }
}
