import SwiftUI
import RealmSwift

struct AchievementsView: View {
    @ObservedResults(AppSettings.self) var settingsList
    var body: some View {
        SwiftUI.List {
            ForEach(achievementDefinitions, id: \.id) { def in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) { Image(systemName: AchievementService.isClaimed(def.id) ? "trophy.fill" : "trophy").foregroundStyle(AppPalette.gold); Text(def.title).font(.system(size: 16, weight: .semibold, design: .rounded)) }
                    Text(def.desc).font(.caption).foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        StatPill(icon: "banknote.fill", text: "\(def.reward) P", color: AppPalette.gold)
                        if AchievementService.isClaimed(def.id) { StatPill(icon: "checkmark.circle.fill", text: "Получено", color: TwentyOneTab.dailies.theme.accent) } else if AchievementService.isUnlocked(def.id) { Button("Забрать награду") { _ = AchievementService.claim(def) }.buttonStyle(.borderedProminent).tint(TwentyOneTab.achievements.theme.accent).font(.caption) } else { StatPill(icon: "lock.fill", text: "Ещё не открыто", color: Color.white.opacity(0.55)) }
                    }
                }
                .padding(.vertical, 4)
                .listRowBackground(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(TwentyOneTab.achievements.theme.card.opacity(0.92)))
            }
        }
        .scrollContentBackground(.hidden)
        .background(TwentyOneTab.achievements.theme.gradient)
        .tint(TwentyOneTab.achievements.theme.accent)
        .navigationTitle("Достижения")
    }
}
