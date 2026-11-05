import SwiftUI
import RealmSwift

struct DailyQuestDef: Identifiable {
    let id: String
    let title: String
    let target: Int
    let rewardPesetas: Int
    let rewardXp: Int
    let kind: String
}

struct DailyQuestsView: View {
    @ObservedResults(HistoryEntry.self) var entries
    @State private var claimed: Set<String> = []
    private let pool: [DailyQuestDef] = [
        DailyQuestDef(id: "daily3", title: "Выполни 3 дейлика", target: 3, rewardPesetas: 200, rewardXp: 30, kind: "daily"),
        DailyQuestDef(id: "daily5", title: "Выполни 5 дейликов", target: 5, rewardPesetas: 400, rewardXp: 60, kind: "daily"),
        DailyQuestDef(id: "spend500", title: "Потрать 500 песет", target: 500, rewardPesetas: 150, rewardXp: 20, kind: "spend"),
        DailyQuestDef(id: "boss1", title: "Победи босса", target: 1, rewardPesetas: 500, rewardXp: 80, kind: "boss"),
        DailyQuestDef(id: "focus1", title: "Заверши фокус-сессию", target: 1, rewardPesetas: 180, rewardXp: 40, kind: "focus")
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(todayQuests()) { quest in
                VStack(alignment: .leading, spacing: 6) {
                    Text(quest.title).font(.system(size: 15, weight: .semibold, design: .rounded))
                    Text("Прогресс: \(min(progress(for: quest), quest.target)) / \(quest.target)").font(.caption).foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        StatPill(icon: "banknote.fill", text: "\(quest.rewardPesetas) P", color: AppPalette.gold)
                        StatPill(icon: "star.fill", text: "\(quest.rewardXp) XP", color: TwentyOneTab.dailies.theme.accent)
                        if claimed.contains(quest.id) { StatPill(icon: "checkmark.circle.fill", text: "Получено", color: TwentyOneTab.dailies.theme.accent) } else { Button("Забрать") { claim(quest) }.buttonStyle(TwentyPrimaryButtonStyle(color: TwentyOneTab.dailies.theme.accent)).disabled(progress(for: quest) < quest.target) }
                    }
                }
            }
        }
        .onAppear { loadClaimed() }
    }
    func dayKey() -> String { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: Date()) }
    func todayQuests() -> [DailyQuestDef] {
        let key = "dailyQuests_" + dayKey()
        if let stored = UserDefaults.standard.string(forKey: key) { let ids = stored.components(separatedBy: ","); let quests = pool.filter { ids.contains($0.id) }; if quests.count == 3 { return quests } }
        let picked = Array(pool.shuffled().prefix(3))
        UserDefaults.standard.set(picked.map { $0.id }.joined(separator: ","), forKey: key)
        return picked
    }
    func progress(for quest: DailyQuestDef) -> Int {
        let today = entries.filter { Calendar.current.isDateInToday($0.date) }
        switch quest.kind {
        case "daily": return today.filter { $0.kind == "daily_complete" }.count
        case "boss": return today.filter { $0.kind == "boss_defeated" }.count
        case "focus": return today.filter { $0.kind == "focus_complete" }.count
        case "spend": return today.filter { $0.kind == "purchase" }.reduce(0) { $0 + max(-$1.pesetasDelta, 0) }
        default: return 0
        }
    }
    func loadClaimed() { let raw = UserDefaults.standard.string(forKey: "dailyQuestClaimed_" + dayKey()) ?? ""; claimed = Set(raw.components(separatedBy: ",").filter { !$0.isEmpty }) }
    func claim(_ quest: DailyQuestDef) {
        guard progress(for: quest) >= quest.target, !claimed.contains(quest.id) else { return }
        RealmStore.write { realm in
            guard let liveUser = RealmStore.user(in: realm) else { return }
            liveUser.pesetas += quest.rewardPesetas
            liveUser.xp += quest.rewardXp
            while liveUser.xp >= User.xpForNextLevel(liveUser.level) { liveUser.xp -= User.xpForNextLevel(liveUser.level); liveUser.level += 1 }
        }
        claimed.insert(quest.id)
        UserDefaults.standard.set(claimed.joined(separator: ","), forKey: "dailyQuestClaimed_" + dayKey())
        HistoryService.log("daily_quest", "Ежедневный квест: " + quest.title, xp: quest.rewardXp, pesetas: quest.rewardPesetas)
        Haptics.success(); SoundService.coin()
    }
}
