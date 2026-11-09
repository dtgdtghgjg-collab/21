import SwiftUI
import RealmSwift

// MARK: - 2. Categories
enum BagCategory: String, CaseIterable, Identifiable {
    case gear = "Экипировка"
    case consumables = "Расходники"
    case lootboxes = "Лутбоксы"
    case junk = "Ресурсы/Хлам"
    var id: String { rawValue }
}

func bagCategory(for item: Item) -> BagCategory {
    let name = item.name.lowercased()
    if item.uniqueFeature == "lootbox" || name.contains("лутбокс") || name.contains("сундук") { return .lootboxes }
    let words = ["зель", "эликсир", "свиток", "яйцо", "пирог", "суп", "хлеб", "сыр", "конфет", "печень"]
    if ["Зелье", "Еда", "Свиток", "Расходник"].contains(item.slot) || words.contains(where: { name.contains($0) }) { return .consumables }
    if item.statModifiers.count == 0 { return .junk }
    return .gear
}

func inventoryArtworkName(_ item: Item) -> String {
    if let c = (regularCatalog + blackCatalog + habiticaCatalog).first(where: { $0.name == item.name }) { return c.imageName }
    return ""
}

// MARK: - 4. Lootbox pool: exactly 100 items
func lootboxPool100() -> [CatalogItem] {
    let combined = regularCatalog + habiticaCatalog.filter { !["S", "SS", "SSS", "R"].contains($0.rank) }
    var pool: [CatalogItem] = []
    var i = 0
    while pool.count < 100 && !combined.isEmpty { pool.append(combined[i % combined.count]); i += 1 }
    return pool
}

struct InventoryStack: Identifiable {
    let item: Item
    let count: Int
    var id: String { item.id.stringValue }
}

func inventoryStacks(_ items: [Item], category: BagCategory) -> [InventoryStack] {
    let filtered = items.filter { bagCategory(for: $0) == category }
    if category == .gear || category == .lootboxes { return filtered.map { InventoryStack(item: $0, count: 1) } }
    var order: [String] = []
    var groups: [String: [Item]] = [:]
    for it in filtered { let k = it.name + "|" + it.rank; if groups[k] == nil { order.append(k) }; groups[k, default: []].append(it) }
    return order.compactMap { k in groups[k].map { InventoryStack(item: $0[0], count: $0.count) } }
}

// MARK: - 1. Grid card
struct InventoryCardView: View {
    let stack: InventoryStack
    let onTap: () -> Void
    var item: Item { stack.item }
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    Group {
                        if !item.imagePath.isEmpty, let ui = UIImage(contentsOfFile: item.imagePath) { Image(uiImage: ui).resizable().interpolation(.none).scaledToFit() } else { ItemArtwork(imageName: inventoryArtworkName(item), fallbackIcon: "star.fill", size: 52) }
                    }.frame(width: 56, height: 56)
                    if item.isEquipped { Image(systemName: "shield.fill").foregroundStyle(AppPalette.gold).shadow(color: AppPalette.gold, radius: 6) }
                }
                Text(item.name).font(.system(size: 11, weight: .semibold)).lineLimit(2).multilineTextAlignment(.center).foregroundStyle(.white)
                RankBadge(rank: item.rank)
            }
            .frame(maxWidth: .infinity, minHeight: 118)
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(TwentyOneTab.market.theme.card.opacity(0.92)))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(RankPalette.color(for: item.rank), lineWidth: item.rank == "R" ? 3 : 2))
            .shadow(color: item.isEquipped ? AppPalette.gold.opacity(0.55) : Color.clear, radius: item.isEquipped ? 10 : 0)
            .overlay(alignment: .bottomTrailing) { if stack.count > 1 { Text("×" + String(stack.count)).font(.system(size: 11, weight: .black, design: .rounded)).foregroundStyle(.white).padding(.horizontal, 6).padding(.vertical, 2).background(Capsule().fill(Color.black.opacity(0.65))) } }
        }.buttonStyle(.plain)
    }
}

