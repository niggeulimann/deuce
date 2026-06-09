//
//  deuceApp.swift
//  deuce Watch App
//
//  Created by Uli Niggemann on 31.05.26.
//

import SwiftUI
import SwiftData

@main
struct deuce_Watch_AppApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(
                for: Schema(versionedSchema: DeuceSchemaV4.self),
                migrationPlan: DeuceMigrationPlan.self
            )
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
        WatchSyncManager.shared.configure(container: modelContainer)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
