import Foundation
import RealmSwift

struct Json21Perk: Codable { var trigger: String; var effect: String; var params: String? }
struct Json21Rewards: Codable { var pesetas: Int?; var xp: Int? }
struct Json21Document: Codable {
    var entity_type: String
    var name: String
    var rank: String?
    var description: String?
    var image_base64: String?
    var pixel_art_ascii: String?
    var slot: String?
    var durability: Int?
    var stat_modifiers: [String: Int]?
    var perks: [Json21Perk]?
    var rewards: Json21Rewards?
    var cost_pesetas: Int?
    var cost_xp: Int?
    var hp: Int?
    var required_attributes: [String]?
    var order_index: Int?
    var calendar_event_link: String?
}

enum Json21Service {
    static func importFile(_ url: URL) -> String? {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return importData(data)
    }
    static func importData(_ data: Data) -> String? {
        guard let doc = try? JSONDecoder().decode(Json21Document.self, from: data), let realm = try? Realm() else { return nil }
        if doc.entity_type == "item" {
            guard let user = realm.objects(User.self).first else { return nil }
            let item = Item()
            item.name = doc.name
            item.rank = doc.rank ?? "F"
            item.itemDescription = doc.description ?? ""
            item.slot = doc.slot ?? "Аксессуар"
            item.durability = doc.durability ?? 100
            item.maxDurability = doc.durability ?? 100
            let points = doc.stat_modifiers?.values.reduce(0, +) ?? 1
            let mult = rankMultipliers[doc.rank ?? "F"] ?? 1
            item.costPesetas = doc.cost_pesetas ?? Int(100 * Double(max(points, 1)) * mult)
            item.costXp = doc.cost_xp ?? (item.costPesetas / 5)
            if let mods = doc.stat_modifiers { for (key, value) in mods { item.statModifiers[key] = value } }
            if let perks = doc.perks { for p in perks { let perk = Perk(); perk.trigger = p.trigger; perk.effect = p.effect; perk.params = p.params ?? ""; item.perks.append(perk) } }
            if let b64 = doc.image_base64, let imageData = Data(base64Encoded: b64) {
                let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("import_" + UUID().uuidString + ".png")
                if let path = path, (try? imageData.write(to: path)) != nil { item.imagePath = path.path }
            }
            item.acquiredAt = Date()
            var result: String?
            try? realm.write { user.inventory.append(item); result = item.name }
            return result
        }
        if doc.entity_type == "boss" {
            let boss = Boss()
            boss.name = doc.name
            boss.rank = doc.rank ?? "F"
            boss.hp = doc.hp ?? 100
            boss.maxHp = doc.hp ?? 100
            boss.pixelArtAscii = doc.pixel_art_ascii ?? ""
            if let b64 = doc.image_base64, let imageData = Data(base64Encoded: b64) {
                let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("boss_" + UUID().uuidString + ".png")
                if let path = path, (try? imageData.write(to: path)) != nil { boss.imagePath = path.path }
            }
            boss.orderIndex = doc.order_index
            boss.calendarEventLink = doc.calendar_event_link
            boss.rewardsPesetas = doc.rewards?.pesetas ?? 0
            boss.rewardsXp = doc.rewards?.xp ?? 0
            if let attrs = doc.required_attributes { for attr in attrs { boss.requiredAttributes.append(attr) } }
            var result: String?
            try? realm.write {
                realm.add(boss)
                if let link = doc.calendar_event_link { for event in realm.objects(Event.self) where event.id.stringValue == link { event.linkedBossId = boss.id.stringValue } }
                result = boss.name
            }
            return result
        }
        return nil
    }
    static func exportItemFile(_ item: Item) -> URL? {
        var mods: [String: Int] = [:]
        for (key, value) in item.statModifiers { mods[key] = value }
        var imageB64: String? = nil
        if !item.imagePath.isEmpty, let data = try? Data(contentsOf: URL(fileURLWithPath: item.imagePath)) { imageB64 = data.base64EncodedString() }
        let doc = Json21Document(entity_type: "item", name: item.name, rank: item.rank, description: item.itemDescription, image_base64: imageB64, pixel_art_ascii: nil, slot: item.slot, durability: item.durability, stat_modifiers: mods, perks: item.perks.map { Json21Perk(trigger: $0.trigger, effect: $0.effect, params: $0.params) }, rewards: nil, cost_pesetas: item.costPesetas, cost_xp: item.costXp, hp: nil, required_attributes: nil, order_index: nil, calendar_event_link: nil)
        return writeFile(doc, fileName: item.name)
    }
    static func exportBossFile(_ boss: Boss) -> URL? {
        var bossImageB64: String? = nil
        if !boss.imagePath.isEmpty, let data = try? Data(contentsOf: URL(fileURLWithPath: boss.imagePath)) { bossImageB64 = data.base64EncodedString() }
        let doc = Json21Document(entity_type: "boss", name: boss.name, rank: boss.rank, description: nil, image_base64: bossImageB64, pixel_art_ascii: boss.pixelArtAscii, slot: nil, durability: nil, stat_modifiers: nil, perks: nil, rewards: Json21Rewards(pesetas: boss.rewardsPesetas, xp: boss.rewardsXp), cost_pesetas: nil, cost_xp: nil, hp: boss.maxHp, required_attributes: Array(boss.requiredAttributes), order_index: boss.orderIndex, calendar_event_link: boss.calendarEventLink)
        return writeFile(doc, fileName: boss.name)
    }
    static func writeFile(_ doc: Json21Document, fileName: String) -> URL? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(doc) else { return nil }
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("exports") else { return nil }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let safe = fileName.replacingOccurrences(of: "/", with: "_")
        let url = dir.appendingPathComponent(safe + ".json21")
        do { try data.write(to: url); return url } catch { return nil }
    }
}
