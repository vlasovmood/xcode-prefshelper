import Foundation

/// Хранение простых настроек и флагов в `UserDefaults`.
///
/// Все методы принимают необязательный параметр `defaults`, поэтому помимо
/// `UserDefaults.standard` можно работать, например, с App Group: `UserDefaults(suiteName:)`.
public enum UserDefaultsHelper {

    /// Сохраняет значение property list-типа: `String`, `Int`, `Double`, `Bool`, `Date`, `Data`,
    /// а также массивы и словари из них. Значение `nil` удаляет ключ.
    /// Для собственных типов используйте ``setCodable(key:value:in:)``.
    public static func set<T>(key: String, value: T?, in defaults: UserDefaults = .standard) {
        defaults.set(value, forKey: key)
    }

    /// Возвращает значение по ключу или `nil`, если ключа нет или тип не совпадает.
    public static func get<T>(key: String, as type: T.Type = T.self, in defaults: UserDefaults = .standard) -> T? {
        defaults.object(forKey: key) as? T
    }

    /// Сохраняет любое `Encodable`-значение в виде JSON. Значение `nil` удаляет ключ.
    public static func setCodable<T: Encodable>(key: String, value: T?, in defaults: UserDefaults = .standard) throws {
        guard let value else {
            defaults.removeObject(forKey: key)
            return
        }
        defaults.set(try JSONEncoder().encode(value), forKey: key)
    }

    /// Возвращает значение, сохранённое через ``setCodable(key:value:in:)``, или `nil`, если ключа нет.
    public static func getCodable<T: Decodable>(key: String, as type: T.Type = T.self, in defaults: UserDefaults = .standard) throws -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }

    public static func delete(key: String, in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }

    public static func exists(key: String, in defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: key) != nil
    }

    /// Удаляет все значения, сохранённые приложением в указанном хранилище.
    public static func clearAll(in defaults: UserDefaults = .standard) {
        if defaults === UserDefaults.standard, let domain = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: domain)
        } else {
            defaults.dictionaryRepresentation().keys.forEach(defaults.removeObject(forKey:))
        }
    }
}
