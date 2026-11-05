import Foundation

enum StreakRewardService {
    private static let daysKey = "allDailiesDoneDays"
    private static let frameKey = "avatarFrameGoldUnlocked"
    static var frameUnlocked: Bool { UserDefaults.standard.bool(forKey: frameKey) }
    static func record(day: Date) {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        var days = Set(UserDefaults.standard.stringArray(forKey: daysKey) ?? [])
        days.insert(f.string(from: day))
        UserDefaults.standard.set(Array(days), forKey: daysKey)
        if currentStreak() >= 7 { UserDefaults.standard.set(true, forKey: frameKey) }
    }
    static func currentStreak() -> Int {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        let days = Set(UserDefaults.standard.stringArray(forKey: daysKey) ?? [])
        var streak = 0
        var cursor = Calendar.current.startOfDay(for: Date())
        if !days.contains(f.string(from: cursor)) { cursor = Calendar.current.date(byAdding: .day, value: -1, to: cursor) ?? cursor }
        while days.contains(f.string(from: cursor)) { streak += 1; cursor = Calendar.current.date(byAdding: .day, value: -1, to: cursor) ?? cursor }
        return streak
    }
}
