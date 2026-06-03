# Deuce – Entwicklungsplan

## Tech-Stack & Konventionen

- SwiftUI, watchOS 10+, reine watchOS-App (kein iPhone-Companion im MVP)
- Architektur: MVVM, Scoring-Logik strikt von der UI getrennt
- Persistenz: SwiftData mit `VersionedSchema` und `SchemaMigrationPlan`
- Tests: ScoringEngine als pure State Machine (Swift Testing), unabhängig von SwiftUI
- Sprache: Diskussion Deutsch, Code/Identifier/Kommentare Englisch

---

## Status: Umgesetzte Phasen

### ✅ Phase 1 – Einzelnes Game (Milestone 1a)
- Punktezählung inkl. Deuce/Vorteil, No-Ad-Variante
- Undo (letzter Punkt)
- Haptisches Feedback

### ✅ Phase 2 – Games + Sätze + Aufschlag
- Spielezähler (gamesWon pro Seite)
- Aufschlag-Auswahl (Du / Gegner) auf Startscreen
- Aufschlagwechsel nach jedem Game (automatisch)
- Aufschlagseite (links/rechts) wechselt nach jedem Punkt
- Satzlogik: 6 Games (konfigurierbar auf 4), 2-Spiele-Vorsprung, Tiebreak bei 6:6 bzw. 4:4 bis 7 Punkte mit 2-Punkte-Vorsprung
- Best of 1 / 3 / 5 konfigurierbar
- Seitenwechsel-Overlay nach jedem Satz
- Match-Over-Overlay mit Ergebnis (Gewonnen/Verloren)

### ✅ Phase 2b – UI / Court-Ansicht
- Tennisfeld-Layout (Asche/Rasen/Hard/Halle wählbar)
- Weißes Score-Badge (invertiert, Platzfarbe als Text)
- Aufschlag-Dot (gelb) + Empfänger-Dot (weiß), beide an Grundlinie, diagonal gegenüber
- Synchrone Animation bei Dot-Wechsel
- Horizontal-Pager: Court (Hauptseite) + Score-Detailseite
- Page Indicator unten
- Undo-Button in watchOS-Statusbar (Uhrzeit erscheint automatisch)
- Startscreen: Tennisball-Icon, Spielen-Button oben, Settings darunter scrollbar

---

### ✅ Phase 3 – Match-History (SwiftData)

- Abgeschlossene und abgebrochene Matches werden als `MatchRecord` gespeichert
- History-Sheet mit kompakter Liste, Löschfunktion und Detailansicht
- Satz-für-Satz Tabelle inkl. aktuellem Satz bei abgebrochenen Matches
- Gegnername nachträglich editierbar, bekannte Gegner werden als `KnownOpponent` gespeichert
- Timing-Daten pro Match: Matchstart, erster Punkt/Warmup, Punkt-, Game- und Satz-Offsets
- Detailansicht zeigt Warmup, Punktzahl, durchschnittlichen und längsten Ballwechsel
- SwiftData-Container enthält `MatchRecord` und `KnownOpponent`

### Aktuelles Domänenmodell (SwiftData)

App-Store-Version 1.0 basiert auf Commit `4af667fc2b48cdf2ea35b9275acf020945079e9a`
und ist als `DeuceSchemaV1` abgebildet. Das aktuelle Modell ist `DeuceSchemaV2`;
die Migration von V1 nach V2 ist als Lightweight-Migration hinterlegt.

```swift
@Model
class MatchRecord {
    var date: Date               // save date
    var surface: String          // CourtSurface.rawValue
    var noAd: Bool
    var gamesPerSet: Int
    var setsToWin: Int
    var isComplete: Bool
    var setsTop: Int
    var setsBottom: Int
    var setScoresTop: [Int]
    var setScoresBottom: [Int]
    var currentGamesTop: Int
    var currentGamesBottom: Int
    var currentPointsTop: Int
    var currentPointsBottom: Int
    var didWin: Bool
    var opponentName: String
    var matchStartDate: Date
    var firstPointOffset: Double
    var pointOffsets: [Double]
    var gameOffsets: [Double]
    var setOffsets: [Double]
}

@Model
class KnownOpponent {
    var name: String
    var lastPlayed: Date
}
```

---

## Phase 4 – Spätere Features (Backlog)

- Digital Crown / Komplikation
- iPhone-Sync (CloudKit oder Watch Connectivity)
- Statistiken (Gewinnquote, Durchschnittsdauer, Gegnerbilanz)
- Gegnerauswahl vor Matchstart
- App-Icon (eigenes Design)
