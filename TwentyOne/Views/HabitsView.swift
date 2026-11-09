import SwiftUI
import RealmSwift

struct HabitsView: View {
    @ObservedResults(Habit.self) var habits
    @State private var newTitle = ""
    @State private var habitType = "both"
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Как в Habitica: + за хорошее действие, − за плохое. Чем краснее привычка, тем больше награда за +; зелёная и синяя дают меньше. Счётчики +/− сбрасываются каждый день.")
                .font(.caption).foregroundStyle(.secondary)
            if habits.isEmpty { Text("Пока нет привычек — добавь первую ниже.").font(.caption).foregroundStyle(.secondary) }
            ForEach(habits, id: \.id) { habit in
                HStack(spacing: 10) {
                    if habit.habitType != "down" { Button { scoreUp(habit) } label: { Image(systemName: "plus").font(.system(size: 16, weight: .black)).foregroundStyle(.white).frame(width: 38, height: 38).background(Circle().fill(color(for: habit.value))) }.buttonStyle(.plain) }
                    VStack(alignment: .leading, spacing: 5) {
                        Text(habit.title).font(.system(size: 15, weight: .semibold, design: .rounded))
                        HStack(spacing: 6) { StatPill(icon: "chart.line.uptrend.xyaxis", text: valueText(habit), color: color(for: habit.value)); StatPill(icon: "calendar", text: "сегодня +\(habit.counterUp) / −\(habit.counterDown)", color: TwentyOneTab.dailies.theme.accent) }
                        Text("Всего: +\(habit.totalUp) / −\(habit.totalDown)").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if habit.habitType != "up" { Button { scoreDown(habit) } label: { Image(systemName: "minus").font(.system(size: 16, weight: .black)).foregroundStyle(.white).frame(width: 38, height: 38).background(Circle().fill(color(for: habit.value).opacity(0.75))) }.buttonStyle(.plain) }
                    Button { deleteHabit(habit) } label: { Image(systemName: "trash").foregroundStyle(.secondary) }.buttonStyle(.plain)
                }
                .padding(.vertical, 4)
            }
            Divider()
            TextField("Новая привычка", text: $newTitle)
            Picker("Тип", selection: $habitType) { Text("+ и −").tag("both"); Text("Только +").tag("up"); Text("Только −").tag("down") }.pickerStyle(.segmented)
            Button("Добавить привычку") { addHabit() }.buttonStyle(TwentyPrimaryButtonStyle(color: TwentyOneTab.dailies.theme.accent)).disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .onAppear { resetCountersIfNeeded() }
    }
    func valueText(_ habit: Habit) -> String { String(format: "%.1f", habit.value) }
    func color(for value: Double) -> Color { if value <= -20 { return Color(red: 0.80, green: 0.15, blue: 0.15) }; if value <= -10 { return Color(red: 0.95, green: 0.35, blue: 0.25) }; if value < 0 { return Color(red: 0.98, green: 0.55, blue: 0.20) }; if value < 10 { return Color(red: 0.90, green: 0.75, blue: 0.20) }; if value < 20 { return Color(red: 0.35, green: 0.75, blue: 0.35) }; return Color(red: 0.30, green: 0.58, blue: 1.00) }
    func resetCounters(_ habit: Habit) { if habit.counterDate.map({ Calendar.current.isDateInToday($0) }) != true { habit.counterUp = 0; habit.counterDown = 0; habit.counterDate = Date() } }
    func resetCountersIfNeeded() { RealmStore.write { realm in for habit in realm.objects(Habit.self) { resetCounters(habit) } } }
    func addHabit() { let title = newTitle.trimmingCharacters(in: .whitespaces); let type = habitType; guard !title.isEmpty else { return }; RealmStore.write { realm in let habit = Habit(); habit.title = title; habit.habitType = type; habit.counterDate = Date(); realm.add(habit) }; newTitle = ""; habitType = "both"; Haptics.tap() }
    func deleteHabit(_ habit: Habit) { let habitId = habit.id; RealmStore.write { realm in if let live = realm.object(ofType: Habit.self, forPrimaryKey: habitId) { realm.delete(live) } } }
    func scoreUp(_ habit: Habit) { let habitId = habit.id; let title = habit.title; let current = habit.value; let factor = min(2.0, max(0.3, exp(-current * 0.03))); let xp = max(1, Int((8.0 * factor).rounded())); let pesetas = max(1, Int((14.0 * factor).rounded())); RealmStore.write { realm in guard let live = realm.object(ofType: Habit.self, forPrimaryKey: habitId), let user = RealmStore.user(in: realm) else { return }; resetCounters(live); live.value = min(50, live.value + 1); live.counterUp += 1; live.totalUp += 1; live.lastScoredDate = Date(); user.pesetas += pesetas; user.xp += xp; while user.xp >= User.xpForNextLevel(user.level) { user.xp -= User.xpForNextLevel(user.level); user.level += 1 } }; HistoryService.log("habit_up", "Привычка +: " + title, xp: xp, pesetas: pesetas); Haptics.success(); SoundService.coin() }
    func scoreDown(_ habit: Habit) { let habitId = habit.id; let title = habit.title; let current = habit.value; let factor = min(2.0, max(0.5, exp(current * 0.02))); let penalty = max(2, Int((10.0 * factor).rounded())); RealmStore.write { realm in guard let live = realm.object(ofType: Habit.self, forPrimaryKey: habitId), let user = RealmStore.user(in: realm) else { return }; resetCounters(live); live.value = max(-50, live.value - 1); live.counterDown += 1; live.totalDown += 1; live.lastScoredDate = Date(); user.pesetas -= penalty }; HistoryService.log("habit_down", "Привычка −: " + title, xp: 0, pesetas: -penalty); _ = DebtService.evaluate(); Haptics.error() }
}
