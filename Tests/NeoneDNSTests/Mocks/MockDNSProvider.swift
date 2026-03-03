import Foundation
@testable import NeoneDNS

final class MockDNSProvider: DNSProvider, @unchecked Sendable {
    let name: String
    private let lock = NSLock()
    private var _results: [Result<DNSLookupResult, Error>] = []
    private var _lookupCount = 0

    var lookupCount: Int {
        lock.withLock { _lookupCount }
    }

    init(name: String = "Mock") {
        self.name = name
    }

    func enqueueResult(_ result: DNSLookupResult) {
        lock.withLock {
            _results.append(.success(result))
        }
    }

    func enqueueError(_ error: Error) {
        lock.withLock {
            _results.append(.failure(error))
        }
    }

    func lookup(domain: String, recordTypes: [DNSRecordType]) async throws -> DNSLookupResult {
        let result = lock.withLock { () -> Result<DNSLookupResult, Error> in
            _lookupCount += 1
            guard !_results.isEmpty else {
                fatalError("MockDNSProvider: no results enqueued")
            }
            return _results.removeFirst()
        }
        return try result.get()
    }
}
