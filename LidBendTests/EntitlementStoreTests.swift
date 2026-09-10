import XCTest
@testable import LidBend

@MainActor
final class EntitlementStoreTests: XCTestCase {
    func testDevelopmentStoreReflectsConfiguredUnlock() {
        XCTAssertEqual(LocalEntitlementStore(unlocked: true).state, .unlocked)
        XCTAssertEqual(LocalEntitlementStore(unlocked: false).state, .locked)
    }

    func testMalformedDirectLicenseStaysLocked() {
        let store = DirectLicenseStore(
            publicKeyBase64: "not-a-key",
            checkoutURL: URL(string: "https://example.com/buy")!,
            portalURL: URL(string: "https://example.com/account")!
        )

        XCTAssertFalse(store.importLicense(data: Data("invalid".utf8)))
        XCTAssertEqual(store.state, .locked)
    }
}
