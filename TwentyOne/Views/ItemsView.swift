import SwiftUI
import RealmSwift
import UniformTypeIdentifiers

let rankMultipliers: [String: Double] = ["F": 1, "E": 2, "D": 4, "C": 8, "B": 16, "A": 32, "S": 64, "SS": 128, "SSS": 256, "R": 512]

let rankBasePrices: [String: Int] = ["F": 4000, "E": 8000, "D": 15000, "C": 30000, "B": 60000, "A": 120000, "S": 250000, "SS": 500000, "SSS": 900000, "R": 2000000]

struct CatalogItem: Identifiable {
    let id: String
    let name: String
    let rank: String
    let desc: String
    let slot: String
    let statName: String
    let statPoints: Int
    var isPinpoon: Bool = false
    var uniqueFeature: String = ""
    var priceMultiplier: Double = 1.0
    var pricePesetas: Int { Int(Double(rankBasePrices[rank] ?? 4000) * (1.0 + 0.2 * Double(max(statPoints - 1, 0))) * (isPinpoon ? 4.0 : 1.0) * priceMultiplier) }
    var priceXp: Int { pricePesetas / 5 }
}

let regularCatalog: [CatalogItem] = [
    CatalogItem(id: "reg-notebook", name: "Потрепанный блокнот", rank: "F", desc: "Для заметок — как у Лайта из «Тетради смерти»", slot: "Аксессуар", statName: "Интеллект", statPoints: 1),
    CatalogItem(id: "reg-mug", name: "Кружка кофе", rank: "F", desc: "Бодрит", slot: "Аксессуар", statName: "Скорость мышления", statPoints: 1),
    CatalogItem(id: "reg-textbook", name: "Учебник логики", rank: "E", desc: "Основы логики", slot: "Инструмент", statName: "Логика", statPoints: 2),
    CatalogItem(id: "reg-sneakers", name: "Спортивные кроссовки", rank: "E", desc: "Быстрые ноги", slot: "Тело", statName: "Скорость мышления", statPoints: 1),
    CatalogItem(id: "reg-helmet", name: "Шлем сосредоточения", rank: "D", desc: "Фокус", slot: "Голова", statName: "Интеллект", statPoints: 2),
    CatalogItem(id: "reg-cloak", name: "Плащ отличника", rank: "D", desc: "Для отличников", slot: "Тело", statName: "Критическое мышление", statPoints: 2),
    CatalogItem(id: "reg-sword", name: "Меч дедлайнов", rank: "C", desc: "Режет сроки", slot: "Инструмент", statName: "Логика", statPoints: 3),
    CatalogItem(id: "reg-glasses", name: "Очки аналитика", rank: "C", desc: "Видят суть", slot: "Голова", statName: "Критическое мышление", statPoints: 3)
]

let blackCatalog: [CatalogItem] = [
    CatalogItem(id: "black-ring", name: "Кольцо гения", rank: "B", desc: "Редкое кольцо", slot: "Аксессуар", statName: "Интеллект", statPoints: 2),
    CatalogItem(id: "black-armor", name: "Броня сессии", rank: "B", desc: "Выдержит сессию", slot: "Тело", statName: "Логика", statPoints: 2),
    CatalogItem(id: "black-crown", name: "Корона знаний", rank: "A", desc: "Корона", slot: "Голова", statName: "Интеллект", statPoints: 3),
    CatalogItem(id: "black-blade", name: "Клинок мудрости", rank: "S", desc: "Очень редкий", slot: "Инструмент", statName: "Логика", statPoints: 4),
    CatalogItem(id: "black-orb", name: "Сфера провидца", rank: "SS", desc: "Почти легенда", slot: "Аксессуар", statName: "Критическое мышление", statPoints: 5),
    CatalogItem(id: "black-relic", name: "Реликвия 21", rank: "R", desc: "Легендарная", slot: "Голова", statName: "Интеллект", statPoints: 8),
    CatalogItem(id: "black-insurance", name: "Страховка от смерти", rank: "R", desc: "Уникальная фича death_insurance: сгорает и отменяет один вайп", slot: "Аксессуар", statName: "Интуиция", statPoints: 1),
    CatalogItem(id: "unique-death-note", name: "Тетрадь смерти", rank: "S", desc: "Как у Лайта из «Тетради смерти»: фича boss_damage_boost", slot: "Аксессуар", statName: "Критическое мышление", statPoints: 4, uniqueFeature: "boss_damage_boost"),
    CatalogItem(id: "unique-time-turner", name: "Маховик времени", rank: "A", desc: "Как у Гермионы: фича no_penalty_once_per_week", slot: "Аксессуар", statName: "Память", statPoints: 3, uniqueFeature: "no_penalty_once_per_week")
]

