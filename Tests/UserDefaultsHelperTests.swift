import XCTest
import PrefsHelper

final class UserDefaultsHelperTests: XCTestCase {

    private let suiteName = "PrefsHelperTests"
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func testSetGetDelete() {
        UserDefaultsHelper.set(key: "name", value: "John", in: defaults)
        XCTAssertEqual(UserDefaultsHelper.get(key: "name", as: String.self, in: defaults), "John")
        XCTAssertTrue(UserDefaultsHelper.exists(key: "name", in: defaults))

        UserDefaultsHelper.delete(key: "name", in: defaults)
        XCTAssertNil(UserDefaultsHelper.get(key: "name", as: String.self, in: defaults))
        XCTAssertFalse(UserDefaultsHelper.exists(key: "name", in: defaults))
    }

    func testSettingNilRemovesValue() {
        UserDefaultsHelper.set(key: "count", value: 1, in: defaults)
        let none: Int? = nil
        UserDefaultsHelper.set(key: "count", value: none, in: defaults)
        XCTAssertFalse(UserDefaultsHelper.exists(key: "count", in: defaults))
    }

    func testCodableRoundTrip() throws {
        struct Settings: Codable, Equatable {
            var theme: String
            var fontSize: Int
        }
        let settings = Settings(theme: "dark", fontSize: 14)

        try UserDefaultsHelper.setCodable(key: "settings", value: settings, in: defaults)
        XCTAssertEqual(try UserDefaultsHelper.getCodable(key: "settings", as: Settings.self, in: defaults), settings)
    }

    func testClearAll() {
        UserDefaultsHelper.set(key: "a", value: 1, in: defaults)
        UserDefaultsHelper.set(key: "b", value: "two", in: defaults)

        UserDefaultsHelper.clearAll(in: defaults)
        XCTAssertFalse(UserDefaultsHelper.exists(key: "a", in: defaults))
        XCTAssertFalse(UserDefaultsHelper.exists(key: "b", in: defaults))
    }
}
