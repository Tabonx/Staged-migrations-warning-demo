//
//  ChildContentView.swift
//  CoreDataStagedMigrations
//
//  Created by Pavel Kroupa on 01.04.2025.
//
import CoreData
import SwiftUI

extension Child {
    static func fetch() -> NSFetchRequest<Child> {
        let request = Child.fetchRequest()
        request.predicate = NSPredicate(format: "TRUEPREDICATE")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return request
    }
}

struct ChildContentView: View {
    @FetchRequest(fetchRequest: Child.fetch()) private var childEntities: FetchedResults<Child>

    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                List {
                    ForEach(childEntities, id: \.objectID) { entity in
                        Text(entity.name ?? "Unknown")
                    }
                }
                .frame(maxHeight: 200)

                VStack(spacing: 12) {
                    Button(action: addChildEntity) {
                        HStack {
                            Text("Add Child Entity")
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
            .navigationTitle("Child Entity Test")
        }
    }

    private func addChildEntity() {
        Task {
            do {
                try await ChildDataManager.shared.addChildEntity(name: generateName())
            } catch {
                print(error)
            }
        }
    }

    private func fetchAndPrintEntities() {
        Task {
            do {
                let entities = try await ChildDataManager.shared.fetchAllChildEntities()
                print("=== Fetched \(entities.count) child entities ===")
                for (index, entity) in entities.enumerated() {
                    print("\(index + 1). ID: \(entity.objectID), Name: \(entity.name ?? "nil")")
                }
                print("=== End of fetch results ===")
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to fetch entities: \(error.localizedDescription)"
                }
            }
        }
    }

    private func clearAllEntities() {
        errorMessage = nil

        Task {
            do {
                try await ChildDataManager.shared.deleteAllChildEntities()
                await MainActor.run {}
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to clear entities: \(error.localizedDescription)"
                }
            }
        }
    }

    private func generateName() -> String {
        let names = ["Alice", "Bob", "Charlie", "Diana", "Emma", "Frank", "Grace", "Henry"]
        return names.randomElement() ?? "Default Child"
    }
}

class ChildDataManager {
    static let shared = ChildDataManager()
    private init() {}

    private var persistentContainer: NSPersistentContainer {
        PersistenceController.shared.container
    }

    func addChildEntity(name: String) async throws {
        let context = persistentContainer.newBackgroundContext()

        try await context.perform {
            let entity = Child(context: context)
            entity.name = name

            try context.save()
        }
    }

    func fetchAllChildEntities() async throws -> [Child] {
        let context = persistentContainer.newBackgroundContext()

        return try await context.perform {
            let request = Child.fetch()
            return try context.fetch(request)
        }
    }

    func deleteAllChildEntities() async throws {
        let context = persistentContainer.newBackgroundContext()

        try await context.perform {
            let request: NSFetchRequest<Child> = Child.fetchRequest()
            let entities = try context.fetch(request)

            for entity in entities {
                context.delete(entity)
            }

            try context.save()
        }
    }
}
