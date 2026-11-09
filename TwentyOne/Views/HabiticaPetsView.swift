import SwiftUI

struct HabiticaPetsView: View {
    @EnvironmentObject var theme: AppTheme
    @State private var typeFilter = "all"
    @State private var query = ""
    private var filtered: [HabiticaPet] { habiticaPets.filter { (typeFilter == "all" || $0.type == typeFilter) && (query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) || $0.nameEn.localizedCaseInsensitiveContains(query)) } }
    var body: some View {
        SwiftUI.List {
            Section { Picker("Тип", selection: $typeFilter) { Text("Все").tag("all"); Text("Обычные").tag("drop"); Text("Премиум").tag("premium"); Text("Квестовые").tag("quest"); Text("Особые").tag("special") }.pickerStyle(.segmented); Text("Показано \(filtered.count) из \(habiticaPets.count). Спрайты stable_Pet в Assets.xcassets.").font(.caption).foregroundStyle(.secondary) }
            ForEach(filtered) { pet in HStack(spacing: 12) { ItemArtwork(imageName: pet.assetName, fallbackIcon: "pawprint.fill", size: 56); VStack(alignment: .leading, spacing: 4) { Text(pet.name).font(.system(size: 15, weight: .semibold, design: .rounded)); Text(pet.nameEn).font(.caption).foregroundStyle(.secondary); StatPill(icon: "pawprint.fill", text: typeName(pet.type), color: TwentyOneTab.profile.theme.accent) } }.padding(.vertical, 4) }
        }.scrollContentBackground(.hidden).background(theme.background(for: 0)).searchable(text: $query, prompt: "Поиск питомца").navigationTitle("Питомцы Habitica")
    }
    func typeName(_ type: String) -> String { switch type { case "drop": return "Обычный"; case "premium": return "Премиум"; case "quest": return "Квестовый"; case "special": return "Особый"; default: return type } }
}
