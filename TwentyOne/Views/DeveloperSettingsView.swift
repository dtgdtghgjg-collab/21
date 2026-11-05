import SwiftUI
import RealmSwift

struct DeveloperSettingsView: View {
    @ObservedResults(User.self) var users
    var user: User? { users.first }
    var body: some View {
        SwiftUI.List {
            Section("Персонаж") {
                Text("Уровень: \(user?.level ?? 0)")
                Text("XP: \(user?.xp ?? 0)")
                Text("Песеты: \(user?.pesetas ?? 0) P")
                Button("+1000 XP") { addXP(1000) }
                Button("+10000 P") { addPesetas(10000) }
                Button("+1 уровень") { addLevel() }
            }
            Section("Рынок и лутбокс") {
                Button("Открыть чёрный рынок сейчас") { openBlackMarketNow() }
                Button("Сбросить лутбокс") { resetLootbox() }
                Button("Сбросить сон и воду") { resetTrackers() }
            }
            Section("Сброс") {
                Button("Удалить все дейлики") { deleteAllDailies() }
                Button("Сбросить штрафы за пропуски") { resetPenalties() }
            }
        }
        .scrollContentBackground(.hidden)
        .background(TwentyOneTab.bosses.theme.gradient)
        .tint(TwentyOneTab.bosses.theme.accent)
        .navigationTitle("Настройки разработчика")
    }
    func addXP(_ amount: Int) {
        guard let realm = try? Realm(), let user = realm.objects(User.self).first else { return }
        try? realm.write {
            user.xp += amount
            while user.xp >= User.xpForNextLevel(user.level) { user.xp -= User.xpForNextLevel(user.level); user.level += 1 }
        }
    }
    func addPesetas(_ amount: Int) {
        guard let realm = try? Realm(), let user = realm.objects(User.self).first else { return }
        try? realm.write { user.pesetas += amount }
    }
    func addLevel() {
        guard let realm = try? Realm(), let user = realm.objects(User.self).first else { return }
        try? realm.write { user.xp = 0; user.level += 1 }
    }
    func openBlackMarketNow() {
        guard let realm = try? Realm(), let s = realm.objects(AppSettings.self).first else { return }
        let today = Calendar.current.startOfDay(for: Date())
        let until = Calendar.current.date(byAdding: .day, value: 2, to: today) ?? today
        try? realm.write { s.blackMarketNextDate = today; s.blackMarketVisibleUntil = until }
    }
    func resetLootbox() {
        guard let realm = try? Realm(), let s = realm.objects(AppSettings.self).first else { return }
        try? realm.write { s.lootboxLastDate = nil }
    }
    func resetTrackers() {
        guard let realm = try? Realm(), let s = realm.objects(AppSettings.self).first else { return }
        try? realm.write { s.sleepHours = 0; s.waterLiters = 0 }
    }
    func deleteAllDailies() {
        guard let realm = try? Realm() else { return }
        try? realm.write { realm.delete(realm.objects(Daily.self)) }
    }
    func resetPenalties() {
        guard let realm = try? Realm(), let s = realm.objects(AppSettings.self).first else { return }
        try? realm.write { s.lastDailyPenaltyDate = nil; s.dailyPenaltyTotal = 0 }
    }
}