// MARK: - 3. Item detail sheet
struct ItemDetailSheet: View {
    let item: Item
    let count: Int
    let sellValue: Int
    let onEquip: () -> Void
    let onSell: () -> Void
    let onUse: () -> Void
    let onOpenLootbox: () -> Void
    @Environment(\.dismiss) var dismiss
    var category: BagCategory { bagCategory(for: item) }
    var statsText: String { item.statModifiers.keys.sorted().map { key in key + " +" + String(item.statModifiers[key] ?? 0) }.joined(separator: ", ") }
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Group {
                    if !item.imagePath.isEmpty, let ui = UIImage(contentsOfFile: item.imagePath) { Image(uiImage: ui).resizable().interpolation(.none).scaledToFit() } else { ItemArtwork(imageName: inventoryArtworkName(item), fallbackIcon: "star.fill", size: 140) }
                }.frame(width: 150, height: 150)
                Text(item.name).font(.system(size: 22, weight: .bold, design: .rounded)).multilineTextAlignment(.center)
                HStack(spacing: 8) { RankBadge(rank: item.rank); StatPill(icon: "tag.fill", text: item.slot, color: TwentyOneTab.market.theme.accent); if count > 1 { StatPill(icon: "square.stack.3d.up.fill", text: "×" + String(count), color: AppPalette.gold) } }
                if !statsText.isEmpty { StatPill(icon: "chart.bar.fill", text: statsText, color: TwentyOneTab.market.theme.accent) }
                if !item.itemDescription.isEmpty { Text(item.itemDescription).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center) }
                if category == .gear { Text("Прочность: " + String(item.durability) + "/" + String(item.maxDurability)).font(.caption).foregroundStyle(.secondary) }
                if category == .lootboxes { Button("Открыть") { onOpenLootbox() }.buttonStyle(TwentyPrimaryButtonStyle(color: AppPalette.gold)) }
                else if category == .consumables { Button("Использовать") { onUse(); dismiss() }.buttonStyle(TwentyPrimaryButtonStyle(color: TwentyOneTab.dailies.theme.accent)) }
                else { Button(item.isEquipped ? "Снять" : "Экипировать") { onEquip(); dismiss() }.buttonStyle(TwentyPrimaryButtonStyle(color: TwentyOneTab.market.theme.accent)) }
                Button("Продать за " + String(sellValue) + " P") { onSell(); dismiss() }.buttonStyle(TwentySecondaryButtonStyle(color: AppPalette.gold))
            }.padding()
        }.background(TwentyOneTab.market.theme.background.ignoresSafeArea())
    }
}

// MARK: - 4. Lootbox opening animation
struct LootboxOpeningView: View {
    let onClaim: (CatalogItem) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var shaking = false
    @State private var flash = false
    @State private var revealed: CatalogItem?
    var body: some View {
        ZStack {
            TwentyOneTab.market.theme.background.ignoresSafeArea()
            VStack(spacing: 16) {
                if let r = revealed {
                    Text("Новый предмет!").font(.system(size: 26, weight: .black, design: .rounded)).foregroundStyle(AppPalette.gold)
                    ItemArtwork(imageName: r.imageName, fallbackIcon: "star.fill", size: 140)
                    Text(r.name).font(.system(size: 20, weight: .bold, design: .rounded)).multilineTextAlignment(.center)
                    HStack(spacing: 8) { RankBadge(rank: r.rank); StatPill(icon: "chart.bar.fill", text: r.statName + " +" + String(r.statPoints), color: TwentyOneTab.market.theme.accent) }
                    Button("Забрать") { onClaim(r); dismiss() }.buttonStyle(TwentyPrimaryButtonStyle(color: AppPalette.gold))
                } else {
                    Image(flash ? "lootbox_open" : "lootbox_chest").resizable().interpolation(.none).scaledToFit().frame(width: 170, height: 170).rotationEffect(.degrees(shaking ? 4 : 0)).animation(shaking ? .easeInOut(duration: 0.12).repeatForever(autoreverses: true) : .default, value: shaking)
                    Button("Открыть") { open() }.buttonStyle(TwentyPrimaryButtonStyle(color: AppPalette.gold)).disabled(shaking)
                }
            }.padding()
            if flash { Rectangle().fill(AppPalette.gold.opacity(0.85)).ignoresSafeArea() }
        }
    }
    func open() {
        shaking = true; Haptics.medium()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { shaking = false; flash = true; SoundService.coin() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { flash = false; revealed = lootboxPool100().randomElement(); Haptics.success() }
    }
}

// MARK: - 1+2. Bag grid with categories and search
struct InventoryGridView: View {
    let items: [Item]
    let sellValue: (Item) -> Int
    let onEquip: (Item) -> Void
    let onSell: (Item) -> Void
    let onUse: (Item) -> Void
    let onOpenLootbox: (Item) -> Void
    @State private var category: BagCategory = .gear
    @State private var search = ""
    @State private var selected: InventoryStack?
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Категория", selection: $category) { ForEach(BagCategory.allCases) { c in Text(c.rawValue).tag(c) } }.pickerStyle(.segmented)
            TextField("Поиск по сумке", text: $search).textFieldStyle(.roundedBorder)
            let visible = items.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) }
            let stacks = inventoryStacks(visible, category: category)
            Text("Предметов: " + String(visible.count)).font(.caption).foregroundStyle(.secondary)
            if stacks.isEmpty { Text("Здесь пусто").font(.caption).foregroundStyle(.secondary) } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) { ForEach(stacks) { st in InventoryCardView(stack: st) { selected = st } } }
            }
        }
        .sheet(item: $selected) { st in ItemDetailSheet(item: st.item, count: st.count, sellValue: sellValue(st.item), onEquip: { onEquip(st.item) }, onSell: { onSell(st.item) }, onUse: { onUse(st.item) }, onOpenLootbox: { onOpenLootbox(st.item) }) }
    }
}
