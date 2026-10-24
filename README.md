# XCode-PrefsHelper
**XCode PrefsHelper** — это универсальный и удобный пакет для хранения, обновления и удаления данных в приложениях на iOS и macOS. Этот пакет предоставляет простой интерфейс для работы с различными типами хранилищ данных, такими как **UserDefaults**, **Keychain**, **Core Data** и **CloudKit**, что позволяет вам эффективно управлять пользовательскими настройками и конфигурациями приложения.

## Особенности

- **UserDefaults**: для хранения простых настроек и предпочтений пользователя, включая собственные `Codable`-типы.
- **Keychain**: для безопасного хранения чувствительных данных, таких как пароли и токены.
- **Core Data**: для хранения структурированных данных с типобезопасными запросами.
- **CloudKit**: для синхронизации данных в облаке и обмена ими между устройствами. Поддерживаются `async/await` и completion handler.
- Поддержка создания, чтения, обновления и удаления данных.
- Простота в использовании с минимальной настройкой.

## Требования

- iOS 15+ / macOS 12+
- Swift 5.9+ (Xcode 15+)

## Установка

### Swift Package Manager

В Xcode: **File → Add Package Dependencies…** и укажите URL репозитория:

```
https://github.com/vlasovmood/XCode-PrefsHelper.git
```

Или добавьте зависимость в `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/vlasovmood/XCode-PrefsHelper.git", branch: "main"),
],
targets: [
    .target(name: "MyApp", dependencies: [
        .product(name: "PrefsHelper", package: "XCode-PrefsHelper"),
    ]),
]
```

Затем подключите модуль:

```swift
import PrefsHelper
```

### Вручную

Скопируйте файлы из папки `Source` в ваш проект. В этом случае `import PrefsHelper` не нужен.

## Использование

### UserDefaultsHelper

Для хранения простых данных, таких как настройки интерфейса или флаги.

#### Пример использования:

```swift
// Сохранить значение в UserDefaults
UserDefaultsHelper.set(key: "username", value: "john_doe")

// Получить значение из UserDefaults
if let username: String = UserDefaultsHelper.get(key: "username") {
    print("Имя пользователя: \(username)")
}
// или с явным указанием типа
let launchCount = UserDefaultsHelper.get(key: "launchCount", as: Int.self) ?? 0

// Удалить значение из UserDefaults
UserDefaultsHelper.delete(key: "username")
```

Собственные типы сохраняются через `Codable`:

```swift
struct Settings: Codable {
    var theme: String
    var fontSize: Int
}

try UserDefaultsHelper.setCodable(key: "settings", value: Settings(theme: "dark", fontSize: 14))
let settings = try UserDefaultsHelper.getCodable(key: "settings", as: Settings.self)
```

Для App Group передайте своё хранилище в параметр `in`:

```swift
let shared = UserDefaults(suiteName: "group.com.example.app")!
UserDefaultsHelper.set(key: "isPremium", value: true, in: shared)
```

### KeychainHelper

Для безопасного хранения чувствительных данных, таких как пароли, токены доступа и другой конфиденциальной информации.

#### Пример использования:

```swift
// Сохранить данные в Keychain (существующая запись будет перезаписана)
KeychainHelper.set(key: "authToken", value: "abc123securetoken")

// Получить данные из Keychain
if let authToken = KeychainHelper.get(key: "authToken") {
    print("Токен авторизации: \(authToken)")
}

// Удалить данные из Keychain
KeychainHelper.delete(key: "authToken")
```

Методы записи и удаления возвращают `Bool` — признак успеха; результат можно не использовать. Помимо строк поддерживается `Data`: `set(key:value:)` с `Data` и `getData(key:)`.

Записи привязываются к сервису (по умолчанию — bundle identifier приложения). Чтобы разделить данные с расширениями или изменить доступность записи, передайте свою конфигурацию:

```swift
extension KeychainHelper.Configuration {
    static let shared = KeychainHelper.Configuration(
        service: "com.example.app.shared",
        accessGroup: "TEAMID.com.example.app.shared",
        accessibility: .afterFirstUnlock
    )
}

KeychainHelper.set(key: "authToken", value: "abc123securetoken", in: .shared)
```

> **Обновление со старой версии.** Ранние версии сохраняли записи без сервиса. Чтобы прочитать такие записи, используйте `KeychainHelper.Configuration(service: nil)`.

### CoreDataHelper

Для хранения структурированных данных. Укажите имя вашей модели `.xcdatamodeld`:

```swift
let coreData = try CoreDataHelper(modelName: "Model")

// Создать объект
let note = coreData.create(Note.self)
note?.title = "Купить молоко"
try coreData.saveContext()

// Получить объекты
let notes = try coreData.fetch(
    Note.self,
    predicate: NSPredicate(format: "title CONTAINS[cd] %@", "молоко"),
    sortDescriptors: [NSSortDescriptor(key: "title", ascending: true)]
)

// Посчитать объекты, не загружая их в память
let count = try coreData.count(Note.self)

// Удалить объект или все объекты типа
try coreData.delete(notes[0])
try coreData.clear(Note.self)
```

Для тестов и превью SwiftUI используйте хранилище в памяти: `CoreDataHelper(modelName: "Model", inMemory: true)`. Методы работают с `viewContext`, поэтому вызывайте их с главного потока.

### CloudKitHelper

Для синхронизации данных между устройствами с помощью CloudKit.

#### Пример использования:

```swift
let cloudKitHelper = CloudKitHelper() // приватная база контейнера по умолчанию

// Сохранить данные в CloudKit
let record = try await cloudKitHelper.save(
    recordType: "User",
    fields: ["username": "john_doe", "email": "john@example.com"]
)

// Получить данные из CloudKit (все страницы результатов загружаются автоматически)
let users = try await cloudKitHelper.fetch(
    recordType: "User",
    predicate: NSPredicate(format: "username == %@", "john_doe")
)

// Обновить запись
try await cloudKitHelper.update(record: record, fields: ["email": "new@example.com"])

// Удалить запись из CloudKit
try await cloudKitHelper.delete(recordID: record.recordID)
```

Те же операции доступны с completion handler. Он вызывается на фоновом потоке:

```swift
cloudKitHelper.fetch(recordType: "User") { result in
    switch result {
    case .success(let records):
        print("Записи получены из CloudKit: \(records)")
    case .failure(let error):
        print("Ошибка получения из CloudKit: \(error)")
    }
}
```

Другую базу данных (публичную, общую или другого контейнера) можно передать в инициализатор: `CloudKitHelper(database: CKContainer(identifier: "iCloud.com.example.app").publicCloudDatabase)`.

## Дополнительные возможности

- **Проверка существования данных**: Вы можете проверить, существует ли ключ в **UserDefaults** или **Keychain** перед чтением.

  Пример для **Keychain**:
  ```swift
  if KeychainHelper.exists(key: "authToken") {
      print("Токен существует")
  } else {
      print("Токен не найден")
  }
  ```

- **Очистка всех данных**: Вы можете очистить все данные из **UserDefaults** или **Keychain**, если необходимо.

  ```swift
  UserDefaultsHelper.clearAll()
  KeychainHelper.clearAll()
  ```

## Пример

В [Examples/NicknameLogic.swift](Examples/NicknameLogic.swift) — экран, который при первом запуске запрашивает никнейм и сохраняет его в Keychain.
