# Deuce – Handover

> Tennis score tracker for Apple Watch, with an iOS companion app for history &
> analytics. This document lets a new agent continue seamlessly.

**Working language:** discussion in German, all code/identifiers/comments in English.

---

## 1. What this is

- **Watch app (shipped, v1):** count a tennis match on the wrist — points
  (0/15/30/40/Deuce/Ad), games, sets, serve indicator, court view, history.
- **iOS companion (v2, in progress):** receives finished matches from the watch
  and is the home for rich history, head-to-head records and statistics.

Bundle/identity:
- Apple Team: `W5XAZYC285`
- iOS companion app bundle id: `de.mokkavadder.app.deuce` (this is the App Store
  Connect record id)
- Watch app bundle id: `de.mokkavadder.app.deuce.watchkitapp`
- Deployment targets: iOS 26.5 / watchOS 26.5 (project is on current SDKs)
- Versions: watch shipped `1.0`; companion work is `MARKETING_VERSION = 2.0`

---

## 2. Current status

- **v1 watch-only is live** on the App Store / TestFlight.
- **v2 = iOS companion** is mid-build. The container target has already been
  converted from an empty `watchapp2-container` into a real iOS `application`
  target (`WKWatchOnly` is now `NO`). All companion Swift code exists.
- ⚠️ **Not yet verified to compile end-to-end** in this state — the project was
  being actively restructured in Xcode (3-folder layout, target memberships).
  First task for a continuing agent: open in Xcode, resolve target membership,
  build both schemes, run tests.

Git: branch `main`. Recent watch work is committed; the companion/shared
restructure is **uncommitted** in the working tree (lots of moves Watch App →
shared/companion). Commit only after it builds. **Do not push unless asked** —
the owner pushes manually.

---

## 3. Repository structure

```
deuce/
├── HANDOVER.md                  ← this file
├── PLAN.md                      ← living development plan (kept up to date)
└── deuce/
    ├── deuce.xcodeproj
    ├── deuce Watch App/         ← WATCH-only UI
    │   ├── deuceApp.swift        (@main watch app, ModelContainer V3)
    │   ├── ContentView.swift     (root; activates sync + back-fill on appear)
    │   ├── StartView.swift       (settings: serve, sets, games, surface,
    │   │                          No-Ad, health toggle, accent picker, history)
    │   ├── HistoryView.swift     (on-watch history + match detail + opponent edit)
    │   ├── ScorePadView.swift    (legacy, largely unused)
    │   ├── Localizable.xcstrings  (DE+EN, source language en)
    │   └── InfoPlist.xcstrings    (DE+EN health permission strings)
    ├── deuce shared/            ← membership in BOTH watch + companion targets
    │   ├── ScoringEngine.swift   (pure state machine — see §5)
    │   ├── MatchViewModel.swift  (@Observable, drives a live match + timestamps)
    │   ├── MatchView.swift       (the in-match scoring UI: court / score / health pager)
    │   ├── MatchRecord.swift     (SwiftData @Model + VersionedSchema V1/V2/V3 + migration)
    │   ├── KnownOpponent.swift   (typealias → DeuceSchemaV3.KnownOpponent)  [in Watch App or shared]
    │   ├── MatchRecordDTO.swift  (Codable transport for WatchConnectivity + mappers)
    │   ├── Analytics.swift       (pure analytics over [MatchRecord] — see §6)
    │   ├── WatchSyncManager.swift (watch→phone send via transferUserInfo)
    │   ├── PhoneSyncManager.swift (phone receive + upsert; iOS membership only)
    │   ├── HealthManager.swift   (HKWorkoutSession tennis workout + live metrics)
    │   ├── HealthView.swift      (3rd pager screen: workout metrics)
    │   ├── CourtSurface.swift    (enum clay/grass/hard/carpet: labels + colors)
    │   ├── AccentTheme.swift     (accent color picker enum)
    │   └── Format.swift          (duration/percent string helpers)
    ├── deuce companion/         ← iOS-only UI (the new app)
    │   ├── DeuceApp.swift        (@main iOS app, ModelContainer V3, 3-tab Root)
    │   ├── MatchesListView.swift (Tab 1: list → MatchDetailView)
    │   ├── MatchDetailView.swift (set table, opponent picker, notes, dynamics)
    │   ├── OpponentsListView.swift (Tab 2: opponents w/ H2H record)
    │   ├── OpponentDetailView.swift (H2H + win-rate trend chart)
    │   ├── StatsView.swift       (Tab 3: overall stats, trend, surface, dynamics — Swift Charts)
    │   └── ContentView.swift     (template leftover; Root is in DeuceApp.swift)
    ├── deuce Watch AppTests/    ← Swift Testing
    │   ├── ScoringEngineTests.swift (scoring rules, 17 tests)
    │   └── AnalyticsTests.swift     (analytics, 16 tests)
    ├── DeuceTests/ DeuceUITests/  ← companion test targets (mostly templates)
    └── deuce Watch AppUITests/    ← watch UI test templates
```

