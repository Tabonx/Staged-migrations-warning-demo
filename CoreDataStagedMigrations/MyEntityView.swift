//
//  MyEntityView.swift
//  CoreDataStagedMigrations
//
//  Created by Pavel Kroupa on 01.04.2025.
//

import CoreData
import SwiftUI

extension MyEntity {
    static func fetch() -> NSFetchRequest<MyEntity> {
        let request = MyEntity.fetchRequest()
        request.predicate = NSPredicate(format: "TRUEPREDICATE")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return request
    }
}

struct MyEntityView: View {
    @FetchRequest(fetchRequest: MyEntity.fetch()) private var testEntities: FetchedResults<MyEntity>

    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                List {
                    ForEach(testEntities, id: \.objectID) { entity in
                        Text(entity.name ?? "Unknown")
                    }
                }
                .frame(maxHeight: 200)

                VStack(spacing: 12) {
                    Button(action: addMyEntity) {
                        HStack {
                            Text("Add Test Entity")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }

                    Button(action: fetchAndPrintEntities) {
                        Text("Fetch & Print to Console")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }

                    Button(action: clearAllEntities) {
                        Text("Clear All")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Core Data Test")
        }
    }

    private func addMyEntity() {
        Task {
            do {
                try await CoreDataManager.shared.addMyEntity(name: generateName())
            } catch {
                print(error)
            }
        }
    }

    private func fetchAndPrintEntities() {
        Task {
            do {
                let entities = try await CoreDataManager.shared.fetchAllTestEntities()
                print("=== Fetched \(entities.count) entities ===")
                for (index, entity) in entities.enumerated() {
                    print("\(index + 1). ID: \(entity.objectID), Name: \(entity.name ?? "nil")")
                }
                print("=== End of fetch results ===")
            } catch {
                print(error)
            }
        }
    }

    private func clearAllEntities() {
        Task {
            do {
                try await CoreDataManager.shared.deleteAllTestEntities()
            } catch {
                print(error)
            }
        }
    }

    private func generateName() -> String {
        let names = ["Breaking Bad", "The Wire", "Sopranos", "Mad Men", "Game of Thrones", "Stranger Things"]
        return names.randomElement() ?? "Default Show"
    }
}

class CoreDataManager {
    static let shared = CoreDataManager()
    private init() {}

    private var persistentContainer: NSPersistentContainer {
        PersistenceController.shared.container
    }

    func addMyEntity(name: String) async throws {
        let context = persistentContainer.newBackgroundContext()

        try await context.perform {
            let entity = MyEntity(context: context)
            entity.name = name

            try context.save()
        }
    }

    func fetchAllTestEntities() async throws -> [MyEntity] {
        let context = persistentContainer.newBackgroundContext()

        return try await context.perform {
            let request = MyEntity.fetch()
            return try context.fetch(request)
        }
    }

    func deleteAllTestEntities() async throws {
        let context = persistentContainer.newBackgroundContext()

        try await context.perform {
            let request: NSFetchRequest<MyEntity> = MyEntity.fetchRequest()
            let entities = try context.fetch(request)

            for entity in entities {
                context.delete(entity)
            }

            try context.save()
        }
    }
}
