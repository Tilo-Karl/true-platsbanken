import Foundation
import BackgroundTasks

final class MatchUpdateService {
    static let shared = MatchUpdateService()
    static let taskIdentifier = "com.trueplatsbanken.matchrefresh"

    enum Trigger {
        case appLaunch
        case matchesAppear
        case background
    }

    private let defaults: UserDefaults
    private let minimumInterval: TimeInterval = 24 * 60 * 60
    private let staleLockInterval: TimeInterval = 30 * 60

    private enum Keys {
        static let lastRun = "matches.lastRunAt"
        static let inProgress = "matches.updateInProgress"
        static let lockStartedAt = "matches.updateLockStartedAt"
        static let paidUntil = "matches.paidUntil"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var lastMatchRun: Date? {
        defaults.object(forKey: Keys.lastRun) as? Date
    }

    var paidUntil: Date? {
        defaults.object(forKey: Keys.paidUntil) as? Date
    }

    func isEntitled(now: Date = Date()) -> Bool {
        guard let paidUntil else { return false }
        return paidUntil >= now
    }

    func extendPaidWindow(days: Int, now: Date = Date()) {
        let seconds = TimeInterval(days * 24 * 60 * 60)
        let base = max(now, paidUntil ?? now)
        defaults.set(base.addingTimeInterval(seconds), forKey: Keys.paidUntil)
        let untilLabel = base.addingTimeInterval(seconds).formatted(date: .numeric, time: .shortened)
        print("[matches] entitlement extended until \(untilLabel)")
    }

    func shouldUpdateMatches(now: Date = Date()) -> Bool {
        guard let lastRun = lastMatchRun else {
            return true
        }
        return now.timeIntervalSince(lastRun) >= minimumInterval
    }

    func acquireLock(now: Date = Date()) -> Bool {
        if defaults.bool(forKey: Keys.inProgress) {
            if let startedAt = defaults.object(forKey: Keys.lockStartedAt) as? Date,
               now.timeIntervalSince(startedAt) > staleLockInterval {
                clearLock()
            } else {
                return false
            }
        }

        defaults.set(now, forKey: Keys.lockStartedAt)
        defaults.set(true, forKey: Keys.inProgress)
        return true
    }

    func clearLock() {
        defaults.set(false, forKey: Keys.inProgress)
        defaults.removeObject(forKey: Keys.lockStartedAt)
    }

    func recordSuccessfulRun(at date: Date = Date()) {
        defaults.set(date, forKey: Keys.lastRun)
    }

    func scheduleBackgroundRefresh() {
        guard isEntitled() else {
            print("[matches] background refresh not scheduled (entitlement expired)")
            return
        }
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: minimumInterval)
        do {
            try BGTaskScheduler.shared.submit(request)
            print("[matches] scheduled background refresh")
        } catch {
            print("[matches] Failed to schedule background refresh: \(error)")
        }
    }

    func handleBackgroundTask(_ task: BGAppRefreshTask, appState: AppStateViewModel) {
        scheduleBackgroundRefresh()
        print("[matches] background task started")

        task.expirationHandler = { [weak self] in
            print("[matches] background task expired")
            self?.clearLock()
        }

        Task { @MainActor [weak self] in
            guard let self else {
                task.setTaskCompleted(success: false)
                return
            }

            enum Outcome {
                case completed(Bool)
                case timedOut
            }

            let outcome = await withTaskGroup(of: Outcome.self) { group in
                group.addTask {
                    let success = await self.runMatchUpdateIfNeeded(appState: appState, trigger: .background)
                    return .completed(success)
                }
                group.addTask {
                    try? await Task.sleep(nanoseconds: 25 * 1_000_000_000)
                    return .timedOut
                }

                let first = await group.next() ?? .timedOut
                group.cancelAll()
                return first
            }

            switch outcome {
            case .completed(let success):
                print("[matches] background task completed success=\(success)")
                task.setTaskCompleted(success: success)
            case .timedOut:
                print("[matches] background task timed out")
                self.clearLock()
                task.setTaskCompleted(success: false)
            }
        }
    }

    @MainActor
    func runMatchUpdateIfNeeded(appState: AppStateViewModel, trigger: Trigger) async -> Bool {
        let lastRun = lastMatchRun
        let lastRunLabel = lastRun?.formatted(date: .numeric, time: .shortened) ?? "never"
        let entitlementLabel = isEntitled() ? "active" : "expired"
        print("[matches] update check trigger=\(trigger) lastRun=\(lastRunLabel) entitlement=\(entitlementLabel)")
        guard appState.matchFlowStep == .idle else { return false }
        guard appState.matchMode == .live else { return false }
        guard isEntitled() else { return false }
        guard !appState.profileEditorViewModel.isDemoProfile else { return false }
        guard appState.profileEditorViewModel.canMatch else { return false }
        guard shouldUpdateMatches() else { return false }
        guard acquireLock() else { return false }

        let previousSnapshot = MatchSnapshotStore().loadSnapshot() ?? []
        let previousLastRun = lastMatchRun
        defer { clearLock() }
        print("[matches] update started")

        guard let payload = appState.profileEditorViewModel.matchPayload() else {
            return false
        }

        let loaded = await appState.matchResultsViewModel.loadMatches(payload: payload, persist: false)
        guard let loaded, appState.matchResultsViewModel.errorMessage == nil else {
            print("[matches] update failed to load matches")
            return false
        }

        let marked = markNewMatches(loaded, since: previousLastRun, previousSnapshot: previousSnapshot)
        appState.matchResultsViewModel.replaceMatches(marked, persist: true)
        recordSuccessfulRun()
        print("[matches] update finished count=\(marked.count)")
        return true
    }

    func markNewMatches(
        _ matches: [MatchResult],
        since lastRun: Date?,
        previousSnapshot: [MatchResult]
    ) -> [MatchResult] {
        let previousIds = Set(previousSnapshot.map { $0.id })

        return matches.map { match in
            var updated = match
            let isNewByDate: Bool
            if let lastRun, let published = match.job.publishedAt {
                isNewByDate = published >= lastRun
            } else {
                isNewByDate = lastRun == nil
            }
            let isNewById = lastRun == nil ? true : !previousIds.contains(match.id)
            updated.isNewToday = isNewByDate || isNewById
            return updated
        }
    }
}
