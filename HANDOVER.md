# Handover — Deuce
> Stand: 2026-06-12

Tennis-Score-Tracker für Apple Watch + neue iOS-Companion (Verlauf, Gegner-Bilanz,
Statistiken). Diskussion Deutsch, Code/Identifier/Kommentare Englisch.

---

## Projekt-Überblick

| | |
|---|---|
| Art | watchOS Score-Tracker + iOS-Companion (Historie/Analytics) |
| Stack | SwiftUI, SwiftData (VersionedSchema), Swift Charts, WatchConnectivity, HealthKit, Swift Testing |
| Apple Team | `W5XAZYC285` |
| Deployment | iOS 26.5 · watchOS 11.6 / 26.5 |
| Version (Repo) | `MARKETING_VERSION = 3.1.0`, `CURRENT_PROJECT_VERSION = 1` (alle App-Targets); Commit „Prepare 3.1.0 release" vorhanden |

**Zwei parallele Apps im selben Projekt** (⚠️ nicht verwechseln):

| App | Bundle-ID | Targets | Typ | WKWatchOnly |
|---|---|---|---|---|
| **Watch-only (live)** | `de.mokkavadder.app.deuce` | `DeuceContainer` + `DeuceContainer WatchApp` | watchapp2-container + Watch | **YES** |
| **Companion (neu)** | `de.mokkavadder.app.deuce.companion` | `DeuceCompanion` + `DeuceCompanionWatchApp` | iOS-App + Watch | **NO** |

> Die Companion ist eine **eigene** ASC-App (anderer Bundle-Suffix `.companion`),
> kein Update der Live-App. **Offene Produktentscheidung:** Companion als neue App
> veröffentlichen oder die Watch-only-App langfristig ablösen? (siehe Offene Punkte)

---

## Repository & Branch

| | |
|---|---|
| Remote | `git@github.com:niggeulimann/deuce.git` |
| Branch | `main` (Konvention: auf `main` arbeiten; Feature-Branches bei Bedarf) |
| HEAD | `bc6d469 screenshots` |
| Uncommitted | nur `D artwork/app-store/final/en/02-score-at-a-glance.png` (gelöschtes Screenshot-Master) |

Commit-Messages enden mit `Co-Authored-By: …` wenn von Agenten erzeugt. Push macht
der Owner manuell (nicht automatisch pushen).

---

## Projektstruktur

```
deuce/
├── HANDOVER.md, PLAN.md          ← Doku (PLAN.md = lebender Entwicklungsplan)
├── artwork/                      ← App-Store-Screenshots, Master (1242x2688), final de/en, Hero-Roh
└── deuce/
    ├── deuce.xcodeproj
    ├── deuce shared/             ← Membership in mehreren Targets (Watch + Companion)
    │   ├── ScoringEngine.swift     pure State-Machine (Punkte/Deuce/Sätze/Tiebreak) – voll getestet
    │   ├── MatchViewModel.swift    @Observable, treibt ein Live-Match + Timestamp-Logging
    │   ├── MatchView.swift         In-Match-Scoring-UI (Court/Score/Health-Pager)
    │   ├── MatchRecord.swift       SwiftData @Model + VersionedSchema V1–V4 + MigrationPlan
    │   ├── MatchRecordDTO.swift    Codable-Transport für WatchConnectivity + Mapper
    │   ├── Analytics.swift         pure Auswertungen über [MatchRecord] (getestet)
    │   ├── WatchSyncManager.swift  Watch→Phone Senden (transferUserInfo, Dedupe per UUID)
    │   ├── PhoneSyncManager.swift  Phone-Empfang + Upsert (iOS-Membership)
    │   ├── HealthManager.swift     HKWorkoutSession (.tennis) + Live-Metriken
    │   ├── AppLanguage.swift       L10n-Layer mit DE-Fallback-Dictionary (Besonderheit, s.u.)
    │   ├── CourtSurface.swift / AccentTheme.swift / Format.swift
    ├── deuce companion/          ← iOS-App (neu)
    │   ├── DeuceApp.swift           @main, ModelContainer V4, RootTabView (4 Tabs)
    │   ├── HeroHeader.swift         wiederverwendbarer Hero (Bild-Array, Crossfade-Rotation)
    │   ├── AppTheme.swift           System/Light/Dark (@AppStorage "appTheme")
    │   ├── MatchesListView / MatchDetailView   Verlauf + Detail (Satz-Tabelle, Gegner, Notizen, Zeiten)
    │   ├── OpponentsListView / OpponentDetailView   H2H + Win-Rate-Trend (Charts)
    │   ├── StatsView.swift          Gesamtquote, Trend, Belag, Dynamik (Charts)
    │   ├── SettingsView.swift       Theme + Accent-Picker
    │   ├── PhonePlayView.swift      (am iPhone zugehörige View)
    │   └── Localizable.xcstrings    Companion-Strings (DE+EN, in Arbeit)
    ├── deuce Watch App/          ← Watch-UI (deuceApp, ContentView, StartView, HistoryView, OpponentsView, ScorePadView)
    ├── deuce Watch AppTests/     ← Swift Testing: ScoringEngineTests + AnalyticsTests
    └── DeuceTests/ DeuceUITests/ deuce Watch AppUITests/  ← Test-Targets (überw. Templates)
```

