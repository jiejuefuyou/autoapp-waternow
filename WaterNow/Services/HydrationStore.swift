import Foundation
import Observation
#if canImport(UserNotifications)
import UserNotifications
#endif

@MainActor
@Observable
final class HydrationStore {
    static let defaultDailyGoalML = 2000
    static let freeHistoryWindowDays = 7
    /// Default mid-day reminder slot used on first launch (24h time).
    static let defaultReminderHour = 12
    static let defaultReminderMinute = 0
    /// Stable identifier for the default mid-day reminder so we can cancel/replace it.
    static let defaultReminderIdentifier = "waternow.reminder.midday"

    var dailyGoalML: Int = HydrationStore.defaultDailyGoalML
    var entries: [HydrationEntry] = []

    private let storageKey = "waternow.entries.v1"
    private let goalKey = "waternow.dailyGoal.v1"
    private let reminderInstalledKey = "waternow.reminder.default.installed.v1"
    private let notificationAuthRequestedKey = "waternow.notifications.auth.requested.v1"

    init() {
        load()
    }

    func todayTotal() -> Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return entries
            .filter { cal.startOfDay(for: $0.loggedAt) == today }
            .reduce(0) { $0 + $1.amountML }
    }

    func todayPercent() -> Double {
        guard dailyGoalML > 0 else { return 0 }
        return min(1.0, Double(todayTotal()) / Double(dailyGoalML))
    }

    func add(_ amount: Int, beverage: BeverageType = .water) {
        let entry = HydrationEntry(amountML: amount, beverage: beverage)
        entries.append(entry)
        persist()
    }

    func remove(_ entry: HydrationEntry) {
        entries.removeAll { $0.id == entry.id }
        persist()
    }

    /// Remove the most-recent entry of exactly the given amount logged today.
    /// Used by the 8-cup grid: tapping a filled cup un-logs the most recent
    /// glass-sized entry, leaving custom-volume entries untouched.
    func removeLastEntryOfAmount(_ amountML: Int) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        if let idx = entries.lastIndex(where: { $0.amountML == amountML && cal.startOfDay(for: $0.loggedAt) == today }) {
            entries.remove(at: idx)
            persist()
        }
    }

    func setGoal(_ ml: Int) {
        dailyGoalML = ml
        UserDefaults.standard.set(ml, forKey: goalKey)
    }

    /// Most recent N days of total. For chart.
    func dailyTotals(lastDays: Int) -> [(Date, Int)] {
        let cal = Calendar.current
        var result: [(Date, Int)] = []
        for offset in (0..<lastDays).reversed() {
            let day = cal.startOfDay(for: cal.date(byAdding: .day, value: -offset, to: Date()) ?? Date())
            let total = entries
                .filter { cal.startOfDay(for: $0.loggedAt) == day }
                .reduce(0) { $0 + $1.amountML }
            result.append((day, total))
        }
        return result
    }

    // MARK: - Streak

    /// Consecutive days (counting back from today) where dailyGoal was hit.
    /// Today is included only if today's total is already >= goal; otherwise
    /// the streak counts back from yesterday so the user isn't penalized for
    /// being mid-day.
    func currentStreakDays() -> Int {
        guard dailyGoalML > 0 else { return 0 }
        let cal = Calendar.current
        var streak = 0
        var cursor = cal.startOfDay(for: Date())
        let todayTotal = self.todayTotal()
        if todayTotal >= dailyGoalML {
            streak += 1
            cursor = cal.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        } else {
            // Don't break the streak just because today is still in progress;
            // begin counting from yesterday.
            cursor = cal.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        // Walk backwards while each day hit goal. Cap at 365 to bound work.
        var safety = 0
        while safety < 365 {
            safety += 1
            let dayStart = cursor
            let total = entries
                .filter { cal.startOfDay(for: $0.loggedAt) == dayStart }
                .reduce(0) { $0 + $1.amountML }
            if total >= dailyGoalML {
                streak += 1
                cursor = cal.date(byAdding: .day, value: -1, to: cursor) ?? cursor
            } else {
                break
            }
        }
        return streak
    }

    // MARK: - Notifications

    /// Request `.alert + .sound` authorization once. Calling repeatedly is
    /// safe — UNUserNotificationCenter is idempotent and we additionally
    /// track a UserDefaults flag so we only present the system prompt on
    /// the first cold launch where it can succeed.
    func requestNotificationAuthorizationIfNeeded() async {
        #if canImport(UserNotifications)
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: notificationAuthRequestedKey) { return }
        defaults.set(true, forKey: notificationAuthRequestedKey)
        do {
            _ = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        } catch {
            // Silent — user can re-enable in Settings.app. Failure is non-fatal.
        }
        #endif
    }

    /// Ensure the default mid-day reminder is scheduled the first time the
    /// app launches with notifications granted. Pro users can layer more
    /// reminders on top via SettingsView; the default slot is always present.
    func ensureDefaultReminder() {
        #if canImport(UserNotifications)
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: reminderInstalledKey) else { return }
        defaults.set(true, forKey: reminderInstalledKey)

        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Time to hydrate", comment: "Reminder title")
        content.body = NSLocalizedString("Tap to log your water intake.", comment: "Reminder body")
        content.sound = .default

        var date = DateComponents()
        date.hour = HydrationStore.defaultReminderHour
        date.minute = HydrationStore.defaultReminderMinute
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)

        let req = UNNotificationRequest(
            identifier: HydrationStore.defaultReminderIdentifier,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
        #endif
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        if let goal = UserDefaults.standard.value(forKey: goalKey) as? Int {
            dailyGoalML = goal
        }
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([HydrationEntry].self, from: data) else {
            return
        }
        entries = decoded
    }
}
