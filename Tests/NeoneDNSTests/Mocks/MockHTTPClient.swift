import Foundation
@testable import NeoneDNS

final class MockHTTPClient: HTTPClient, @unchecked Sendable {
    private let lock = NSLock()
    private var _responses: [(Data, URLResponse)] = []
    private var _errors: [Error?] = []
    private var _recordedRequests: [URLRequest] = []

    var recordedRequests: [URLRequest] {
        lock.withLock { _recordedRequests }
    }

    func enqueueResponse(data: Data, statusCode: Int = 200) {
        let response = HTTPURLResponse(
            url: URL(string: "https://mock")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        lock.withLock {
            _responses.append((data, response))
            _errors.append(nil)
        }
    }

    func enqueueError(_ error: Error) {
        lock.withLock {
            _responses.append((Data(), URLResponse()))
            _errors.append(error)
        }
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let (response, error) = lock.withLock { () -> ((Data, URLResponse), Error?) in
            _recordedRequests.append(request)
            guard !_responses.isEmpty else {
                fatalError("MockHTTPClient: no responses enqueued")
            }
            let resp = _responses.removeFirst()
            let err = _errors.removeFirst()
            return (resp, err)
        }

        if let error { throw error }
        return response
    }
}