> **Ordner ≠ Target 1:1.** Membership wird in Xcode gesetzt. `deuce shared/` muss in
> die jeweils nutzenden App-Targets; Watch-UI nur in Watch-Targets; Companion-UI nur iOS.

**Domänenmodell (SwiftData, aktuell V4 = `Schema.Version(1,3,0)`):** Migrationskette
V1→V2→V3→V4 (alle `.lightweight`), globale Typealiases zeigen auf `DeuceSchemaV4`.
`MatchRecord` enthält u.a. `id: UUID` (Sync-Dedupe), `opponentName`, `notes`,
`isDeleted` (Soft-Delete), Timestamps `firstPointOffset`/`pointOffsets`/`gameOffsets`/
`setOffsets` (Sekunden seit `matchStartDate`). `KnownOpponent` = `name`, `lastPlayed`.
Konvention: `top` = Gegner, `bottom` = du; `didWin` = bottom gewonnen.

---

## Was eingerichtet wurde (Tooling, Besonderheiten, Stolperfallen)

**Eingerichtet**
- Xcode Cloud (Build/Submit) – serverseitig in ASC konfiguriert, **kein** `ci_scripts/` im Repo.
- ASC-App `de.mokkavadder.app.deuce` ist die Live-Watch-App.
- Swift-Testing-Tests: Scoring (≈17) + Analytics (≈16); laufen grün (`xcodebuild … test`).
- 3 String-Kataloge: Watch `Localizable.xcstrings` + `InfoPlist.xcstrings`, Companion `Localizable.xcstrings`.
- Sync: Einweg Watch→iPhone (`transferUserInfo`, Dedupe per UUID) **plus** Delete-Propagation über `isDeleted`/`markDeleted` + `PhoneSyncManager.send`.

**Stolperfallen (explizit)**
- **Info.plist:** `GENERATE_INFOPLIST_FILE = YES` → Keys ausschließlich als `INFOPLIST_KEY_*` (Build Settings), **nie** physische `.plist` mischen. Version nie hardcoden – `$(MARKETING_VERSION)`/`$(CURRENT_PROJECT_VERSION)`.
- **`ITSAppUsesNonExemptEncryption = NO`** muss am **iOS/Container-Target** liegen (ASC liest es aus dem Haupt-Bundle), nicht nur am Watch-Target.
- **Watch-Bundle-IDs** (`…watchkitapp`, `…companion.watchkitapp`) müssen im Developer-Portal **manuell** als App-ID registriert sein – Xcode-Cloud-Auto-Signing legt sie nicht an (sonst `exportArchive` Exit 70).
- **Xcode Cloud / Archiv:** iOS-/Container-Scheme auf **iOS-Plattform** bauen, nie watchOS-Destination.
- **L10n-Besonderheit:** `AppLanguage.swift`/`L10n.string(...)` mappt EN-Key → DE über ein **Fallback-Dictionary `germanFallbacks`**. Neue DE-Strings ggf. **dort** (zusätzlich zum xcstrings) eintragen, sonst bleibt es Englisch.
- **Schema-Bump:** neue `DeuceSchemaVx` + `.lightweight`-Stage + **beide** Typealiases umziehen + **beide** Apps' `ModelContainer(for: Schema(versionedSchema:))` aktualisieren.
- **WCSession-Delegate** kommt off-main → vor SwiftData-Zugriff `@MainActor` hoppen (PhoneSyncManager macht das).
- **Strava-Sackgasse:** Strava importiert nur native Apple-Workout-App-Sessions; API seit 2026-06-01 abo-pflichtig ($11.99/Mo). Lösung: Owner nutzt **HealthFit** (Health→Strava). Keine Strava-Integration bauen.

