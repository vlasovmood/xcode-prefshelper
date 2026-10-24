import Foundation
import Security

/// Безопасное хранение чувствительных данных (паролей, токенов) в Keychain.
///
/// Записи сохраняются как generic password и привязываются к сервису из ``Configuration``
/// (по умолчанию — bundle identifier приложения), поэтому не пересекаются с записями
/// других библиотек. Для обмена данными с расширениями передайте конфигурацию с `accessGroup`.
public enum KeychainHelper {

    /// Когда запись доступна для чтения (`kSecAttrAccessible`).
    public enum Accessibility: Sendable {
        case whenUnlocked
        case whenUnlockedThisDeviceOnly
        case afterFirstUnlock
        case afterFirstUnlockThisDeviceOnly
        case whenPasscodeSetThisDeviceOnly

        fileprivate var attribute: CFString {
            switch self {
            case .whenUnlocked: return kSecAttrAccessibleWhenUnlocked
            case .whenUnlockedThisDeviceOnly: return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            case .afterFirstUnlock: return kSecAttrAccessibleAfterFirstUnlock
            case .afterFirstUnlockThisDeviceOnly: return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            case .whenPasscodeSetThisDeviceOnly: return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
            }
        }
    }

    /// Набор параметров, общих для группы записей.
    public struct Configuration: Sendable {
        /// `kSecAttrService`. `nil` — без сервиса, как сохраняли записи ранние версии PrefsHelper.
        public var service: String?
        /// `kSecAttrAccessGroup` для общего доступа из нескольких приложений и расширений.
        public var accessGroup: String?
        /// Применяется при создании записи.
        public var accessibility: Accessibility

        public init(service: String? = Bundle.main.bundleIdentifier ?? "PrefsHelper",
                    accessGroup: String? = nil,
                    accessibility: Accessibility = .whenUnlocked) {
            self.service = service
            self.accessGroup = accessGroup
            self.accessibility = accessibility
        }

        public static let standard = Configuration()
    }

    // MARK: - Чтение

    public static func get(key: String, in configuration: Configuration = .standard) -> String? {
        getData(key: key, in: configuration).flatMap { String(data: $0, encoding: .utf8) }
    }

    public static func getData(key: String, in configuration: Configuration = .standard) -> Data? {
        let query = configuration.query(key: key, [
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ])

        var result: AnyObject?
        guard SecItemCopyMatching(query, &result) == errSecSuccess else { return nil }
        return result as? Data
    }

    public static func exists(key: String, in configuration: Configuration = .standard) -> Bool {
        let query = configuration.query(key: key, [kSecMatchLimit as String: kSecMatchLimitOne])
        return SecItemCopyMatching(query, nil) == errSecSuccess
    }

    // MARK: - Запись

    /// Сохраняет строку: обновляет существующую запись или создаёт новую.
    @discardableResult
    public static func set(key: String, value: String, in configuration: Configuration = .standard) -> Bool {
        set(key: key, value: Data(value.utf8), in: configuration)
    }

    /// Сохраняет данные: обновляет существующую запись или создаёт новую.
    @discardableResult
    public static func set(key: String, value: Data, in configuration: Configuration = .standard) -> Bool {
        let status = SecItemUpdate(configuration.query(key: key), [kSecValueData as String: value] as CFDictionary)
        guard status == errSecItemNotFound else { return status == errSecSuccess }

        let newItem = configuration.query(key: key, [
            kSecValueData as String: value,
            kSecAttrAccessible as String: configuration.accessibility.attribute,
        ])
        return SecItemAdd(newItem, nil) == errSecSuccess
    }

    /// Обновляет только существующую запись. Возвращает `false`, если записи нет.
    @discardableResult
    public static func update(key: String, newValue: String, in configuration: Configuration = .standard) -> Bool {
        let attributes = [kSecValueData as String: Data(newValue.utf8)]
        return SecItemUpdate(configuration.query(key: key), attributes as CFDictionary) == errSecSuccess
    }

    // MARK: - Удаление

    /// Возвращает `true`, если записи больше нет, в том числе если её и не было.
    @discardableResult
    public static func delete(key: String, in configuration: Configuration = .standard) -> Bool {
        isDeleted(SecItemDelete(configuration.query(key: key)))
    }

    /// Удаляет все записи конфигурации (с её сервисом и группой доступа).
    @discardableResult
    public static func clearAll(in configuration: Configuration = .standard) -> Bool {
        #if os(macOS)
        // В файловой связке ключей macOS без kSecMatchLimitAll удаляется только первая найденная запись.
        let extra: [String: Any] = [kSecMatchLimit as String: kSecMatchLimitAll]
        #else
        let extra: [String: Any] = [:]
        #endif
        return isDeleted(SecItemDelete(configuration.query(key: nil, extra)))
    }

    private static func isDeleted(_ status: OSStatus) -> Bool {
        status == errSecSuccess || status == errSecItemNotFound
    }
}

private extension KeychainHelper.Configuration {
    /// Запрос к записям конфигурации; `key == nil` — ко всем записям.
    func query(key: String?, _ extra: [String: Any] = [:]) -> CFDictionary {
        var query: [String: Any] = [kSecClass as String: kSecClassGenericPassword]
        query[kSecAttrService as String] = service
        query[kSecAttrAccessGroup as String] = accessGroup
        query[kSecAttrAccount as String] = key
        return query.merging(extra) { _, new in new } as CFDictionary
    }
}
