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
                for: Schema(versionedSchema: DeuceSchemaV2.self),
                migrationPlan: DeuceMigrationPlan.self
            )
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
