import Foundation
import Observation

@MainActor
@Observable
final class HydrationStore {
    static let defaultDailyGoalML = 2000
    static let freeHistoryWindowDays = 7

    var dailyGoalML: Int = HydrationStore.defaultDailyGoalML
    var entries: [HydrationEntry] = []

    private let storageKey = "waternow.entries.v1"
    private let goalKey = "waternow.dailyGoal.v1"

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
