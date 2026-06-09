#if os(iOS)

import Foundation
import SwiftData
import WatchConnectivity

final class PhoneSyncManager: NSObject, WCSessionDelegate {

    static let shared = PhoneSyncManager()

    private var container: ModelContainer?
    private var pending: [MatchRecordDTO] = []
    private var latestUpdates: [MatchRecordDTO] = []

    private override init() { super.init() }

    func configure(container: ModelContainer) {
        self.container = container
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
        print("WCSession (phone) activating paired=\(WCSession.default.isPaired) installed=\(WCSession.default.isWatchAppInstalled)")
    }

    func send(_ record: MatchRecord) {
        send(MatchRecordDTO(record))
    }

    func send(_ dto: MatchRecordDTO) {
        guard WCSession.isSupported() else { return }
        pending.append(dto)
        latestUpdates.removeAll { $0.id == dto.id }
        latestUpdates.append(dto)
        flushPending()
    }

    private func flushPending() {
        guard WCSession.default.activationState == .activated else { return }
        let unique = Dictionary(grouping: pending, by: \.id).compactMap { $0.value.last }
        pending.removeAll()

        for dto in unique {
            guard let data = dto.encoded() else { continue }
            WCSession.default.transferUserInfo(["match": data])
            print("WCSession (phone) queued match update \(dto.id)")
            sendImmediatelyIfReachable(data: data, id: dto.id)
        }

        guard let snapshot = MatchRecordDTO.encode(latestUpdates), !latestUpdates.isEmpty else { return }
        do {
            try WCSession.default.updateApplicationContext(["matches": snapshot])
            print("WCSession (phone) updated match updates count=\(latestUpdates.count)")
        } catch {
            print("WCSession (phone) failed to update match updates: \(error)")
        }
    }

    // MARK: - Receiving

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        receiveMatches(from: userInfo)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        receiveMatches(from: applicationContext)
    }

    private func receiveMatches(from payload: [String: Any]) {
        if let data = payload["match"] as? Data,
           let dto = MatchRecordDTO.decode(from: data) {
            print("WCSession (phone) received match \(dto.id)")
            Task { @MainActor in self.upsert(dto) }
            return
        }

        if let data = payload["matches"] as? Data,
           let dtos = MatchRecordDTO.decodeList(from: data) {
            print("WCSession (phone) received match snapshot count=\(dtos.count)")
            for dto in dtos {
                Task { @MainActor in self.upsert(dto) }
            }
            return
        }

        if !payload.isEmpty {
            print("WCSession (phone) received invalid payload keys=\(payload.keys)")
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
                print("WCSession (phone) skipped match \(id) incoming=\(dto.syncUpdatedAt) existing=\(existing.syncUpdatedAt)")
                return
            }
            existing.apply(dto)
        } else {
            context.insert(dto.makeRecord())
        }

        do {
            try context.save()
            print("WCSession (phone) saved match \(id)")
        } catch {
            print("WCSession (phone) failed to save match \(id): \(error)")
        }
    }

    private func shouldApply(_ dto: MatchRecordDTO, to existing: MatchRecord) -> Bool {
        if dto.syncUpdatedAt > existing.syncUpdatedAt { return true }
        if dto.syncUpdatedAt == existing.syncUpdatedAt {
            return dto.isDeleted && !existing.isDeleted
        }
        return false
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        if let error { print("WCSession (phone) activation error: \(error)") }
        print("WCSession (phone) activation state=\(activationState.rawValue) paired=\(session.isPaired) installed=\(session.isWatchAppInstalled)")
        guard activationState == .activated else { return }
        receiveMatches(from: session.receivedApplicationContext)
        flushPending()
        requestWatchSync(session)
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        flushPending()
    }

    private func sendImmediatelyIfReachable(data: Data, id: UUID) {
        let session = WCSession.default
        guard session.isReachable else {
            print("WCSession (phone) watch not reachable for immediate match update \(id)")
            return
        }
        session.sendMessage(["match": data], replyHandler: { reply in
            print("WCSession (phone) immediate match update \(id) reply=\(reply)")
        }, errorHandler: { error in
            print("WCSession (phone) immediate match update \(id) failed: \(error)")
        })
    }

    private func requestWatchSync(_ session: WCSession) {
        guard session.isReachable else {
            print("WCSession (phone) watch not reachable for sync request")
            return
        }
        session.sendMessage(["request": "syncMatches"], replyHandler: { reply in
            print("WCSession (phone) sync request reply=\(reply)")
        }, errorHandler: { error in
            print("WCSession (phone) sync request failed: \(error)")
        })
    }
}

#endif
