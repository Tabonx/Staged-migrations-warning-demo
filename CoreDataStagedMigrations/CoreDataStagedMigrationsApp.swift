//
//  CoreDataStagedMigrationsApp.swift
//  CoreDataStagedMigrations
//
//  Created by Pavel Kroupa on 01.04.2025.
//

import SwiftUI

@main
struct CoreDataStagedMigrationsApp: App {
    var body: some Scene {
        WindowGroup {
            EntityView()
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        }
    }
}

struct EntityView: View {
    var body: some View {
        TabView {
            MyEntityView()
                .tabItem {
                    Image(systemName: "1.circle")
                    Text("My Entity")
                }

            ChildContentView()
                .tabItem {
                    Image(systemName: "2.circle")
                    Text("Child")
                }
        }
    }
}
