import Testing
import Foundation
@testable import NeoneDNS

@Suite("DoH Response Decoding")
struct DoHResponseTests {

    @Test("Decodes A record response")
    func decodesARecord() throws {
        let response = try JSONDecoder().decode(DoHResponse.self, from: FixtureData.successARecord)

        #expect(response.status == 0)
        #expect(response.rd == true)
        #expect(response.ra == true)

        let records = response.toDNSRecords()
        #expect(records.count == 1)
        #expect(records[0].name == "example.com.")
        #expect(records[0].type == .a)
        #expect(records[0].ttl == 300)
        #expect(records[0].data == "93.184.216.34")
    }

    @Test("Decodes AAAA record response")
    func decodesAAAARecord() throws {
        let response = try JSONDecoder().decode(DoHResponse.self, from: FixtureData.successAAAARecord)

        let records = response.toDNSRecords()
        #expect(records.count == 1)
        #expect(records[0].type == .aaaa)
        #expect(records[0].data == "2606:2800:220:1:248:1893:25c8:1946")
    }

    @Test("Decodes CNAME record response")
    func decodesCNAMERecord() throws {
        let response = try JSONDecoder().decode(DoHResponse.self, from: FixtureData.successCNAMERecord)

        let records = response.toDNSRecords()
        #expect(records.count == 1)
        #expect(records[0].type == .cname)
        #expect(records[0].data == "example.com.")
    }

    @Test("Decodes NXDOMAIN response with no answers")
    func decodesNXDOMAIN() throws {
        let response = try JSONDecoder().decode(DoHResponse.self, from: FixtureData.nxdomainResponse)

        #expect(response.status == 3)
        let records = response.toDNSRecords()
        #expect(records.isEmpty)
    }

    @Test("Decodes response with no Answer field")
    func decodesNoAnswer() throws {
        let response = try JSONDecoder().decode(DoHResponse.self, from: FixtureData.noAnswerResponse)

        #expect(response.status == 0)
        #expect(response.answer == nil)
        let records = response.toDNSRecords()
        #expect(records.isEmpty)
    }

    @Test("Skips unsupported record types")
    func skipsUnsupportedTypes() throws {
        // SOA record (type 6) is not in DNSRecordType
        let json = """
        {
            "Status": 0,
            "TC": false,
            "RD": true,
            "RA": true,
            "AD": false,
            "CD": false,
            "Answer": [
                { "name": "example.com.", "type": 6, "TTL": 900, "data": "ns1.example.com." },
                { "name": "example.com.", "type": 1, "TTL": 300, "data": "1.2.3.4" }
            ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(DoHResponse.self, from: json)
        let records = response.toDNSRecords()
        #expect(records.count == 1)
        #expect(records[0].type == .a)
    }
}
