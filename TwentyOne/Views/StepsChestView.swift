import SwiftUI
import RealmSwift

struct StepsChestView: View {
    let steps: Int
    @State private var claimed = false
    var body: some View {
        Group {
            if steps < 8000 { Text("Сундук за шаги: \(steps) / 8000 шагов").font(.caption).foregroundStyle(.secondary) } else if claimed { StatPill(icon: "checkmark.circle.fill", text: "Сундук за шаги получен", color: TwentyOneTab.dailies.theme.accent) } else { Button("Открыть сундук за шаги") { claim() }.buttonStyle(TwentyPrimaryButtonStyle(color: TwentyOneTab.dailies.theme.accent)) }
        }
        .onAppear { claimed = UserDefaults.standard.string(forKey: "stepsChestDate") == dayKey() }
    }
    func dayKey() -> String { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: Date()) }
    func claim() {
        guard steps >= 8000, !claimed else { return }
        let reward = Int.random(in: 150...350)
        RealmStore.write { realm in guard let liveUser = RealmStore.user(in: realm) else { return }; liveUser.pesetas += reward; liveUser.xp += 25; while liveUser.xp >= User.xpForNextLevel(liveUser.level) { liveUser.xp -= User.xpForNextLevel(liveUser.level); liveUser.level += 1 } }
        UserDefaults.standard.set(dayKey(), forKey: "stepsChestDate")
        claimed = true
        HistoryService.log("steps_chest", "Сундук за шаги открыт", xp: 25, pesetas: reward)
        Haptics.success(); SoundService.coin()
    }
}
