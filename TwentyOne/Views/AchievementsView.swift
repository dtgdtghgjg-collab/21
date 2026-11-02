import SwiftUI
import RealmSwift

struct AchievementsView: View {
    @ObservedResults(AppSettings.self) var settingsList
    var body: some View {
        List {
            ForEach(achievementDefinitions, id: \.id) { def in
                VStack(alignment: .leading, spacing: 4) {
                    Text(def.title)
                    Text(def.desc).font(.caption).foregroundStyle(.secondary)
                    Text("Награда: " + String(def.reward) + " P").font(.caption).foregroundStyle(.secondary)
                    if AchievementService.isClaimed(def.id) { Text("Получено").foregroundStyle(.green) } else if AchievementService.isUnlocked(def.id) { Button("Забрать награду") { _ = AchievementService.claim(def) } } else { Text("Ещё не открыто").font(.caption).foregroundStyle(.secondary) }
                }
            }
        }
        .navigationTitle("Достижения")
    }
}