> **Folder = target-membership convention.** `deuce shared/` files must have
> membership in **both** the watch app and the companion. `deuce companion/` =
> iOS only. `deuce Watch App/` = watch only. `PhoneSyncManager` lives in shared
> but should be iOS-membership only (uses iOS-only WCSession delegate methods).
> The watch target uses **file-system-synchronized groups**, so files dropped in
> its folder auto-compile; shared/companion need explicit membership in Xcode.

---

## 4. Build / test / run

- **Build:** open `deuce/deuce.xcodeproj` in Xcode. Schemes:
  `deuce Watch App` and `DeuceCompanion`.
- **Tests:** `⌘U` on the watch scheme runs `ScoringEngineTests` +
  `AnalyticsTests` (Swift Testing). The test module imports
  `@testable import deuce_Watch_App` — keep new shared code in the watch target
  so tests can see it.
- **Sync testing:** needs a **paired iPhone+Watch** (real devices most reliable;
  a paired simulator pair works for `transferUserInfo`). Finish a match on the
  watch → it should appear in the companion's Matches tab. Historical matches
  back-fill on first connect (de-duped by UUID).
- There is **no Swift Package / `swift build`** anymore (an earlier
  `Package.swift` experiment was removed). Everything builds via Xcode.

---

## 5. Scoring engine (the testable core)

`ScoringEngine` (in `deuce shared/`) is a **pure, deterministic state machine**,
fully unit-tested, no SwiftUI/UIKit. `GameState` holds points/games/sets/server/
settings. Key rules:
- Points 0/15/30/40, Deuce/Advantage, No-Ad option.
- Set won at `gamesPerSet` (default 6, configurable 4) with 2-game lead, or 7-6
  tiebreak. Best-of 1/3/5 via `setsToWin` (1/2/3).
- Serve alternates each game; serve box (left/right) alternates each point and is
  derived, not stored.
`MatchViewModel` wraps the engine for the UI, owns undo history, and **logs
timestamps**: `firstPointOffset` (warmup), `pointOffsets`, `gameOffsets`,
`setOffsets` — all seconds since `matchStartDate`. Undo pops timestamp history too.

---

## 6. Data model & persistence (SwiftData)

Versioned schema with a migration plan, all in `MatchRecord.swift`:
- `DeuceSchemaV1` (shipped App Store v1.0; commit `4af667f…`)
- `DeuceSchemaV2` — added opponentName + timestamps + `KnownOpponent`
- `DeuceSchemaV3` (current) — added `id: UUID` (sync dedupe) + `notes: String`
- `DeuceMigrationPlan`: lightweight V1→V2→V3.
- Global typealiases `MatchRecord`/`KnownOpponent` point at **V3**. Both apps
  create their own `ModelContainer(for: Schema(versionedSchema: DeuceSchemaV3.self),
  migrationPlan: DeuceMigrationPlan.self)`.

`MatchRecord` (V3) fields: `id`, `date`, `surface`, `noAd`, `gamesPerSet`,
`setsToWin`, `isComplete`, `setsTop/Bottom`, `setScoresTop/Bottom[]`,
`currentGamesTop/Bottom`, `currentPointsTop/Bottom`, `didWin`, `opponentName`,
`notes`, `matchStartDate`, `firstPointOffset`, `pointOffsets[]`, `gameOffsets[]`,
`setOffsets[]`.
`KnownOpponent`: `name`, `lastPlayed`.

> Convention: `top` = opponent, `bottom` = you. `didWin` = bottom won.

`Analytics` (pure): win/loss & win-rate (completed only), H2H by opponent,
signed current streak, opponents-by-recency, surface breakdown, cumulative
win-rate trend, and per-match/aggregate **dynamics** (duration = last
pointOffset, warmup = firstPointOffset, rally gaps = diffs between consecutive
pointOffsets, longest/avg rally). All unit-tested in `AnalyticsTests`.

---

## 7. Watch ⇆ iPhone sync (one-way, WatchConnectivity)

Decision: **Watch Connectivity, not CloudKit** (no iCloud dependency, watch store
untouched). One-way **watch → phone**.
- `WatchSyncManager` (watch): `transferUserInfo(["match": jsonData])` per finished
  match; persists a set of sent UUIDs in `UserDefaults` for one-time back-fill.
  Triggered from `MatchView.saveAndExit` and `ContentView.onAppear/onChange`.
- `PhoneSyncManager` (iOS): `WCSessionDelegate.didReceiveUserInfo` → decode DTO →
  upsert into the iOS store, **de-dupe by UUID** (`FetchDescriptor` + `#Predicate`).
