//
//  DeuceTests.swift
//  DeuceTests
//
//  Created by Uli Niggemann on 05.06.26.
//

import Foundation
import Testing
@testable import DeuceCompanion

struct DeuceTests {

    @Test
    func localizedStringsFollowThePreferredLocale() {
        #expect(L10n.string("Start Warmup", locale: Locale(identifier: "en")) == "Start Warmup")
        #expect(L10n.string("Green", locale: Locale(identifier: "en")) == "Green")
        #expect(L10n.string("Start Warmup", locale: Locale(identifier: "de")) == "Einspielen starten")
        #expect(L10n.string("Green", locale: Locale(identifier: "de")) == "Grün")
        #expect(L10n.string("Start Warmup", locale: Locale(identifier: "fr")) == "Start Warmup")
    }

    @Test @MainActor
    func warmupEndsWhenMatchConfigurationIsConfirmed() {
        let startDate = Date(timeIntervalSinceReferenceDate: 1_000)
        let viewModel = MatchViewModel(matchStartDate: startDate)

        viewModel.startMatch(
            server: .top,
            noAd: true,
            gamesPerSet: 4,
            setsToWin: 1,
            surface: .grass,
            at: startDate.addingTimeInterval(95)
        )

        #expect(viewModel.firstPointOffset == 95)
        #expect(viewModel.server == .top)
        #expect(viewModel.noAd)
        #expect(viewModel.surface == .grass)
    }

    @Test @MainActor
    func phoneMatchRecordKeepsConfigurationAndOpponent() {
        let viewModel = MatchViewModel(
            server: .top,
            noAd: true,
            gamesPerSet: 4,
            setsToWin: 1,
            surface: .hard
        )

        viewModel.point(for: .bottom)
        let record = viewModel.makeRecord(
            isComplete: false,
            opponentName: "Alex"
        )

        #expect(record.opponentName == "Alex")
        #expect(record.surface == CourtSurface.hard.rawValue)
        #expect(record.noAd)
        #expect(record.gamesPerSet == 4)
        #expect(record.setsToWin == 1)
        #expect(record.pointOffsets.count == 1)
        #expect(!record.isComplete)
    }

    @Test @MainActor
    func completedPhoneMatchProducesWinningRecord() {
        let viewModel = MatchViewModel(
            gamesPerSet: 4,
            setsToWin: 1
        )

        for _ in 0..<16 {
            viewModel.point(for: .bottom)
        }

        let record = viewModel.makeRecord(isComplete: true)

        #expect(record.isComplete)
        #expect(record.didWin)
        #expect(record.setsBottom == 1)
        #expect(record.setsTop == 0)
        #expect(record.setScoresBottom == [4])
        #expect(record.setScoresTop == [0])
    }

}
