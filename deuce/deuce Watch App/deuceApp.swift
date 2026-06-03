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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [MatchRecord.self, KnownOpponent.self])
    }
}
