import Foundation

/// Internal model matching the JSON response from both Google and Cloudflare DoH APIs.
struct DoHResponse: Codable, Sendable {
    let status: Int
    let tc: Bool
    let rd: Bool
    let ra: Bool
    let ad: Bool
    let cd: Bool
    let question: [DoHQuestion]?
    let answer: [DoHAnswer]?
    let authority: [DoHAnswer]?
    let comment: String?

    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case tc = "TC"
        case rd = "RD"
        case ra = "RA"
        case ad = "AD"
        case cd = "CD"
        case question = "Question"
        case answer = "Answer"
        case authority = "Authority"
        case comment = "Comment"
    }

    func toDNSRecords() -> [DNSRecord] {
        guard let answers = answer else { return [] }
        return answers.compactMap { answer in
            guard let recordType = DNSRecordType(rawValue: answer.type) else {
                return nil
            }
            return DNSRecord(
                name: answer.name,
                type: recordType,
                ttl: answer.ttl,
                data: answer.data
            )
        }
    }
}

struct DoHQuestion: Codable, Sendable {
    let name: String
    let type: Int
}

struct DoHAnswer: Codable, Sendable {
    let name: String
    let type: Int
    let ttl: Int
    let data: String

    enum CodingKeys: String, CodingKey {
        case name
        case type
        case ttl = "TTL"
        case data
    }
}
