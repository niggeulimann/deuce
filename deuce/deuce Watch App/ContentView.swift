//
//  ContentView.swift
//  deuce Watch App
//
//  Created by Uli Niggemann on 31.05.26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var matches: [MatchRecord]

    var body: some View {
        StartView()
            .onAppear {
                // Activate the iPhone link and back-fill any matches the phone
                // hasn't received yet (including ones recorded before the
                // companion existed). The iPhone de-dupes by match UUID.
                syncMatches()
            }
            .onChange(of: matches.map(\.id)) {
                syncMatches()
            }
    }

    private func syncMatches() {
        WatchSyncManager.shared.sync(matches.map(MatchRecordDTO.init))
    }
}

#Preview {
    ContentView()
}
