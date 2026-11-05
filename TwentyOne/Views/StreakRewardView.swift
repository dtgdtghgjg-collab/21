import SwiftUI
import RealmSwift

struct StreakRewardView: View {
    @ObservedResults(Daily.self) var dailies
    var regular: [Daily] { dailies.filter { !$0.isRandomDaily } }
    var allDoneToday: Bool { !regular.isEmpty && regular.allSatisfy { daily in daily.lastCompletedDay.map { Calendar.current.isDateInToday($0) } ?? false } }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Text("Серия полных дней").font(.system(size: 16, weight: .semibold, design: .rounded)); Spacer(); StatPill(icon: "flame.fill", text: "\(StreakRewardService.currentStreak()) / 7", color: Color(red: 1.00, green: 0.55, blue: 0.20)) }
            GradientProgressBar(value: Double(StreakRewardService.currentStreak()), total: 7, color: AppPalette.gold, height: 8)
            if StreakRewardService.frameUnlocked { StatPill(icon: "checkmark.seal.fill", text: "Золотая рамка аватара получена", color: AppPalette.gold) } else { Text("Выполняй все дейлики 7 дней подряд — получишь золотую рамку для аватара").font(.caption).foregroundStyle(.secondary) }
        }
        .onAppear { if allDoneToday { StreakRewardService.record(day: Date()) } }
    }
}
