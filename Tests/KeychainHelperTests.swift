import XCTest
import PrefsHelper

final class KeychainHelperTests: XCTestCase {

    private let keychain = KeychainHelper.Configuration(service: "PrefsHelperTests")

    override func tearDown() {
        KeychainHelper.clearAll(in: keychain)
        super.tearDown()
    }

    func testSetGetDelete() {
        XCTAssertTrue(KeychainHelper.set(key: "token", value: "abc", in: keychain))
        XCTAssertEqual(KeychainHelper.get(key: "token", in: keychain), "abc")
        XCTAssertTrue(KeychainHelper.exists(key: "token", in: keychain))

        XCTAssertTrue(KeychainHelper.delete(key: "token", in: keychain))
        XCTAssertNil(KeychainHelper.get(key: "token", in: keychain))
        XCTAssertFalse(KeychainHelper.exists(key: "token", in: keychain))
    }

    func testSetOverwritesExistingValue() {
        KeychainHelper.set(key: "token", value: "old", in: keychain)
        KeychainHelper.set(key: "token", value: "new", in: keychain)
        XCTAssertEqual(KeychainHelper.get(key: "token", in: keychain), "new")
    }

    func testUpdateRequiresExistingItem() {
        XCTAssertFalse(KeychainHelper.update(key: "missing", newValue: "x", in: keychain))

        KeychainHelper.set(key: "token", value: "old", in: keychain)
        XCTAssertTrue(KeychainHelper.update(key: "token", newValue: "new", in: keychain))
        XCTAssertEqual(KeychainHelper.get(key: "token", in: keychain), "new")
    }

    func testServicesAreIsolated() {
        let other = KeychainHelper.Configuration(service: "PrefsHelperTests.other")
        defer { KeychainHelper.clearAll(in: other) }

        KeychainHelper.set(key: "token", value: "abc", in: keychain)
        XCTAssertNil(KeychainHelper.get(key: "token", in: other))
    }

    func testClearAll() {
        KeychainHelper.set(key: "a", value: "1", in: keychain)
        KeychainHelper.set(key: "b", value: "2", in: keychain)

        XCTAssertTrue(KeychainHelper.clearAll(in: keychain))
        XCTAssertFalse(KeychainHelper.exists(key: "a", in: keychain))
        XCTAssertFalse(KeychainHelper.exists(key: "b", in: keychain))
    }
}
