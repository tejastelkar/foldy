import AppKit
import CryptoKit
import Foundation

@MainActor
final class DirectLicenseStore: EntitlementStore {
    struct Payload: Codable {
        let licenseID: String
        let productID: String
        let issuedAt: Date
    }

    struct SignedLicense: Codable {
        let payload: Payload
        let signature: String
    }

    private(set) var state: EntitlementState = .locked
    private let publicKeyBase64: String
    private let checkoutURL: URL
    private let portalURL: URL

    init(publicKeyBase64: String, checkoutURL: URL, portalURL: URL) {
        self.publicKeyBase64 = publicKeyBase64
        self.checkoutURL = checkoutURL
        self.portalURL = portalURL
    }

    @discardableResult
    func importLicense(data: Data) -> Bool {
        guard let signedLicense = try? JSONDecoder().decode(SignedLicense.self, from: data),
              signedLicense.payload.productID == "lidbend-lifetime",
              let publicKeyData = Data(base64Encoded: publicKeyBase64),
              let signature = Data(base64Encoded: signedLicense.signature),
              let publicKey = try? Curve25519.Signing.PublicKey(rawRepresentation: publicKeyData),
              let payloadData = try? canonicalData(for: signedLicense.payload),
              publicKey.isValidSignature(signature, for: payloadData)
        else {
            state = .locked
            return false
        }

        state = .unlocked
        return true
    }

    func purchase() async throws {
        NSWorkspace.shared.open(checkoutURL)
    }

    func restore() async throws {
        NSWorkspace.shared.open(portalURL)
    }

    private func canonicalData(for payload: Payload) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(payload)
    }
}
