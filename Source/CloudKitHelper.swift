import Foundation
import CloudKit

/// Сохранение и синхронизация данных через CloudKit.
///
/// У каждой операции есть `async`-версия и версия с completion handler.
/// Completion handler вызывается на фоновом потоке — для работы с UI переключайтесь на главный.
public final class CloudKitHelper {

    private let database: CKDatabase

    /// - Parameter database: база данных CloudKit; по умолчанию — приватная база контейнера по умолчанию.
    public init(database: CKDatabase = CKContainer.default().privateCloudDatabase) {
        self.database = database
    }

    // MARK: - async/await

    public func save(recordType: String, fields: [String: Any]) async throws -> CKRecord {
        let record = CKRecord(recordType: recordType)
        record.setValuesForKeys(fields)
        return try await database.save(record)
    }

    /// Возвращает все записи, подходящие под условие, автоматически загружая все страницы результатов.
    public func fetch(recordType: String,
                      predicate: NSPredicate = NSPredicate(value: true),
                      sortDescriptors: [NSSortDescriptor]? = nil,
                      zoneID: CKRecordZone.ID? = nil) async throws -> [CKRecord] {
        let query = CKQuery(recordType: recordType, predicate: predicate)
        query.sortDescriptors = sortDescriptors

        var response = try await database.records(matching: query, inZoneWith: zoneID)
        var records = try response.matchResults.map { try $0.1.get() }
        while let cursor = response.queryCursor {
            response = try await database.records(continuingMatchFrom: cursor)
            records += try response.matchResults.map { try $0.1.get() }
        }
        return records
    }

    public func fetch(recordID: CKRecord.ID) async throws -> CKRecord {
        try await database.record(for: recordID)
    }

    /// Записывает поля в `record` и сохраняет его.
    @discardableResult
    public func update(record: CKRecord, fields: [String: Any]) async throws -> CKRecord {
        record.setValuesForKeys(fields)
        return try await database.save(record)
    }

    public func delete(recordID: CKRecord.ID) async throws {
        _ = try await database.deleteRecord(withID: recordID)
    }

    // MARK: - Completion handlers

    public func save(recordType: String, fields: [String: Any], completion: @escaping (Result<CKRecord, Error>) -> Void) {
        run(completion) { try await self.save(recordType: recordType, fields: fields) }
    }

    public func fetch(recordType: String,
                      predicate: NSPredicate = NSPredicate(value: true),
                      sortDescriptors: [NSSortDescriptor]? = nil,
                      zoneID: CKRecordZone.ID? = nil,
                      completion: @escaping (Result<[CKRecord], Error>) -> Void) {
        run(completion) {
            try await self.fetch(recordType: recordType, predicate: predicate, sortDescriptors: sortDescriptors, zoneID: zoneID)
        }
    }

    public func fetch(recordID: CKRecord.ID, completion: @escaping (Result<CKRecord, Error>) -> Void) {
        run(completion) { try await self.fetch(recordID: recordID) }
    }

    public func update(record: CKRecord, fields: [String: Any], completion: @escaping (Result<CKRecord, Error>) -> Void) {
        run(completion) { try await self.update(record: record, fields: fields) }
    }

    public func delete(recordID: CKRecord.ID, completion: @escaping (Result<Void, Error>) -> Void) {
        run(completion) { try await self.delete(recordID: recordID) }
    }

    private func run<T>(_ completion: @escaping (Result<T, Error>) -> Void, operation: @escaping () async throws -> T) {
        Task {
            do {
                completion(.success(try await operation()))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
