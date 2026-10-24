import CoreData
import XCTest
import PrefsHelper

@objc(Note)
final class Note: NSManagedObject {
    @NSManaged var title: String
}

final class CoreDataHelperTests: XCTestCase {

    /// Модель создаётся один раз: несколько моделей с одним и тем же классом сущности ломают `Note.entity()`.
    private static let model: NSManagedObjectModel = {
        let title = NSAttributeDescription()
        title.name = "title"
        title.attributeType = .stringAttributeType
        title.isOptional = false

        let entity = NSEntityDescription()
        entity.name = "Note"
        entity.managedObjectClassName = NSStringFromClass(Note.self)
        entity.properties = [title]

        let model = NSManagedObjectModel()
        model.entities = [entity]
        return model
    }()

    private var coreData: CoreDataHelper!

    override func setUpWithError() throws {
        let container = NSPersistentContainer(name: "PrefsHelperTests", managedObjectModel: Self.model)
        container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        coreData = try CoreDataHelper(container: container)
    }

    override func tearDown() {
        coreData = nil
        super.tearDown()
    }

    func testCreateFetchCount() throws {
        for title in ["B", "A", "C"] {
            coreData.create(Note.self)?.title = title
        }
        try coreData.saveContext()

        let notes = try coreData.fetch(Note.self, sortDescriptors: [NSSortDescriptor(key: "title", ascending: true)])
        XCTAssertEqual(notes.map(\.title), ["A", "B", "C"])
        XCTAssertEqual(try coreData.fetch(Note.self, limit: 2).count, 2)
        XCTAssertEqual(try coreData.count(Note.self, predicate: NSPredicate(format: "title == %@", "A")), 1)
    }

    func testDeleteAndClear() throws {
        let note = try XCTUnwrap(coreData.create(Note.self))
        note.title = "A"
        coreData.create(Note.self)?.title = "B"
        try coreData.saveContext()

        try coreData.delete(note)
        XCTAssertEqual(try coreData.count(Note.self), 1)

        try coreData.clear(Note.self)
        XCTAssertEqual(try coreData.count(Note.self), 0)
    }
}
