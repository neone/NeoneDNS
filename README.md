# NeoneDNS

A Swift 6 library for checking DNS propagation via DNS-over-HTTPS (DoH). Works on iOS, macOS, and Linux (Vapor).

## Overview

When a new Neone space is created, a subdomain `<space-id>.neone.cloud` is registered. NeoneDNS verifies that DNS records have propagated globally before allowing dependent actions (e.g., requesting one-time passcodes).

It queries multiple public DNS providers (Google DNS + Cloudflare) concurrently and considers a domain propagated only when **all providers** return matching records.

## Installation

Add NeoneDNS to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/user/NeoneDNS.git", from: "1.0.0"),
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["NeoneDNS"]
    ),
]
```

## Quick Start

```swift
import NeoneDNS

let client = DNSClient()

// Single check — is the domain resolvable right now?
let results = try await client.lookup(domain: "my-space.neone.cloud")
for result in results {
    print("\(result.providerName): \(result.hasRecords ? "resolved" : result.statusDescription)")
}

// Wait for propagation — polls until all providers see the record
let propagation = try await client.waitForPropagation(
    domain: "my-space.neone.cloud"
)
if propagation.isPropagated {
    // Safe to proceed with OTP requests, etc.
}
```

## API

### DNSClient

The primary entry point. Created with sensible defaults (Google + Cloudflare providers, queries A/AAAA/CNAME records).

```swift
// Default configuration
let client = DNSClient()

// Custom configuration
let client = DNSClient(configuration: DNSClientConfiguration(
    providers: [GoogleDNSProvider(), CloudflareDNSProvider()],
    recordTypes: [.a],
    session: .shared
))
```

#### `lookup(domain:recordTypes:)`

Performs a one-off DNS lookup across all configured providers concurrently.

```swift
let results = try await client.lookup(domain: "example.neone.cloud")
// Returns [DNSLookupResult] — one per provider
```

#### `waitForPropagation(domain:recordTypes:pollingConfiguration:)`

Polls all providers with exponential backoff until consensus is reached or the timeout expires.

```swift
let result = try await client.waitForPropagation(
    domain: "example.neone.cloud",
    pollingConfiguration: .fast // 1s initial, 5s max, 60s timeout
)
```

### PollingConfiguration

Controls the backoff behavior during propagation checks.

| Property | Default | Description |
|---|---|---|
| `initialInterval` | 2s | Time before the first retry |
| `maxInterval` | 30s | Backoff cap |
| `timeout` | 5min | Total time before giving up |
| `backoffMultiplier` | 1.5 | Multiplier applied after each poll |

Built-in presets:

```swift
// Quick checks (testing, short-lived operations)
.fast    // 1s initial, 5s max, 60s timeout, 1.2x backoff

// Long-running production checks
.patient // 5s initial, 60s max, 10min timeout, 2.0x backoff
```

### Result Types

**`DNSLookupResult`** — per-provider result:
- `providerName: String` — e.g., "Google", "Cloudflare"
- `records: [DNSRecord]` — resolved DNS records
- `status: Int` — DNS status code (0 = NOERROR, 3 = NXDOMAIN)
- `hasRecords: Bool` — whether any records were returned
- `statusDescription: String` — human-readable status

**`DNSPropagationResult`** — aggregated result:
- `isPropagated: Bool` — true when all providers returned records
- `providerResults: [DNSLookupResult]` — individual provider results
- `elapsed: Duration` — total time spent checking
- `attempts: Int` — number of polling attempts
- `allRecords: [DNSRecord]` — deduplicated records across providers

**`DNSRecord`** — a single DNS record:
- `name: String` — domain name
- `type: DNSRecordType` — `.a`, `.aaaa`, or `.cname`
- `ttl: Int` — time-to-live in seconds
- `data: String` — record value (IP address or hostname)

### Error Handling

All errors are thrown as `DNSError`:

```swift
do {
    let result = try await client.waitForPropagation(domain: "space.neone.cloud")
} catch let error as DNSError {
    switch error {
    case .timeout(let partialResult):
        // Inspect which providers propagated and which didn't
        for pr in partialResult.providerResults {
            print("\(pr.providerName): \(pr.hasRecords ? "ready" : "pending")")
        }
    case .networkError(let underlying):
        print("Network issue: \(underlying)")
    case .httpError(let statusCode, let provider):
        print("\(provider) returned HTTP \(statusCode)")
    default:
        print(error.localizedDescription)
    }
}
```

### Custom Providers

Implement the `DNSProvider` protocol to add your own DNS resolver:

```swift
struct Quad9Provider: DNSProvider {
    let name = "Quad9"

    func lookup(domain: String, recordTypes: [DNSRecordType]) async throws -> DNSLookupResult {
        // Your implementation here
    }
}

let config = DNSClientConfiguration(
    providers: [GoogleDNSProvider(), CloudflareDNSProvider(), Quad9Provider()]
)
let client = DNSClient(configuration: config)
```

## Platforms

| Platform | Minimum Version |
|---|---|
| macOS | 13.0 |
| iOS | 16.0 |
| Linux | Swift 5.9+ |

## Requirements

- Swift 6.0+
- No external dependencies