struct ItemsView: View {
    @ObservedResults(User.self) var users
    @ObservedResults(AppSettings.self) var settingsList
    @State private var selectedTab = 0
    @State private var showImporter = false
    @State private var importMessage: String?
    @State private var exportURL: URL?
    var user: User? { users.first }
    var settings: AppSettings? { settingsList.first }
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Раздел", selection: $selectedTab) {
                    Text("Мои").tag(0)
                    Text("Рынок").tag(1)
                    Text("Черный рынок").tag(2)
                    Text("Создать").tag(3)
                }.pickerStyle(.segmented).padding(.horizontal)
                if selectedTab == 0 { inventoryView }
                else if selectedTab == 1 { marketList(isBlack: false) }
                else if selectedTab == 3 { CustomItemView() }
                else { blackMarketView }
            }
            .navigationTitle("Предметы")
            .onAppear { ensureUser(); ensureSettings(); ensureFirstItem(); ensureBlackMarketSchedule() }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [UTType(filenameExtension: "json21") ?? .json]) { result in if let url = try? result.get() { importMessage = Json21Service.importFile(url) } }
        }
    }
    var inventoryView: some View {
        SwiftUI.List {
            Section(".json21") {
                Button("Импортировать .json21") { showImporter = true }
                if let importMessage = importMessage { Text("Импортировано: " + importMessage) }
                if let exportURL = exportURL { ShareLink(item: exportURL) { Text("Поделиться экспортом") } }
            }
            Section("Лутбокс (1 раз в неделю)") {
                if lootboxAvailable() { Button("Открыть лутбокс") { openLootbox() } }
                else { Text("Уже открыт на этой неделе") }
            }
            Section("Экипировано") {
                if let user = user {
                    if user.equipped.isEmpty { Text("Ничего не экипировано").font(.caption).foregroundStyle(.secondary) }
                    ForEach(user.equipped, id: \.id) { item in Text(item.name + " (" + item.slot + ")") }
                }
            }
            Section("Мои предметы") {
                if let user = user {
                    ForEach(user.inventory, id: \.id) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name + " [" + item.rank + "]")
                            Text(item.slot + " - " + String(item.costPesetas) + " P - прочность " + String(item.durability) + "/" + String(item.maxDurability)).font(.caption).foregroundStyle(.secondary)
                            HStack {
                                Button(item.isEquipped ? "Снять" : "Экипировать") { toggleEquip(item) }
                                Button("Переработать (+" + String(recycleValue(item)) + " P)") { recycle(item) }
                                Button("Экспорт .json21") { exportURL = Json21Service.exportItemFile(item) }
                            }.font(.caption)
                        }
                    }
                }
            }
        }
    }
    func marketList(isBlack: Bool) -> some View {
        SwiftUI.List {
            ForEach(marketItems(isBlack: isBlack)) { catalog in
                VStack(alignment: .leading, spacing: 4) {
                    Text(catalog.name + " [" + catalog.rank + "]")
                    Text(catalog.slot + " - " + catalog.statName + " +" + String(catalog.statPoints)).font(.caption).foregroundStyle(.secondary)
                    Text(String(catalog.pricePesetas) + " P, " + String(catalog.priceXp) + " XP").font(.caption)
                    Button("Купить") { buy(catalog) }.disabled((user?.pesetas ?? 0) < catalog.pricePesetas)
                }
            }
        }
    }
    var blackMarketView: some View {
        Group {
            if isBlackOpen() {
                VStack(alignment: .leading) {
                    Text("Черный рынок открыт").font(.headline).padding(.horizontal)
                    marketList(isBlack: true)
                }
            } else {
                VStack(spacing: 8) {
                    Text("Черный рынок закрыт")
                    if let next = settings?.blackMarketNextDate { Text("Следующее появление: " + next.formatted(date: .abbreviated, time: .omitted)) }
                    else { Text("Расписание появится после первого запуска") }
                    Text("Появляется спорадически: раз в 2 недели - 2 месяца, открыт 3 дня").font(.caption).foregroundStyle(.secondary)
                }.padding()
            }
        }
    }
    func ensureUser() {
        guard let realm = try? Realm() else { return }
        if realm.objects(User.self).isEmpty { try? realm.write { realm.add(User()) } }
    }
    func ensureSettings() {
        guard let realm = try? Realm() else { return }
        try? realm.write {
            if realm.objects(AppSettings.self).isEmpty { realm.add(AppSettings()) }
            if let s = realm.objects(AppSettings.self).first {
                if let d = s.marketDate, !Calendar.current.isDateInToday(d) { s.marketPurchased = "" }
                s.marketDate = Date()
            }
        }
    }
    func ensureFirstItem() {
        guard let realm = try? Realm(), let user = realm.objects(User.self).first, let s = realm.objects(AppSettings.self).first else { return }
        if s.firstItemGiven { return }
        let item = Item()
        item.name = "Талисман новичка"
        item.rank = "F"
        item.itemDescription = "Декоративный талисман первого дня"
        item.slot = "Аксессуар"
        item.costPesetas = 0
        item.costXp = 0
        item.acquiredAt = Date()
        try? realm.write { user.inventory.append(item); s.firstItemGiven = true }
    }
    func ensureBlackMarketSchedule() {
        guard let realm = try? Realm(), let s = realm.objects(AppSettings.self).first else { return }
        let today = Calendar.current.startOfDay(for: Date())
        try? realm.write {
            if s.blackMarketNextDate == nil {
                s.blackMarketNextDate = Calendar.current.date(byAdding: .day, value: Int.random(in: 14...60), to: today)
            } else if let until = s.blackMarketVisibleUntil {
                if today > until {
                    s.blackMarketNextDate = Calendar.current.date(byAdding: .day, value: Int.random(in: 14...60), to: today)
                    s.blackMarketVisibleUntil = nil
                }
            } else if let next = s.blackMarketNextDate, s.blackMarketVisibleUntil == nil, today >= Calendar.current.startOfDay(for: next) {
                s.blackMarketVisibleUntil = Calendar.current.date(byAdding: .day, value: 2, to: Calendar.current.startOfDay(for: next))
            }
        }
    }
    func isBlackOpen() -> Bool {
        guard let next = settings?.blackMarketNextDate, let until = settings?.blackMarketVisibleUntil else { return false }
        let today = Date()
        return today >= next && today <= until
    }
    func isPurchased(_ catalog: CatalogItem) -> Bool {
        guard let s = settings else { return false }
        return s.marketPurchased.components(separatedBy: ",").contains(catalog.id)
    }
    func marketItems(isBlack: Bool) -> [CatalogItem] {
        let catalog = isBlack ? blackCatalog : regularCatalog
        let day = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        var result: [CatalogItem] = []
        for i in 0..<6 {
            let idx = (day * 7 + i * 5 + (isBlack ? 3 : 0)) % catalog.count
            var entry = catalog[idx]
            if (day * 31 + i * 17) % 20 == 0 { entry.isPinpoon = true }
            entry.priceMultiplier = 0.8 + Double((day * 37 + i * 53) % 221) / 100.0
            result.append(entry)
        }
        return result.filter { !isPurchased($0) }
    }
    func lootboxAvailable() -> Bool {
        guard let last = settings?.lootboxLastDate else { return true }
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: last), to: Calendar.current.startOfDay(for: Date())).day ?? 0
        return days >= 7
    }
    func rollRank(level: Int) -> String {
        let weights: [(String, Double)] = [("F", 97), ("E", 3 + Double(level) * 0.5), ("D", 0.4 + Double(level) * 0.1), ("C", 0.15), ("B", 0.07), ("A", 0.03), ("S", 0.01), ("SS", 0.005), ("SSS", 0.001), ("R", 0.0005)]
        let total = weights.reduce(0) { $0 + $1.1 }
        var r = Double.random(in: 0..<total)
        for w in weights {
            if r < w.1 { return w.0 }
            r -= w.1
        }
        return "F"
    }
    func openLootbox() {
        guard let realm = try? Realm(), let user = user, let s = realm.objects(AppSettings.self).first else { return }
        if !lootboxAvailable() { return }
        let rank = rollRank(level: user.level)
        let points: [String: Int] = ["F": 1, "E": 1, "D": 2, "C": 2, "B": 3, "A": 3, "S": 4, "SS": 5, "SSS": 6, "R": 8]
        let pts = points[rank] ?? 1
        let slot = ["Голова", "Тело", "Инструмент", "Аксессуар"].randomElement() ?? "Аксессуар"
        let statName = user.attributes.flatMap { Array($0.subAttributes) }.randomElement()?.name ?? "Логика"
        let price = Int(Double(rankBasePrices[rank] ?? 500) * (1.0 + 0.2 * Double(max(pts - 1, 0))))
        let item = Item()
        item.name = "Трофей из лутбокса (" + rank + ")"
        item.rank = rank
        item.itemDescription = "Выпал из еженедельного лутбокса"
        item.slot = slot
        item.costPesetas = price
        item.costXp = price / 5
        item.statModifiers[statName] = pts
        item.acquiredAt = Date()
        try? realm.write { user.inventory.append(item); s.lootboxLastDate = Date() }
    }
    func buy(_ catalog: CatalogItem) {
        guard let realm = try? Realm(), let user = user, let s = realm.objects(AppSettings.self).first else { return }
        if user.pesetas < catalog.pricePesetas { return }
        let item = Item()
        item.name = catalog.name
        item.rank = catalog.rank
        item.itemDescription = catalog.desc
        item.slot = catalog.slot
        item.costPesetas = catalog.pricePesetas
        item.costXp = catalog.priceXp
        item.statModifiers[catalog.statName] = catalog.statPoints
        item.isIndestructible = catalog.isPinpoon
        item.uniqueFeature = catalog.uniqueFeature
        if catalog.id == "black-insurance" { item.uniqueFeature = "death_insurance" }
        item.acquiredAt = Date()
        try? realm.write {
            user.pesetas -= catalog.pricePesetas
            user.inventory.append(item)
            if s.marketPurchased.isEmpty { s.marketPurchased = catalog.id } else { s.marketPurchased += "," + catalog.id }
        }
        HistoryService.log("purchase", "Куплен предмет: " + catalog.name, pesetas: -catalog.pricePesetas)
    }
    func toggleEquip(_ item: Item) {
        guard let realm = try? Realm(), let user = user else { return }
        try? realm.write {
            if item.isEquipped {
                item.isEquipped = false
                var idx: Int? = nil
                for (i, eq) in user.equipped.enumerated() { if eq.id == item.id { idx = i; break } }
                if let idx = idx { user.equipped.remove(at: idx) }
            } else {
                for other in Array(user.equipped) where other.slot == item.slot {
                    other.isEquipped = false
                    var idx: Int? = nil
                    for (i, eq) in user.equipped.enumerated() { if eq.id == other.id { idx = i; break } }
                    if let idx = idx { user.equipped.remove(at: idx) }
                }
                item.isEquipped = true
                user.equipped.append(item)
            }
        }
    }
    func recycleValue(_ item: Item) -> Int {
        let days = Calendar.current.dateComponents([.day], from: item.acquiredAt, to: Date()).day ?? 0
        let weeks = max(0, days / 7)
        let durabilityFactor = Double(item.durability) / Double(max(item.maxDurability, 1))
        let value = Double(item.costPesetas) * 0.5 * durabilityFactor * pow(0.9, Double(weeks))
        return Int(value.rounded(.down))
    }
    func recycle(_ item: Item) {
        guard let realm = try? Realm(), let user = user else { return }
        let value = recycleValue(item)
        try? realm.write {
            user.pesetas += value
            var eIdx: Int? = nil
            for (i, eq) in user.equipped.enumerated() { if eq.id == item.id { eIdx = i; break } }
            if let eIdx = eIdx { user.equipped.remove(at: eIdx) }
            var iIdx: Int? = nil
            for (i, inv) in user.inventory.enumerated() { if inv.id == item.id { iIdx = i; break } }
            if let iIdx = iIdx { user.inventory.remove(at: iIdx) }
            realm.delete(item)
        }
    }
}
