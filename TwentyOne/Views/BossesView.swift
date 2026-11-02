import SwiftUI
import RealmSwift

struct BossesView: View {
    @ObservedResults(Boss.self) var bosses
    @ObservedResults(User.self) var users
    @ObservedResults(Daily.self) var dailies
    @ObservedResults(Event.self) var events
    @ObservedResults(AppSettings.self) var settingsList
    @State private var showVictory = false
    @State private var lastDamage = 0
    @State private var exportURL: URL?
    var user: User? { users.first }
    var campaignBosses: [Boss] { bosses.filter { $0.orderIndex != nil && !$0.departed }.sorted { ($0.orderIndex ?? 0) < ($1.orderIndex ?? 0) } }
    var freeBosses: [Boss] { bosses.filter { $0.orderIndex == nil && !$0.departed } }
    var body: some View {
        NavigationStack {
            SwiftUI.List {
                Section("Кампания") { ForEach(campaignBosses, id: \.id) { boss in bossRow(boss) } }
                Section("Свободные и ивентовые") { ForEach(freeBosses, id: \.id) { boss in bossRow(boss) } }
            }
            .navigationTitle("Боссы")
            .onAppear { ensureUser(); seedBosses(); processEventBosses() }
            .alert("Босс побеждён!", isPresented: $showVictory) { Button("OK", role: .cancel) {} }
        }
    }
    func bossRow(_ boss: Boss) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(boss.name + " [" + boss.rank + "]")
            if !boss.pixelArtAscii.isEmpty { Text(boss.pixelArtAscii).font(.caption).monospaced() }
            Text("HP: " + String(boss.hp) + " / " + String(boss.maxHp)).font(.caption).foregroundStyle(.secondary)
            ProgressView(value: Double(boss.hp), total: Double(max(boss.maxHp, 1)))
            if !boss.requiredAttributeName.isEmpty { Text("Нужно: " + boss.requiredAttributeName + " " + String(boss.requiredAttributeValue) + ", у вас " + String(attributeTotal(boss.requiredAttributeName))).font(.caption).foregroundStyle(.secondary) }
            if isHarming(boss) { Text("Босс вредит: -20 P в день и -10% к наградам дейликов").font(.caption).foregroundStyle(.red) }
            Text("Награда: " + String(boss.rewardsPesetas) + " P, " + String(boss.rewardsXp) + " XP").font(.caption).foregroundStyle(.secondary)
            Button("Экспорт .json21") { exportURL = Json21Service.exportBossFile(boss) }
            if let exportURL = exportURL { ShareLink(item: exportURL) { Text("Поделиться .json21") } }
            if boss.isDefeated { Text("Побеждён").foregroundStyle(.green) }
            else if !isUnlocked(boss) { Text("Закрыт: сначала победите предыдущего босса кампании").font(.caption).foregroundStyle(.secondary) }
            else if !meetsRequirement(boss) { Text("Непробиваем: не хватает атрибута").font(.caption).foregroundStyle(.orange) }
            else if isBlocked(boss) { Text("Непробиваем: сначала выполните связанный дейлик").font(.caption).foregroundStyle(.orange) }
            else { Button(canAttackToday(boss) ? "Атаковать (урон ~" + String(playerDamage(boss)) + ")" : "Попытка сегодня уже была") { attack(boss) }.disabled(!canAttackToday(boss)) }
        }
    }
    func ensureUser() { guard let realm = try? Realm() else { return }; if realm.objects(User.self).isEmpty { try? realm.write { realm.add(User()) } } }
    func isUnlocked(_ boss: Boss) -> Bool { guard let order = boss.orderIndex else { return true }; return bosses.filter { ($0.orderIndex ?? Int.max) < order }.allSatisfy { $0.isDefeated } }
    func attributeTotal(_ name: String) -> Int { guard let user = user else { return 0 }; return user.attributes.first { $0.name == name }?.total ?? 0 }
    func meetsRequirement(_ boss: Boss) -> Bool { if boss.requiredAttributeName.isEmpty || boss.requiredAttributeValue <= 0 { return true }; return attributeTotal(boss.requiredAttributeName) >= boss.requiredAttributeValue }
    func isHarming(_ boss: Boss) -> Bool { guard boss.isEventBoss, !boss.isDefeated, !boss.departed, let date = boss.eventDate else { return false }; return Calendar.current.startOfDay(for: date) < Calendar.current.startOfDay(for: Date()) }
    func longestStreak() -> Int { dailies.map { $0.streak }.max() ?? 0 }
    func wear(for rank: String) -> Int { switch rank { case "F": return 5; case "E": return 4; case "D": return 3; case "C": return 2; default: return 1 } }
    func playerDamage(_ boss: Boss) -> Int {
        guard let user = user else { return 10 }
        var base = 0
        if !boss.requiredAttributeName.isEmpty, let attr = user.attributes.first(where: { $0.name == boss.requiredAttributeName }) { base += attr.total; for item in user.equipped { for sub in attr.subAttributes { base += item.statModifiers[sub.name] ?? 0 } } } else { for attr in user.attributes { base += attr.total } }
        let bonus = min(0.5, Double(longestStreak()) * 0.02)
        return max(10, Int((Double(base) * (1 + bonus)).rounded(.down)))
    }
    func isBlocked(_ boss: Boss) -> Bool { let linked = events.filter { $0.linkedBossId == boss.id.stringValue || (boss.calendarEventLink != nil && $0.id.stringValue == boss.calendarEventLink) }; for event in linked { if let dailyId = event.linkedDailyId, let daily = dailies.first(where: { $0.id.stringValue == dailyId }), daily.lastCompletedDay == nil { return true } }; return false }
    func canAttackToday(_ boss: Boss) -> Bool { boss.lastAttemptDate.map { !Calendar.current.isDateInToday($0) } ?? true }
    func processEventBosses() {
        guard let realm = try? Realm(), let user = realm.objects(User.self).first, let s = realm.objects(AppSettings.self).first else { return }
        let cal = Calendar.current; let today = cal.startOfDay(for: Date())
        try? realm.write {
            for boss in realm.objects(Boss.self) where boss.isEventBoss && !boss.isDefeated && !boss.departed {
                guard let date = boss.eventDate else { continue }
                let days = cal.dateComponents([.day], from: cal.startOfDay(for: date), to: today).day ?? 0
                if days >= 30 { boss.departed = true; continue }
                if days > 0, let last = s.lastBossHarmDate, !cal.isDateInToday(last) { user.pesetas -= 20; s.lastBossHarmDate = Date() } else if days > 0 && s.lastBossHarmDate == nil { user.pesetas -= 20; s.lastBossHarmDate = Date() }
            }
        }
        _ = DebtService.evaluate()
    }
    func attack(_ boss: Boss) {
        guard let realm = try? Realm(), let user = user else { return }
        if boss.isDefeated || boss.departed || !isUnlocked(boss) || !meetsRequirement(boss) || isBlocked(boss) || !canAttackToday(boss) { return }
        let damage = playerDamage(boss); var victory = false
        try? realm.write {
            boss.lastAttemptDate = Date(); boss.hp = max(0, boss.hp - damage)
            for item in user.equipped where !item.isIndestructible { item.durability = max(0, item.durability - wear(for: item.rank)) }
            if boss.hp == 0 && !boss.isDefeated { boss.isDefeated = true; victory = true; user.pesetas += boss.rewardsPesetas; user.xp += boss.rewardsXp; while user.xp >= User.xpForNextLevel(user.level) { user.xp -= User.xpForNextLevel(user.level); user.level += 1 } } else { user.pesetas -= 50 }
        }
        lastDamage = damage; if victory { HistoryService.log("boss_defeated", "Побеждён босс: " + boss.name, xp: boss.rewardsXp, pesetas: boss.rewardsPesetas); showVictory = true } else { _ = DebtService.evaluate() }
    }
    func seedBosses() {
        guard let realm = try? Realm() else { return }; if !realm.objects(Boss.self).isEmpty { return }
        let b1 = Boss(); b1.name = "Хранитель утра"; b1.rank = "F"; b1.hp = 100; b1.maxHp = 100; b1.requiredAttributeName = "Интеллект"; b1.requiredAttributeValue = 10; b1.rewardsPesetas = 100; b1.rewardsXp = 20; b1.orderIndex = 1
        let b2 = Boss(); b2.name = "Страж прокрастинации"; b2.rank = "E"; b2.hp = 250; b2.maxHp = 250; b2.requiredAttributeName = "Дух"; b2.requiredAttributeValue = 20; b2.rewardsPesetas = 250; b2.rewardsXp = 50; b2.orderIndex = 2
        let b3 = Boss(); b3.name = "Сдача сессии"; b3.rank = "D"; b3.hp = 500; b3.maxHp = 500; b3.requiredAttributeName = "Интеллект"; b3.requiredAttributeValue = 50; b3.rewardsPesetas = 500; b3.rewardsXp = 100; b3.orderIndex = 3
        let b4 = Boss(); b4.name = "Тень лени"; b4.rank = "F"; b4.hp = 150; b4.maxHp = 150; b4.requiredAttributeName = "Ловкость"; b4.requiredAttributeValue = 10; b4.rewardsPesetas = 150; b4.rewardsXp = 30
        try? realm.write { realm.add([b1, b2, b3, b4]) }
    }
}
