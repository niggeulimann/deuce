#if os(watchOS)

import Foundation
import SwiftData
import WatchConnectivity

/// Watch side of the match sync. Pushes local match changes to the iPhone and
/// accepts newer iPhone changes, including tombstones for deletes.
final class WatchSyncManager: NSObject, WCSessionDelegate {

    static let shared = WatchSyncManager()

    private let defaultsKey = "syncedMatchIDs"
    private var pending: [MatchRecordDTO] = []
    private var latestSnapshot: [MatchRecordDTO] = []
    private var container: ModelContainer?
    private var session: WCSession? {
        WCSession.isSupported() ? WCSession.default : nil
    }

    private override init() {
        super.init()
    }

    // MARK: - Lifecycle

    func configure(container: ModelContainer) {
        self.container = container
        activate()
    }

    func activate() {
        guard let session else { return }
        session.delegate = self
        if session.activationState != .activated {
            session.activate()
        } else {
            flushPending()
        }
    }

    // MARK: - Sending

    /// Queue/send a single record. The iPhone de-dupes by UUID, so retrying is safe.
    func send(_ dto: MatchRecordDTO) {
        pending.append(dto)
        latestSnapshot.removeAll { $0.id == dto.id }
        latestSnapshot.append(dto)
        activate()
    }

    /// Back-fill all records. The iPhone de-dupes by UUID, so this can run often.
    func sync(_ dtos: [MatchRecordDTO]) {
        latestSnapshot = dtos
        pending.append(contentsOf: dtos)
        activate()
    }

    private func flushPending() {
        guard let session, session.activationState == .activated else { return }
        let unique = Dictionary(grouping: pending, by: \.id).compactMap { $0.value.last }
        pending.removeAll()

        for dto in unique {
            guard let data = dto.encoded() else { continue }
            let transfer = session.transferUserInfo(["match": data])
            print("Queued match sync \(dto.id) pending=\(transfer.isTransferring)")
        }

        guard let snapshot = MatchRecordDTO.encode(latestSnapshot), !latestSnapshot.isEmpty else { return }
        do {
            try session.updateApplicationContext(["matches": snapshot])
            print("Updated match snapshot count=\(latestSnapshot.count)")
        } catch {
            print("Failed to update match snapshot: \(error)")
        }
    }

    // MARK: - Sent-ID bookkeeping

    private var sentIDs: Set<UUID> {
        get {
            let strings = UserDefaults.standard.stringArray(forKey: defaultsKey) ?? []
            return Set(strings.compactMap(UUID.init(uuidString:)))
        }
        set {
            UserDefaults.standard.set(newValue.map(\.uuidString), forKey: defaultsKey)
        }
    }

    private func markSent(_ id: UUID) {
        var ids = sentIDs
        ids.insert(id)
        sentIDs = ids
    }

    private func updateSnapshot(with dto: MatchRecordDTO) {
        latestSnapshot.removeAll { $0.id == dto.id }
        latestSnapshot.append(dto)
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        if let error { print("WCSession (watch) activation error: \(error)") }
        if activationState == .activated {
            receiveMatches(from: session.receivedApplicationContext)
            flushPending()
        }
    }

    func session(_ session: WCSession,
                 didFinish userInfoTransfer: WCSessionUserInfoTransfer,
                 error: Error?) {
        guard error == nil,
              let data = userInfoTransfer.userInfo["match"] as? Data,
              let dto = MatchRecordDTO.decode(from: data) else {
            if let error { print("WCSession transfer error: \(error)") }
            return
        }
        markSent(dto.id)
        print("Finished match sync \(dto.id)")
    }

    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any],
                 replyHandler: @escaping ([String: Any]) -> Void) {
        if message["match"] != nil || message["matches"] != nil {
            receiveMatches(from: message)
            replyHandler(["ok": true])
            return
        }

        guard message["request"] as? String == "syncMatches" else {
            replyHandler(["ok": false])
            return
        }
        flushPending()
        replyHandler(["ok": true, "count": latestSnapshot.count])
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        receiveMatches(from: userInfo)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        receiveMatches(from: applicationContext)
    }

    private func receiveMatches(from payload: [String: Any]) {
        if let data = payload["match"] as? Data,
           let dto = MatchRecordDTO.decode(from: data) {
            print("WCSession (watch) received match \(dto.id) deleted=\(dto.isDeleted) opponent=\(dto.opponentName)")
            Task { @MainActor in self.upsert(dto) }
            return
        }
        if let data = payload["matches"] as? Data,
           let dtos = MatchRecordDTO.decodeList(from: data) {
            print("WCSession (watch) received match updates count=\(dtos.count)")
            for dto in dtos {
                Task { @MainActor in self.upsert(dto) }
            }
        }
    }

    @MainActor
    private func upsert(_ dto: MatchRecordDTO) {
        guard let container else { return }
        let context = container.mainContext
        let id = dto.id
        let descriptor = FetchDescriptor<MatchRecord>(predicate: #Predicate { $0.id == id })
        if let existing = (try? context.fetch(descriptor))?.first {
            guard shouldApply(dto, to: existing) else {
                print("WCSession (watch) skipped match \(id) incoming=\(dto.syncUpdatedAt) existing=\(existing.syncUpdatedAt)")
                return
            }
            existing.apply(dto)
        } else {
            context.insert(dto.makeRecord())
        }
        do {
            try context.save()
            updateSnapshot(with: dto)
            print("WCSession (watch) saved match \(id)")
        } catch {
            print("WCSession (watch) failed to save match \(id): \(error)")
        }
    }

    private func shouldApply(_ dto: MatchRecordDTO, to existing: MatchRecord) -> Bool {
        if dto.syncUpdatedAt > existing.syncUpdatedAt { return true }
        if dto.syncUpdatedAt == existing.syncUpdatedAt {
            return !existing.hasSameSyncContent(as: dto)
        }
        return false
    }
}

#endif
