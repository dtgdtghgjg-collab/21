import SwiftUI
import RealmSwift
import PhotosUI

struct CustomItemView: View {
    @ObservedResults(User.self) var users
    @State private var name = ""
    @State private var desc = ""
    @State private var rank = "F"
    @State private var slot = "Аксессуар"
    @State private var statName = "Логика"
    @State private var statPoints = 1
    @State private var perkEffect = "double_xp_if_category_logic"
    @State private var perkParam = "Логика"
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var created = false
    var user: User? { users.first }
    var perkPrice: Int {
        switch perkEffect {
        case "double_xp": return 5000
        case "double_pesetas": return 5000
        default: return 3000
        }
    }
    var pricePesetas: Int {
        let base: Double = Double(rankBasePrices[rank] ?? 500)
        let factor: Double = 1.0 + 0.2 * Double(max(statPoints - 1, 0))
        return Int(base * factor) + perkPrice
    }
    var priceXp: Int { 0 }
    var canAfford: Bool { (user?.pesetas ?? 0) >= pricePesetas }
    var body: some View {
        Form {
            Section("Предмет") {
                TextField("Название", text: $name)
                TextField("Описание", text: $desc)
                Picker("Ранг", selection: $rank) {
                    Text("F").tag("F")
                    Text("E").tag("E")
                    Text("D").tag("D")
                    Text("C").tag("C")
                    Text("B").tag("B")
                    Text("A").tag("A")
                    Text("S").tag("S")
                    Text("SS").tag("SS")
                    Text("SSS").tag("SSS")
                    Text("R").tag("R")
                }
                Picker("Слот", selection: $slot) {
                    Text("Голова").tag("Голова")
                    Text("Тело").tag("Тело")
                    Text("Инструмент").tag("Инструмент")
                    Text("Аксессуар").tag("Аксессуар")
                }
                TextField("Характеристика", text: $statName)
                Stepper("Очки статов: \(statPoints)", value: $statPoints, in: 1...10)
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Text(imageData == nil ? "Выбрать PNG" : "PNG выбран")
                }
            }
            Section("Перк") {
                Text("Триггер: on_task_complete").font(.caption).foregroundStyle(.secondary)
                Picker("Эффект", selection: $perkEffect) {
                    Text("double_xp").tag("double_xp")
                    Text("double_pesetas").tag("double_pesetas")
                    Text("double_xp_if_category_logic").tag("double_xp_if_category_logic")
                }
                TextField("Параметр (имя характеристики)", text: $perkParam)
                Text("Цена перка: \(perkPrice) P").font(.caption).foregroundStyle(.secondary)
            }
            Section("Цена") {
                Text("\(pricePesetas) P, \(priceXp) XP")
                Text("Баланс: \(user?.pesetas ?? 0) P, \(user?.xp ?? 0) XP").font(.caption).foregroundStyle(.secondary)
                Button("Создать предмет") { createItem() }.disabled(name.isEmpty || !canAfford)
                if created { Text("Предмет создан и добавлен в инвентарь").foregroundStyle(.green) }
            }
        }
        .onChange(of: selectedPhoto) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self) { imageData = data }
            }
        }
    }
    func createItem() {
        guard let userId = user?.id, canAfford else { return }
        var path = ""
        if let data = imageData {
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("custom_" + UUID().uuidString + ".png")
            if let url = url, (try? data.write(to: url)) != nil { path = url.path }
        }
        let itemName = name; let itemDesc = desc; let itemRank = rank; let itemSlot = slot; let itemStatName = statName; let itemStatPoints = statPoints; let itemPrice = pricePesetas; let itemPriceXp = priceXp; let itemPerkEffect = perkEffect; let itemPerkParam = perkParam
        RealmStore.write { realm in
            guard let liveUser = realm.object(ofType: User.self, forPrimaryKey: userId), liveUser.pesetas >= itemPrice else { return }
            let item = Item()
            item.name = itemName
            item.rank = itemRank
            item.itemDescription = itemDesc
            item.slot = itemSlot
            item.imagePath = path
            item.costPesetas = itemPrice
            item.costXp = itemPriceXp
            item.statModifiers[itemStatName] = itemStatPoints
            item.acquiredAt = Date()
            let perk = Perk()
            perk.trigger = "on_task_complete"
            perk.effect = itemPerkEffect
            perk.params = itemPerkParam
            item.perks.append(perk)
            liveUser.pesetas -= itemPrice
            liveUser.inventory.append(item)
        }
        created = true
        name = ""
        desc = ""
    }
}
