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
        let b5 = Boss(); b5.name = "Кузнец воли"; b5.rank = "C"; b5.hp = 800; b5.maxHp = 800; b5.requiredAttributeName = "Сила"; b5.requiredAttributeValue = 40; b5.rewardsPesetas = 800; b5.rewardsXp = 150; b5.orderIndex = 4
        let b6 = Boss(); b6.name = "Лабиринт мыслей"; b6.rank = "C"; b6.hp = 1200; b6.maxHp = 1200; b6.requiredAttributeName = "Интеллект"; b6.requiredAttributeValue = 70; b6.rewardsPesetas = 1200; b6.rewardsXp = 200; b6.orderIndex = 5
        let b7 = Boss(); b7.name = "Хор сомнений"; b7.rank = "B"; b7.hp = 2000; b7.maxHp = 2000; b7.requiredAttributeName = "Социальные"; b7.requiredAttributeValue = 60; b7.rewardsPesetas = 2000; b7.rewardsXp = 350; b7.orderIndex = 6
        let b8 = Boss(); b8.name = "Зеркало перфекционизма"; b8.rank = "B"; b8.hp = 3000; b8.maxHp = 3000; b8.requiredAttributeName = "Дух"; b8.requiredAttributeValue = 80; b8.rewardsPesetas = 3000; b8.rewardsXp = 500; b8.orderIndex = 7
        let b9 = Boss(); b9.name = "Буря дедлайнов"; b9.rank = "A"; b9.hp = 5000; b9.maxHp = 5000; b9.requiredAttributeName = "Ловкость"; b9.requiredAttributeValue = 70; b9.rewardsPesetas = 5000; b9.rewardsXp = 800; b9.orderIndex = 8
        let b10 = Boss(); b10.name = "Архитектор хаоса"; b10.rank = "S"; b10.hp = 8000; b10.maxHp = 8000; b10.requiredAttributeName = "Творчество"; b10.requiredAttributeValue = 80; b10.rewardsPesetas = 8000; b10.rewardsXp = 1200; b10.orderIndex = 9
        let b11 = Boss(); b11.name = "Повелитель 21"; b11.rank = "SS"; b11.hp = 15000; b11.maxHp = 15000; b11.requiredAttributeName = "Интеллект"; b11.requiredAttributeValue = 100; b11.rewardsPesetas = 15000; b11.rewardsXp = 2000; b11.orderIndex = 10
        let b12 = Boss(); b12.name = "Эхо прошлого"; b12.rank = "F"; b12.hp = 200; b12.maxHp = 200; b12.requiredAttributeName = "Творчество"; b12.requiredAttributeValue = 10; b12.rewardsPesetas = 200; b12.rewardsXp = 40
        let b13 = Boss(); b13.name = "Туман усталости"; b13.rank = "E"; b13.hp = 400; b13.maxHp = 400; b13.requiredAttributeName = "Сила"; b13.requiredAttributeValue = 20; b13.rewardsPesetas = 400; b13.rewardsXp = 80
        let b14 = Boss(); b14.name = "Шёпот соцсетей"; b14.rank = "D"; b14.hp = 700; b14.maxHp = 700; b14.requiredAttributeName = "Социальные"; b14.requiredAttributeValue = 30; b14.rewardsPesetas = 700; b14.rewardsXp = 140
        let b15 = Boss(); b15.name = "Голодный холодильник"; b15.rank = "C"; b15.hp = 1000; b15.maxHp = 1000; b15.requiredAttributeName = "Дух"; b15.requiredAttributeValue = 40; b15.rewardsPesetas = 1000; b15.rewardsXp = 200
        let b16 = Boss(); b16.name = "Король откладывания"; b16.rank = "B"; b16.hp = 1800; b16.maxHp = 1800; b16.requiredAttributeName = "Дух"; b16.requiredAttributeValue = 60; b16.rewardsPesetas = 1800; b16.rewardsXp = 300
        let b17 = Boss(); b17.name = "Титан рутины"; b17.rank = "A"; b17.hp = 3500; b17.maxHp = 3500; b17.requiredAttributeName = "Сила"; b17.requiredAttributeValue = 70; b17.rewardsPesetas = 3500; b17.rewardsXp = 600
        try? realm.write { realm.add([b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14, b15, b16, b17]) }
        let extraBosses: [(String, String, Int, String, Int)] = [("Саурон", "S", 5000, "Сила", 80), ("Волан-де-Морт", "S", 5500, "Интеллект", 80), ("Дарт Вейдер", "A", 4000, "Дух", 70), ("Танос", "SS", 8000, "Сила", 90), ("Джокер", "B", 2500, "Социальные", 60), ("Локи", "A", 4000, "Творчество", 70), ("Галактус", "SSS", 12000, "Интеллект", 90), ("Фриза", "S", 6000, "Сила", 80), ("Селл", "S", 6500, "Ловкость", 80), ("Мадара", "SS", 9000, "Дух", 90), ("Пейн", "A", 4500, "Интеллект", 70), ("Обито", "A", 4200, "Ловкость", 70), ("Кайдо", "SS", 9500, "Сила", 90), ("Биг Мам", "S", 7000, "Сила", 80), ("Чёрная Борода", "S", 6800, "Дух", 80), ("Акаину", "A", 4800, "Сила", 70), ("Музан", "S", 7200, "Ловкость", 80), ("Аказа", "B", 3000, "Ловкость", 60), ("Сукуна", "SS", 10000, "Дух", 90), ("Махито", "A", 4300, "Творчество", 70), ("Кенджаку", "A", 4400, "Интеллект", 70), ("Айзен", "SS", 8500, "Интеллект", 90), ("Яхве", "SSS", 11000, "Дух", 90), ("Гриммджоу", "B", 3200, "Сила", 60), ("Титан-колосс", "A", 5000, "Сила", 70), ("Звероподобный титан", "B", 2800, "Интеллект", 60), ("Бронированный титан", "A", 4600, "Сила", 70), ("Женская особь титана", "B", 3000, "Ловкость", 60), ("Дио Брандо", "S", 6000, "Дух", 80), ("Карс", "A", 4500, "Творчество", 70), ("Пуччи", "S", 6200, "Интеллект", 80), ("Кира Йошикаге", "B", 2600, "Социальные", 60), ("Валентайн", "A", 4700, "Социальные", 70), ("Гриффит", "SS", 9000, "Дух", 90), ("Фемто", "SS", 9200, "Творчество", 90), ("Бог-рука", "S", 5800, "Дух", 80), ("Мерэм", "SS", 9800, "Сила", 90), ("Хисока", "A", 4100, "Ловкость", 70), ("Хролло", "A", 4300, "Интеллект", 70), ("Неферпиту", "S", 5600, "Ловкость", 80), ("Ганнибал Лектер", "B", 2400, "Интеллект", 60), ("Фредди Крюгер", "B", 2700, "Творчество", 60), ("Джейсон Вурхис", "B", 2900, "Сила", 60), ("Пеннивайз", "A", 4400, "Творчество", 70), ("Самара", "B", 2300, "Дух", 60), ("Чаки", "C", 1800, "Ловкость", 50), ("Ксеноморф", "A", 4900, "Ловкость", 70), ("Хищник", "A", 4800, "Сила", 70), ("Терминатор T-800", "S", 6100, "Сила", 80), ("Скайнет", "SS", 8800, "Интеллект", 90), ("Агент Смит", "A", 4600, "Интеллект", 70), ("Беллатриса", "B", 3100, "Дух", 60), ("Долорес Амбридж", "C", 2000, "Социальные", 50), ("Грин-де-Вальд", "A", 4500, "Социальные", 70), ("Дементор", "B", 3300, "Дух", 60), ("Балрог", "S", 6400, "Сила", 80), ("Шелоб", "A", 4200, "Ловкость", 70), ("Назгул", "A", 4300, "Дух", 70), ("Саруман", "A", 4700, "Интеллект", 70), ("Голлум-тень", "C", 1900, "Ловкость", 50), ("Дракон Смауг", "SS", 9900, "Сила", 90), ("Некромант", "A", 4600, "Дух", 70), ("Король-чародей", "S", 5900, "Дух", 80), ("Моргот", "SSS", 13000, "Сила", 90), ("Унголиант", "S", 5700, "Творчество", 80), ("Ктулху", "SSS", 14000, "Дух", 90), ("Ньярлатхотеп", "SS", 8700, "Интеллект", 90), ("Азатот", "SSS", 15000, "Интеллект", 100), ("Йог-Сотот", "SS", 8600, "Интеллект", 90), ("Шуб-Ниггурат", "S", 5400, "Творчество", 80), ("Дагон", "A", 4100, "Сила", 70), ("Гидра", "A", 4400, "Социальные", 70), ("Красный Череп", "B", 2800, "Социальные", 60), ("Зимний Солдат", "A", 4500, "Ловкость", 70), ("Альтрон", "SS", 8400, "Интеллект", 90), ("Хела", "S", 6300, "Дух", 80), ("Суртур", "S", 6600, "Сила", 80), ("Дормамму", "SS", 9100, "Дух", 90), ("Эго", "S", 5800, "Творчество", 80), ("Канг Завоеватель", "SS", 9300, "Интеллект", 90), ("Дарксайд", "SS", 9600, "Сила", 90), ("Думсдей", "S", 6700, "Сила", 80), ("Брейньяк", "A", 4800, "Интеллект", 70), ("Лекс Лютор", "B", 2600, "Интеллект", 60), ("Магнето", "A", 4900, "Социальные", 70), ("Апокалипсис", "SS", 9700, "Сила", 90), ("Сет", "A", 4300, "Дух", 70), ("Арес", "S", 5500, "Сила", 80)]
        try? realm.write { for def in extraBosses { let b = Boss(); b.name = def.0; b.rank = def.1; b.hp = def.2; b.maxHp = def.2; b.requiredAttributeName = def.3; b.requiredAttributeValue = def.4; b.rewardsPesetas = def.2; b.rewardsXp = def.2 / 5; realm.add(b) } }
    }
}