---

## Jira  (Board **ULI**, mokkavadder.atlassian.net)

⚠️ **Es existiert aktuell KEIN Deuce-Epic und keine Deuce-Tickets** auf dem Board.
Das ULI-Board ist Multi-Projekt; vorhandene Epics:

| Epic | Thema | Status |
|---|---|---|
| ULI-1 | pickTHEShot App | Open |
| ULI-2 | Barista Care App | Open |
| ULI-3 | Garden Workout App | Open |
| ULI-4 | Mokkavadder Homepage | Open |
| ULI-5 | tr.ai.ner App | Open |
| ULI-11 | Workout Converter | Plan/Concept |
| ULI-30 | Haus und Hof | Open |

→ **Empfehlung:** Epic „Deuce" anlegen und die Punkte unten als Stories/Bugs einhängen.
(Hinweis: ULI-8 „Jira Workflow & AGENTS.md definieren" ist Done, aber **keine `AGENTS.md` im Repo** – liegt vermutlich im Vault.)

---

## Offene Punkte (angefangen / bekannt)

- **Companion-Lokalisierung** in Arbeit: Katalog + `germanFallbacks` müssen für alle neuen iOS-Strings vollständig sein.
- **Hero-Artwork:** Rotation technisch fertig (`HeroHeader(imageNames:)`, Crossfade, Zufallsstart); **Assets fehlen** noch → `imageNames` pro Tab füllen.
- **Companion-App-Icon** final (Platzhalter im Catalog).
- **Sync auf echten Geräten** noch nicht verifiziert (Builds grün): Match-Übertragung + Backfill + **Delete-Roundtrip** (am iPhone löschen → Watch?).
- **Zwei-App-Strategie** ungeklärt (neue `.companion`-App vs. Ablösung der Live-App).
- **iPhone-Screenshots** für ASC fehlen (Companion wird als iOS-App reviewt).

## Nächste Schritte (priorisiert)

1. **Geräte-Test des Sync** (iPhone+Watch gepaart): Erstübertragung, Backfill, Delete-Roundtrip.
2. **Companion-DE-Strings** vervollständigen (xcstrings + `germanFallbacks`).
3. **Hero-Assets** einsetzen, sobald Artwork fertig (`imageNames` in Matches/Opponents/Stats/Settings).
4. **Companion-App-Icon** + **iPhone-Screenshots** für ASC.
5. **Produktentscheidung** Zwei-App-Strategie treffen; ASC-App-Record entsprechend anlegen/zuordnen.
6. **Jira:** Deuce-Epic + Tickets für 1–5 anlegen.
7. Submission der Companion (iOS+Watch); Build über Container/iOS-Scheme, Encryption-Key gesetzt, Watch-Bundle-ID registriert.

## Build & Test (Kurzreferenz)
```
# Companion bauen
xcodebuild -scheme DeuceCompanion -destination 'generic/platform=iOS Simulator' build
# Watch-App + Tests
xcodebuild -scheme "deuce Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch SE 3 (40mm)' test
```
Kein Swift Package / `swift build` mehr – alles über Xcode.