- Transport: `MatchRecordDTO` (Codable, ISO8601 dates).

**Mental model:** watch = capture device, iPhone = review/analyze device.
Phone→watch echo is **out of scope for v1** (edits on phone don't sync back).

---

## 8. Health & Strava (important context)

- `HealthManager` records an `HKWorkoutSession` (`.tennis`, `goalType = .time`),
  live heart rate / distance / steps / calories via `HKLiveWorkoutBuilder`.
  Start/stop is wrapped so call sites stay synchronous.
- Health opt-in is a toggle on `StartView` (`@AppStorage("healthOptIn")`); the
  workout only starts in-app when on. Workout saves cleanly to Apple Health.
- **Strava is a dead end without a paid dev subscription.** Researched June 2026:
  Strava only auto-imports workouts recorded by the **native Apple Workout app**,
  never third-party HKWorkouts. And as of **2026-06-01** the Strava API itself
  requires an $11.99/mo developer subscription. There is no public/inoffizial way
  to start the native Workout app with a type from a third-party app, and only one
  `HKWorkoutSession` can run at a time. **Resolution: the owner uses HealthFit**
  (one-time purchase) to bridge Health→Strava. Do not build a Strava integration.

---

## 9. UI conventions & polish already decided

- Court view = main page; pager order Score · Court · Health, Court selected by
  default. Undo lives in the watch status bar (NavigationStack toolbar).
- Serve marker = **tennis ball yellow** always (`#DBD11F`), independent of accent.
- Receiver = small white dot, diagonally opposite, both at their baseline corner.
- Player labels "You"/"Opponent" vertically centred at the left edge.
- Start screen: outline buttons for Serve/Sets/Games, filled colored buttons for
  Surface; accent color picker at the bottom (green/blue/tennis-yellow/purple/white,
  `@AppStorage("accentThemeKey")`). Section icons: `tennis.racket` (serve),
  `sportscourt` (surface).
- No green flash on game win; haptics only.

---

## 10. Localization

- `Localizable.xcstrings` (source `en`, with `de`) holds all watch UI strings.
  Use `String(localized:)` / `Text("…")` with the **English text as the key**.
- ⚠️ **The new companion (iOS) strings are not yet translated** — they currently
  fall back to the English keys. Run Xcode string extraction to populate the
  catalog, then add `de` values. Ensure the companion target has a localizable
  strings catalog in its membership.

---

## 11. App Store / submission learnings (hard-won)

- **Info.plist:** targets use `GENERATE_INFOPLIST_FILE = YES`. **Never** mix that
  with a physical `.plist` — set keys as `INFOPLIST_KEY_*` build settings instead.
  This bit us with `ITSAppUsesNonExemptEncryption`. (Also recorded in agent memory.)
- `ITSAppUsesNonExemptEncryption = NO` must be on the **container/iOS app** target
  (ASC reads it from the main bundle), not only the watch target.
- Watch app bundle id `…watchkitapp` must be **registered manually** in the
  Developer portal — Xcode Cloud automatic signing could not create it, which
  failed `-exportArchive` with exit 70.
- Xcode Cloud / archiving: build the **iOS app scheme** on the **iOS platform**,
  not the watch scheme / watchOS destination (that caused a "no destination
  matching watchOS" failure when it was still a watch-only container).
- The container needed `GENERATE_INFOPLIST_FILE = YES` so version keys land in
  its Info.plist (export failed without it).

---

## 12. Next steps / open items

1. **Make the companion build green:** finish target memberships (shared in both,
   companion iOS-only, `PhoneSyncManager` iOS-only), build both schemes, `⌘U`.
2. **Verify sync end-to-end** on paired devices (incl. historical back-fill).
3. **Localize companion strings** (DE+EN) via the string catalog.
4. **Companion app polish:** iOS app icon, iPhone screenshots in ASC, review as
   an iOS app (no longer watch-only).
5. Optional later: phone→watch echo, opponent selection before match start,
   complications/Digital Crown, deeper stats (per-surface win rate, opponent
   bilanz over time).

## 13. Gotchas

- Keep `ScoringEngine` and `Analytics` **pure** (Foundation only) so the watch
  test target keeps compiling them and tests stay fast.
- When bumping the schema, add a new `DeuceSchemaVx` + lightweight stage and move
  **both** global typealiases; update **both** apps' `ModelContainer` schema arg.
- SwiftData + WatchConnectivity delegate callbacks arrive off-main — hop to
  `@MainActor` before touching the `ModelContext` (PhoneSyncManager already does).
- `transferUserInfo` is queued/guaranteed but only flushes between a real paired
  watch app and its installed companion; simulators can be flaky.
