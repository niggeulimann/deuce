import Foundation
import HealthKit
import Observation

@Observable
final class HealthManager: NSObject {

    // MARK: - Auth state
    private(set) var isAuthorized = false

    // MARK: - Live metrics
    private(set) var heartRate: Double = 0          // bpm
    private(set) var activeCalories: Double = 0     // kcal
    private(set) var distance: Double = 0           // metres
    private(set) var steps: Double = 0              // count
    private(set) var elapsedSeconds: Int = 0
    private(set) var isRunning = false

    // MARK: - Private
    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var timer: Timer?
    private var sessionStart: Date?
    private var isStarting = false

    private let typesToShare: Set<HKSampleType> = [
        HKObjectType.workoutType()
    ]
    private let typesToRead: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!
    ]

    // MARK: - Auth

    @discardableResult
    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        do {
            try await store.requestAuthorization(toShare: typesToShare, read: typesToRead)
            let status = store.authorizationStatus(for: HKObjectType.workoutType())
            let authorized = status == .sharingAuthorized
            await MainActor.run { isAuthorized = authorized }
            return authorized
        } catch {
            print("HealthKit auth error: \(error)")
            return false
        }
    }

    func checkAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let status = store.authorizationStatus(for: HKObjectType.workoutType())
        isAuthorized = (status == .sharingAuthorized)
    }

    // MARK: - Workout lifecycle
    // Both methods are synchronous at call-site; async work is wrapped internally.

    func startWorkout() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        guard isAuthorized else { return }
        guard session == nil, !isStarting else { return }
        isStarting = true
        Task { await _startWorkout() }
    }

    func stopWorkout() {
        guard session != nil || builder != nil || isRunning || isStarting else { return }
        session?.end()
        stopTimer()
        isStarting = false
        isRunning = false
    }

    private func _startWorkout() async {
        let config = HKWorkoutConfiguration()
        config.activityType = .tennis
        config.locationType  = .outdoor
        do {
            let newSession = try HKWorkoutSession(healthStore: store, configuration: config)
            let newBuilder = newSession.associatedWorkoutBuilder()
            newBuilder.dataSource = HKLiveWorkoutDataSource(
                healthStore: store,
                workoutConfiguration: config
            )
            newSession.delegate = self
            newBuilder.delegate = self
            self.session = newSession
            self.builder = newBuilder
            let start = Date()
            sessionStart = start
            newSession.startActivity(with: start)
            try? await newBuilder.beginCollection(at: start)
            await MainActor.run {
                isStarting = false
                isRunning = true
                startTimer()
            }
        } catch {
            print("Workout start error: \(error)")
            await MainActor.run {
                isStarting = false
                session = nil
                builder = nil
                sessionStart = nil
            }
        }
    }

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let start = self.sessionStart else { return }
            let elapsed = Int(Date().timeIntervalSince(start))
            DispatchQueue.main.async { self.elapsedSeconds = elapsed }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Metric helpers

    var elapsedFormatted: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }

    var distanceFormatted: String {
        distance >= 1000
            ? String(format: "%.1f km", distance / 1000)
            : String(format: "%.0f m", distance)
    }
}

// MARK: - HKWorkoutSessionDelegate

extension HealthManager: HKWorkoutSessionDelegate {
    func workoutSession(_ session: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) {
        DispatchQueue.main.async {
            self.isRunning = (toState == .running)
        }
        if toState == .ended {
            builder?.endCollection(withEnd: date) { [weak self] _, _ in
                self?.builder?.finishWorkout { [weak self] _, _ in
                    DispatchQueue.main.async {
                        self?.builder = nil
                        self?.session = nil
                        self?.sessionStart = nil
                        self?.isStarting = false
                    }
                }
            }
        }
    }

    func workoutSession(_ session: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session error: \(error)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate

extension HealthManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                        didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            guard let stats = workoutBuilder.statistics(for: quantityType) else { continue }

            DispatchQueue.main.async {
                switch quantityType.identifier {
                case HKQuantityTypeIdentifier.heartRate.rawValue:
                    self.heartRate = stats.mostRecentQuantity()?.doubleValue(for: .count().unitDivided(by: .minute())) ?? 0

                case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
                    self.activeCalories = stats.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0

                case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
                    self.distance = stats.sumQuantity()?.doubleValue(for: .meter()) ?? 0

                case HKQuantityTypeIdentifier.stepCount.rawValue:
                    self.steps = stats.sumQuantity()?.doubleValue(for: .count()) ?? 0

                default: break
                }
            }
        }
    }
}
