import SwiftUI
import RealmSwift

struct SeasonalShopView: View {
    @ObservedResults(User.self) var users
    @ObservedResults(AppSettings.self) var settingsList
    @EnvironmentObject var theme: AppTheme
    @State private var selectedLabel = ""
    var user: User? { users.first }
    var settings: AppSettings? { settingsList.first }
    private var labels: [String] { habiticaSeasonLabels }
    private var activeLabel: String { labels.contains(selectedLabel) ? selectedLabel : (labels.first ?? "") }
    private var items: [CatalogItem] { let ids = Set(habiticaSeasonalEntries.filter { $0.seasonLabel == activeLabel }.map { $0.catalogId }); return habiticaCatalog.filter { ids.contains($0.id) && !isPurchased($0) } }
    private var iconName: String { let m = Calendar.current.component(.month, from: Date()); switch m { case 12, 1, 2: return "seasonal_shop_winter"; case 3, 4, 5: return "seasonal_shop_spring"; case 6, 7, 8: return "seasonal_shop_summer"; default: return "seasonal_shop_fall" } }
    var body: some View {
        SwiftUI.List {
            Section { HStack(spacing: 12) { ItemArtwork(imageName: iconName, fallbackIcon: "leaf.fill", size: 56); VStack(alignment: .leading, spacing: 4) { Text("Сезонная лавка").font(.headline); Text("Сезонное снаряжение Habitica: \(habiticaSeasonalItems.count) предметов, \(labels.count) сезонов").font(.caption).foregroundStyle(.secondary) } } }
            Section { Picker("Сезон", selection: Binding(get: { activeLabel }, set: { selectedLabel = $0 })) { ForEach(labels, id: \.self) { Text($0).tag($0) } } }
            Section(activeLabel) { ForEach(items) { catalog in HStack(alignment: .top, spacing: 12) { ItemArtwork(imageName: catalog.imageName, fallbackIcon: "star.fill", size: 64); VStack(alignment: .leading, spacing: 7) { HStack(spacing: 7) { Text(catalog.name).font(.system(size: 16, weight: .semibold, design: .rounded)); RankBadge(rank: catalog.rank) }; if !catalog.desc.isEmpty { Text(catalog.desc).font(.caption).foregroundStyle(.secondary) }; HStack(spacing: 6) { StatPill(icon: "tag.fill", text: catalog.slot, color: TwentyOneTab.market.theme.accent); StatPill(icon: "chart.bar.fill", text: "\(catalog.statName) +\(catalog.statPoints)", color: TwentyOneTab.market.theme.accent) }; HStack(spacing: 6) { StatPill(icon: "banknote.fill", text: "\(catalog.pricePesetas) P", color: AppPalette.gold) }; Button("Купить") { buy(catalog) }.buttonStyle(TwentyPrimaryButtonStyle(color: TwentyOneTab.market.theme.accent)).disabled((user?.pesetas ?? 0) < catalog.pricePesetas) } }.padding(.vertical, 6) } }
        }.scrollContentBackground(.hidden).background(theme.background(for: 3))
    }
    func isPurchased(_ catalog: CatalogItem) -> Bool { guard let s = settings else { return false }; return s.marketPurchased.components(separatedBy: ",").contains(catalog.id) }
    func buy(_ catalog: CatalogItem) { guard let userId = user?.id else { return }; RealmStore.write { realm in guard let liveUser = realm.object(ofType: User.self, forPrimaryKey: userId), let s = RealmStore.settings(in: realm) else { return }; if liveUser.pesetas < catalog.pricePesetas { return }; let item = Item(); item.name = catalog.name; item.rank = catalog.rank; item.itemDescription = catalog.desc; item.slot = catalog.slot; item.costPesetas = catalog.pricePesetas; item.costXp = catalog.priceXp; item.statModifiers[catalog.statName] = catalog.statPoints; item.acquiredAt = Date(); liveUser.pesetas -= catalog.pricePesetas; liveUser.inventory.append(item); if s.marketPurchased.isEmpty { s.marketPurchased = catalog.id } else { s.marketPurchased += "," + catalog.id } }; HistoryService.log("purchase", "Сезонная лавка: " + catalog.name, pesetas: -catalog.pricePesetas) }
}
