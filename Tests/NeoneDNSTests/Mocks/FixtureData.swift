import Foundation

enum FixtureData {
    /// A successful DoH response with an A record for "example.com" -> "93.184.216.34"
    static let successARecord = """
    {
        "Status": 0,
        "TC": false,
        "RD": true,
        "RA": true,
        "AD": false,
        "CD": false,
        "Question": [
            { "name": "example.com.", "type": 1 }
        ],
        "Answer": [
            { "name": "example.com.", "type": 1, "TTL": 300, "data": "93.184.216.34" }
        ]
    }
    """.data(using: .utf8)!

    /// A successful DoH response with an AAAA record
    static let successAAAARecord = """
    {
        "Status": 0,
        "TC": false,
        "RD": true,
        "RA": true,
        "AD": false,
        "CD": false,
        "Question": [
            { "name": "example.com.", "type": 28 }
        ],
        "Answer": [
            { "name": "example.com.", "type": 28, "TTL": 300, "data": "2606:2800:220:1:248:1893:25c8:1946" }
        ]
    }
    """.data(using: .utf8)!

    /// A successful DoH response with a CNAME record
    static let successCNAMERecord = """
    {
        "Status": 0,
        "TC": false,
        "RD": true,
        "RA": true,
        "AD": false,
        "CD": false,
        "Question": [
            { "name": "www.example.com.", "type": 5 }
        ],
        "Answer": [
            { "name": "www.example.com.", "type": 5, "TTL": 3600, "data": "example.com." }
        ]
    }
    """.data(using: .utf8)!

    /// An NXDOMAIN response (domain not found)
    static let nxdomainResponse = """
    {
        "Status": 3,
        "TC": false,
        "RD": true,
        "RA": true,
        "AD": false,
        "CD": false,
        "Question": [
            { "name": "nonexistent.example.com.", "type": 1 }
        ],
        "Authority": [
            { "name": "example.com.", "type": 6, "TTL": 900, "data": "ns1.example.com. admin.example.com. 2024010101 7200 3600 1209600 900" }
        ]
    }
    """.data(using: .utf8)!

    /// A NOERROR response with no answers (empty result)
    static let noAnswerResponse = """
    {
        "Status": 0,
        "TC": false,
        "RD": true,
        "RA": true,
        "AD": false,
        "CD": false,
        "Question": [
            { "name": "example.com.", "type": 28 }
        ]
    }
    """.data(using: .utf8)!

    /// A SERVFAIL response
    static let servfailResponse = """
    {
        "Status": 2,
        "TC": false,
        "RD": true,
        "RA": true,
        "AD": false,
        "CD": false,
        "Question": [
            { "name": "example.com.", "type": 1 }
        ]
    }
    """.data(using: .utf8)!
}
