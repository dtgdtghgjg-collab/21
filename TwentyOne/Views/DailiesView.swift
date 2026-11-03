import SwiftUI
import RealmSwift

struct DailiesView: View {
    @ObservedResults(Daily.self) var dailies
    @ObservedResults(User.self) var users
    @ObservedResults(AppSettings.self) var settingsList
    @ObservedResults(Boss.self) var bosses
    @State private var newTitle = ""
    @State private var xpReward = 10
    @State private var pesetasReward = 50
    @State private var deadlineTime = "23:59"
    @State private var selectedSubId: String?
    @State private var selectedSkillId: String?
    @State private var showLevelUp = false
    @State private var showCrystallized = false
    var user: User? { users.first }
    var settings: AppSettings? { settingsList.first }
    var allSubs: [SubAttribute] { user?.attributes.flatMap { Array($0.subAttributes) } ?? [] }
    var randomDaily: Daily? { dailies.first { $0.isRandomDaily && ($0.randomDate.map { Calendar.current.isDateInToday($0) } ?? false) } }
    var regularDailies: [Daily] { dailies.filter { !$0.isRandomDaily } }
    var body: some View {
        NavigationStack {
            SwiftUI.List {
                Section("Сон и вода") {
                    if let settings = settings {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("Трекер сна", isOn: Binding(get: { settings.sleepEnabled }, set: { v in updateSettings { s in s.sleepEnabled = v } }))
                            if settings.sleepEnabled {
                                Text("Сон: \(String(format: "%.1f", settings.sleepHours)) ч / \(String(format: "%.1f", settings.sleepGoalHours)) ч")
                                ProgressView(value: settings.sleepHours, total: max(settings.sleepGoalHours, 0.5))
                                Slider(value: Binding(get: { settings.sleepHours }, set: { v in updateSettings { s in s.sleepHours = v } }), in: 0...24, step: 0.5)
                            }
                            Toggle("Трекер воды", isOn: Binding(get: { settings.waterEnabled }, set: { v in updateSettings { s in s.waterEnabled = v } }))
                            if settings.waterEnabled {
                                Text("Вода: \(String(format: "%.1f", settings.waterLiters)) л / \(String(format: "%.2f", settings.waterGoalLiters)) л")
                                ProgressView(value: settings.waterLiters, total: max(settings.waterGoalLiters, 0.25))
                                Slider(value: Binding(get: { settings.waterLiters }, set: { v in updateSettings { s in s.waterLiters = v } }), in: 0...5, step: 0.25)
                            }
                            Text("Множитель XP: x\(String(format: "%.1f", sleepWaterMultiplier()))")
                            Stepper("Цель сна: \(String(format: "%.1f", settings.sleepGoalHours)) ч", value: Binding(get: { settings.sleepGoalHours }, set: { v in updateSettings { s in s.sleepGoalHours = v } }), in: 4...12, step: 0.5)
                            Stepper("Цель воды: \(String(format: "%.2f", settings.waterGoalLiters)) л", value: Binding(get: { settings.waterGoalLiters }, set: { v in updateSettings { s in s.waterGoalLiters = v } }), in: 0.5...4, step: 0.25)
                            Button("Сбросить сон и воду") { updateSettings { s in s.sleepHours = 0; s.waterLiters = 0 } }
                        }
                        .padding(8)
                        .background(Color.blue.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                Section("Задание дня") {
                    if let daily = randomDaily {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(daily.title)
                            Text("Награда: \(daily.xpReward) XP, \(daily.pesetasReward) P").font(.caption).foregroundStyle(.secondary)
                            Button(completedToday(daily) ? "Выполнено сегодня" : "Выполнить") { completeDaily(daily) }.disabled(completedToday(daily))
                        }
                    } else { Button("Сгенерировать") { ensureRandomDaily() } }
                }
                Section("Создать дейлик") {
                    TextField("Название", text: $newTitle)
                    Text("XP: \(xpReward)")
                    Slider(value: Binding(get: { Double(xpReward) }, set: { xpReward = Int($0) }), in: 0...1000, step: 5)
                    Text("Песеты: \(pesetasReward) P")
                    Slider(value: Binding(get: { Double(pesetasReward) }, set: { pesetasReward = Int($0) }), in: 0...10000, step: 50)
                    TextField("Дедлайн (ЧЧ:ММ)", text: $deadlineTime)
                    Picker("Подхарактеристика", selection: $selectedSubId) {
                        Text("Без подхарактеристики").tag(nil as String?)
                        ForEach(allSubs, id: \.id) { sub in Text(sub.name).tag(sub.id.stringValue as String?) }
                    }
                    if let user = user {
                        Picker("Навык", selection: $selectedSkillId) {
                            Text("Без навыка").tag(nil as String?)
                            ForEach(user.skills, id: \.id) { skill in Text(skill.name).tag(skill.id.stringValue as String?) }
                        }
                    }
                    Button("Добавить дейлик") { addDaily() }.disabled(newTitle.isEmpty)
                }
                Section("Дейлики") {
                    ForEach(regularDailies, id: \.id) { daily in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(daily.title)
                            if let name = subName(daily) { Text("Подхарактеристика: \(name)").font(.caption).foregroundStyle(.secondary) }
                            Text("Награда: \(daily.xpReward) XP, \(daily.pesetasReward) P").font(.caption).foregroundStyle(.secondary)
                            Text("Дедлайн: \(daily.deadlineTime) · Стрик: \(daily.streak) дн. · Пропусков подряд: \(daily.consecutiveMisses)").font(.caption).foregroundStyle(.secondary)
                            Text("После дедлайна: награда /2, стрик не растёт, +1 к подхарактеристике сохраняется").font(.caption).foregroundStyle(.secondary)
                            Button(completedToday(daily) ? "Выполнено сегодня" : "Выполнить") { completeDaily(daily) }.disabled(completedToday(daily))
                            Button(focusButtonText(daily)) { toggleFocus(daily) }.disabled(completedToday(daily))
                        }
                    }
                    .onDelete { offsets in deleteDailies(at: offsets) }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Дейлики")
            .onAppear { ensureUser(); ensureSettings(); applyMissPenalties(); ensureRandomDaily() }
            .alert("Новый уровень!", isPresented: $showLevelUp) { Button("OK", role: .cancel) {} }
            .alert("Навык кристаллизовался в пассивный!", isPresented: $showCrystallized) { Button("OK", role: .cancel) {} }
        }
    }
    func subName(_ daily: Daily) -> String? { guard let id = daily.subAttributeId else { return nil }; return allSubs.first { $0.id.stringValue == id }?.name }
    func completedToday(_ daily: Daily) -> Bool { guard let last = daily.lastCompletedDay else { return false }; return Calendar.current.isDateInToday(last) }
    func isBeforeDeadline(_ daily: Daily) -> Bool {
        let parts = daily.deadlineTime.split(separator: ":")
        guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) else { return true }
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: Date())
        comps.hour = h; comps.minute = m
        guard let deadline = cal.date(from: comps) else { return true }
        return Date() <= deadline
    }
    func sleepWaterMultiplier() -> Double {
        guard let settings = settings else { return 1.0 }
        if !settings.sleepEnabled && !settings.waterEnabled { return 1.0 }
        var ok = true
        if settings.sleepEnabled && settings.sleepHours < settings.sleepGoalHours { ok = false }
        if settings.waterEnabled && settings.waterLiters < settings.waterGoalLiters { ok = false }
        return ok ? 1.1 : 0.9
    }
    func harmMultiplier() -> Double { bosses.contains { $0.isEventBoss && !$0.isDefeated && !$0.departed && ($0.eventDate.map { Calendar.current.startOfDay(for: $0) < Calendar.current.startOfDay(for: Date()) } ?? false) } ? 0.9 : 1.0 }
    func ensureUser() { guard let realm = try? Realm() else { return }; if realm.objects(User.self).isEmpty { try? realm.write { realm.add(User()) } } }
    func ensureSettings() {
        guard let realm = try? Realm() else { return }
        try? realm.write {
            if realm.objects(AppSettings.self).isEmpty { realm.add(AppSettings()) }
            if let s = realm.objects(AppSettings.self).first { if let d = s.trackerDate, !Calendar.current.isDateInToday(d) { s.sleepHours = 0; s.waterLiters = 0 }; s.trackerDate = Date() }
        }
    }
    func updateSettings(_ change: @escaping (AppSettings) -> Void) { RealmStore.write { realm in if let s = RealmStore.settings(in: realm) { change(s) } } }
    func applyMissPenalties() {
        guard let realm = try? Realm(), let user = realm.objects(User.self).first, let s = realm.objects(AppSettings.self).first else { return }
        if let d = s.lastDailyPenaltyDate, Calendar.current.isDateInToday(d) { return }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let yesterday = cal.date(byAdding: .day, value: -1, to: today) else { return }
        var totalToday = 0
        try? realm.write {
            for daily in realm.objects(Daily.self) where !daily.isRandomDaily {
                if let p = daily.lastPenaltyDate, cal.isDateInToday(p) { continue }
                let completedYesterday = daily.lastCompletedDay.map { cal.isDate($0, inSameDayAs: yesterday) } ?? false
                let completedToday = daily.lastCompletedDay.map { cal.isDateInToday($0) } ?? false
                if completedYesterday || completedToday { continue }
                if daily.lastCompletedDay == nil && daily.lastPenaltyDate == nil { continue }
                daily.consecutiveMisses += 1
                daily.streak = 0
                daily.lastPenaltyDate = Date()
                let penalty = min(10 * daily.consecutiveMisses, 50)
                let allowed = max(0, min(penalty, 100 - totalToday))
                totalToday += allowed
                user.pesetas -= allowed
            }
            s.lastDailyPenaltyDate = Date()
            s.dailyPenaltyTotal = totalToday
        }
        _ = DebtService.evaluate()
    }
    func ensureRandomDaily() {
        if randomDaily != nil { return }
        guard let realm = try? Realm(), let user = user else { return }
        let daily = Daily()
        if let sub = allSubs.randomElement() { daily.title = "Задание дня: тренировка — " + sub.name; daily.subAttributeId = sub.id.stringValue } else { daily.title = "Задание дня: 20 минут фокусной работы" }
        daily.xpReward = 25; daily.pesetasReward = 120; daily.deadlineTime = "23:59"; daily.isRandomDaily = true; daily.randomDate = Date()
        _ = user
        try? realm.write { realm.add(daily) }
    }
    func addDaily() {
        guard let realm = try? Realm() else { return }
        let daily = Daily(); daily.title = newTitle; daily.xpReward = xpReward; daily.pesetasReward = pesetasReward; daily.deadlineTime = deadlineTime; daily.subAttributeId = selectedSubId; daily.linkedSkillId = selectedSkillId
        try? realm.write { realm.add(daily) }
        newTitle = ""; xpReward = 10; pesetasReward = 50; deadlineTime = "23:59"; selectedSubId = nil; selectedSkillId = nil
    }
    func deleteDailies(at offsets: IndexSet) { let ids = offsets.map { regularDailies[$0].id }; RealmStore.write { realm in realm.delete(ids.compactMap { realm.object(ofType: Daily.self, forPrimaryKey: $0) }) } }
    func grantSubPoint(_ daily: Daily) {
        guard let id = daily.subAttributeId, let oid = try? ObjectId(string: id) else { return }
        RealmStore.write { realm in guard let sub = realm.object(ofType: SubAttribute.self, forPrimaryKey: oid) else { return }; if sub.value < sub.cap { sub.value += 1 } else { sub.overCapCounter += 1; if sub.overCapCounter >= 3 { sub.overCapCounter = 0; sub.value += 1 } } }
    }
    func focusButtonText(_ daily: Daily) -> String {
        guard let start = daily.focusStartedAt else { return "Фокус 25 мин" }
        let elapsed = Int(Date().timeIntervalSince(start))
        if elapsed >= 1500 { return "Завершить фокус и выполнить" }
        let remainingMinutes: Int = 25 - elapsed / 60
        return "Фокус: осталось \(remainingMinutes) мин"
    }
    func toggleFocus(_ daily: Daily) {
        let dailyId = daily.id
        guard let start = daily.focusStartedAt else { RealmStore.write { realm in realm.object(ofType: Daily.self, forPrimaryKey: dailyId)?.focusStartedAt = Date() }; return }
        if Date().timeIntervalSince(start) >= 1500 { RealmStore.write { realm in if let live = realm.object(ofType: Daily.self, forPrimaryKey: dailyId) { live.focusCompletedDay = Date(); live.focusStartedAt = nil } }; completeDaily(daily) }
    }
    func completeDaily(_ daily: Daily) {
        guard let user = user else { return }
        let dailyId = daily.id
        let userId = user.id
        let subIdString = daily.subAttributeId
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let onTime = isBeforeDeadline(daily)
        var newStreak = daily.streak
        if onTime {
            newStreak = 1
            if let last = daily.lastCompletedDay { let lastDay = calendar.startOfDay(for: last); if lastDay == today { return }; if let yesterday = calendar.date(byAdding: .day, value: -1, to: today), lastDay == yesterday { newStreak = daily.streak + 1 } }
        } else if daily.lastCompletedDay.map({ calendar.isDateInToday($0) }) ?? false { return }
        let streakMultiplier = daily.isRandomDaily ? 1.0 : (onTime ? min(daily.streakCap, 1.0 + 0.1 * Double(newStreak)) : 1.0)
        let lateFactor = onTime ? 1.0 : 0.5
        let totalMultiplier = streakMultiplier * sleepWaterMultiplier() * harmMultiplier() * lateFactor
        var perkXpMultiplier = 1.0; var perkPesetasMultiplier = 1.0
        let name = subName(daily) ?? ""
        for item in user.equipped { for perk in item.perks where perk.trigger == "on_task_complete" { if perk.effect == "double_xp" { perkXpMultiplier *= 2 }; if perk.effect == "double_pesetas" { perkPesetasMultiplier *= 2 }; if perk.effect == "double_xp_if_category_logic" && perk.params == name { perkXpMultiplier *= 2 } } }
        let xpEarned = Int((Double(daily.xpReward) * totalMultiplier * perkXpMultiplier).rounded(.down))
        let pesetasEarned = Int((Double(daily.pesetasReward) * totalMultiplier * perkPesetasMultiplier).rounded(.down))
        var leveledUp = false; var crystallized = false
        RealmStore.write { realm in
            guard let liveDaily = realm.object(ofType: Daily.self, forPrimaryKey: dailyId), let liveUser = realm.object(ofType: User.self, forPrimaryKey: userId) else { return }
            liveDaily.streak = newStreak; liveDaily.lastCompletedDay = Date(); liveDaily.consecutiveMisses = 0
            liveUser.pesetas += pesetasEarned; liveUser.xp += xpEarned
            while liveUser.xp >= User.xpForNextLevel(liveUser.level) { liveUser.xp -= User.xpForNextLevel(liveUser.level); liveUser.level += 1; leveledUp = true }
            if let subIdString = subIdString, let oid = try? ObjectId(string: subIdString), let sub = realm.object(ofType: SubAttribute.self, forPrimaryKey: oid) { if sub.value < sub.cap { sub.value += 1 } else { sub.overCapCounter += 1; if sub.overCapCounter >= 3 { sub.overCapCounter = 0; sub.value += 1 } } }
            if let skillId = liveDaily.linkedSkillId, let skill = liveUser.skills.first(where: { $0.id.stringValue == skillId }) {
                if !skill.linkedDailyIds.contains(liveDaily.id.stringValue) { skill.linkedDailyIds.append(liveDaily.id.stringValue) }
                if onTime && !skill.isPassive { skill.progress = min(100, newStreak * 100 / max(liveDaily.crystallizationDays, 1)); if newStreak >= liveDaily.crystallizationDays { skill.isPassive = true; skill.progress = 100; crystallized = true } }
            }
        }
        HistoryService.log("daily_complete", "Выполнен дейлик: " + daily.title, xp: xpEarned, pesetas: pesetasEarned)
        if leveledUp { showLevelUp = true }
        if crystallized { showCrystallized = true }
    }
}
