# Deuce – Entwicklungsplan

## Tech-Stack & Konventionen

- SwiftUI, watchOS 10+, reine watchOS-App (kein iPhone-Companion im MVP)
- Architektur: MVVM, Scoring-Logik strikt von der UI getrennt
- Persistenz: SwiftData ab Phase 3 (Match-History)
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
- Satzlogik: 6 Games (konfigurierbar auf 4), 2-Spiele-Vorsprung, Tiebreak bei 6:6 → 7:6
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

## Phase 3 – Match-History (SwiftData) 🔜

### Ziel
Abgeschlossene Matches mit Datum speichern, damit der Spieler
vergangene Ergebnisse einsehen kann.

### Domänenmodell (SwiftData)

```swift
@Model
class MatchRecord {
    var date: Date
    var surface: String          // CourtSurface.rawValue
    var noAd: Bool
    var gamesPerSet: Int
    var setsToWin: Int
    // Ergebnis
    var setsTop: Int             // Gegner
    var setsBottom: Int          // Du
    // Satz-für-Satz Aufschlüsselung  [(topGames, bottomGames), …]
    var setScoresTop: [Int]
    var setScoresBottom: [Int]
    var didWin: Bool             // Du hast gewonnen?
}
```

### Was sich ändert

| Datei | Änderung |
|---|---|
| `deuceApp.swift` | `.modelContainer(for: MatchRecord.self)` hinzufügen |
| `MatchViewModel` | `func saveRecord(context: ModelContext)` – schreibt Record beim Match-Ende |
| `MatchView` | `@Environment(\.modelContext)` – ruft `saveRecord` beim Tap auf „Fertig" |
| `StartView` | Tab-View oder NavigationStack mit History-Button |
| `HistoryView` (neu) | Liste vergangener Matches, sortiert nach Datum |
| `MatchDetailView` (neu) | Satz-Tabelle + Datum + Oberfläche für ein einzelnes Match |

### UI-Konzept History

**Startscreen** – kleiner History-Button (z. B. Uhr-Icon) oben rechts  
→ öffnet `HistoryView` als Sheet oder eigene Navigation-Seite

**HistoryView** – kompakte Liste:
```
● 31. Mai   6:3 6:2   Asche   ✓
○ 29. Mai   4:6 3:6   Rasen   ✗
```
Grüner Punkt = gewonnen, grauer = verloren

**MatchDetailView** – Satztabelle:
```
        S1   S2   S3
Gegner   3    4    –
Du       6    6    –
```
+ Datum, Belag, No-Ad, Best-of

### Persistenz-Entscheidungen

- SwiftData direkt im Watch Target (kein CloudKit im MVP, kein iPhone-Sync)
- Kein automatisches Löschen alter Records – User kann manuell aus History löschen (Swipe-to-delete)
- Max. ~100 Records realistisch → kein Paging nötig

### Offene Fragen vor Umsetzung

1. **Speichern nur bei vollständig beendetem Match** (Match-Over-Overlay) oder auch bei „Beenden" mittendrin?
2. **Abgebrochene Matches** anzeigen (mit Zwischenstand) oder verwerfen?

---

## Phase 4 – Spätere Features (Backlog)

- Digital Crown / Komplikation
- iPhone-Sync (CloudKit oder Watch Connectivity)
- Tiebreak als eigener Spielmodus (7 Punkte, kein Vorteil)
- Statistiken (Gewinnquote, Durchschnittsdauer)
- App-Icon (eigenes Design)
