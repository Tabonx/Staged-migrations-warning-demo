//
//  PersistenceController.swift
//  CoreDataStagedMigrations
//
//  Created by Pavel Kroupa on 01.04.2025.
//

import CoreData
import Foundation

let groupIdentifier = "group.com.tabonx.CoreDataStagedMigrations"

class PersistenceController: @unchecked Sendable {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    private var backgroundContext_: NSManagedObjectContext?

    init() {
        container = NSPersistentContainer(name: "StagedMigrations")

        if let description = container.persistentStoreDescriptions.first {
            guard let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier) else { fatalError("Unable to create URL") }

            let storeURL = fileContainer.appendingPathComponent("StagedMigrations.sqlite")

            print(storeURL)

            description.url = storeURL

            let migrationFactory = MigrationFactory()

            description.setOption(
                migrationFactory.create(),
                forKey: NSPersistentStoreStagedMigrationManagerOptionKey
            )
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            self.container.viewContext.automaticallyMergesChangesFromParent = true
        }
    }
}

struct MigrationFactory {
    private struct ModelInfo {
        let checksum: String
        let reference: NSManagedObjectModelReference
    }

    private let models: [ModelInfo]

    let modelNames = [
        "StagedMigrations",
        "StagedMigrationsV2",
        "StagedMigrationsV3",
    ]

    init() {
        guard let momdURL = Bundle.main.url(
            forResource: "StagedMigrations",
            withExtension: "momd"
        ) else {
            fatalError("Missing .momd file")
        }

        models = modelNames.compactMap { name in
            let modelURL = momdURL.appendingPathComponent("\(name).mom")

            guard let model = NSManagedObjectModel(contentsOf: modelURL) else { fatalError("Failed to load model: \(name)") }

            return ModelInfo(
                checksum: model.versionChecksum,
                reference: NSManagedObjectModelReference(model: model, versionChecksum: model.versionChecksum)
            )
        }
    }

    private func migrationStage(from: Int, to: Int, handler: @escaping (NSStagedMigrationManager, NSCustomMigrationStage) -> Void) -> NSCustomMigrationStage {
        let stage = NSCustomMigrationStage(migratingFrom: models[from].reference, to: models[to].reference)

        stage.didMigrateHandler = handler

        return stage
    }

    private func v1toV2() -> NSCustomMigrationStage {
        migrationStage(from: 0, to: 1) { migrationManager, _ in
            self.insertEntities(entityName: "MyEntity", count: 10, into: migrationManager)
            print("Did migrate from v1 to v2")
        }
    }

    private func v2toV3() -> NSCustomMigrationStage {
        migrationStage(from: 1, to: 2) { migrationManager, _ in
            self.updateEntities(entityName: "MyEntity", key: "name", value: "filled", in: migrationManager)
            print("Did migrate from v2 to v3")
        }
    }

    func create() -> NSStagedMigrationManager {
        let stages = [v1toV2(), v2toV3()]

        return NSStagedMigrationManager(stages)
    }

    private func insertEntities(entityName: String, count: Int, into migrationManager: NSStagedMigrationManager) {
        guard let context = migrationManager.container?.newBackgroundContext() else { return }

        context.performAndWait {
            for _ in 0 ..< count {
                guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else { return }
                context.insert(NSManagedObject(entity: entity, insertInto: context))
            }
            try? context.save()
        }
    }

    private func updateEntities(entityName: String, key: String, value: Any, in migrationManager: NSStagedMigrationManager) {
        guard let context = migrationManager.container?.newBackgroundContext() else { return }

        context.performAndWait {
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
            if let objects = try? context.fetch(fetchRequest) {
                objects.forEach { $0.setValue(value, forKey: key) }
                try? context.save()
            }
        }
    }
}
