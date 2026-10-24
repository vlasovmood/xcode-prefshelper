import Foundation
import CoreData

/// Core Data-стек с типобезопасными CRUD-операциями.
///
/// Методы работают с `viewContext`, поэтому вызывайте их с главного потока.
/// Для тяжёлых операций используйте `container.performBackgroundTask(_:)`.
public final class CoreDataHelper {

    public let container: NSPersistentContainer

    public var viewContext: NSManagedObjectContext { container.viewContext }

    /// - Parameters:
    ///   - modelName: имя модели `.xcdatamodeld` без расширения.
    ///   - inMemory: хранить данные только в памяти (удобно для тестов и превью).
    public convenience init(modelName: String, inMemory: Bool = false) throws {
        let container = NSPersistentContainer(name: modelName)
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        try self.init(container: container)
    }

    /// Загружает хранилища контейнера синхронно и выбрасывает ошибку, если загрузка не удалась.
    public init(container: NSPersistentContainer) throws {
        self.container = container

        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = loadError ?? error
        }
        if let loadError { throw loadError }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    public func saveContext() throws {
        guard viewContext.hasChanges else { return }
        try viewContext.save()
    }

    public func create<T: NSManagedObject>(_ type: T.Type) -> T? {
        guard let entityName = T.entity().name else { return nil }
        return NSEntityDescription.insertNewObject(forEntityName: entityName, into: viewContext) as? T
    }

    public func fetch<T: NSManagedObject>(_ type: T.Type,
                                          predicate: NSPredicate? = nil,
                                          sortDescriptors: [NSSortDescriptor]? = nil,
                                          limit: Int? = nil) throws -> [T] {
        let request = fetchRequest(for: type)
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        if let limit { request.fetchLimit = limit }
        return try viewContext.fetch(request)
    }

    /// Считает объекты на стороне хранилища, не загружая их в память.
    public func count<T: NSManagedObject>(_ type: T.Type, predicate: NSPredicate? = nil) throws -> Int {
        let request = fetchRequest(for: type)
        request.predicate = predicate
        return try viewContext.count(for: request)
    }

    public func delete(_ object: NSManagedObject) throws {
        viewContext.delete(object)
        try saveContext()
    }

    /// Удаляет все объекты типа с учётом правил удаления связей.
    public func clear<T: NSManagedObject>(_ type: T.Type) throws {
        let request = fetchRequest(for: type)
        request.includesPropertyValues = false // для удаления достаточно ID объектов
        try viewContext.fetch(request).forEach { viewContext.delete($0) }
        try saveContext()
    }

    private func fetchRequest<T: NSManagedObject>(for type: T.Type) -> NSFetchRequest<T> {
        NSFetchRequest<T>(entityName: T.entity().name ?? String(describing: T.self))
    }
}
