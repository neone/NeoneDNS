// NeoneDNS - DNS-over-HTTPS propagation checking library
//
// Usage:
//   let client = DNSClient()
//   let results = try await client.lookup(domain: "example.neone.cloud")
//   let propagation = try await client.waitForPropagation(domain: "example.neone.cloud")
