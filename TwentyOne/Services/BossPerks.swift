import Foundation

enum BossPerks {
    private static let perks: [String: (title: String, bonus: Double)] = [
        "Сила": ("Сокрушительный удар: +15% к урону", 0.15),
        "Ловкость": ("Серия ударов: +12% к урону", 0.12),
        "Интеллект": ("Слабое место: +12% к урону", 0.12),
        "Дух": ("Несгибаемость: +10% к урону", 0.10),
        "Социальные": ("Боевой клич: +8% к урону", 0.08),
        "Творчество": ("Импровизация: +10% к урону", 0.10)
    ]
    static func bonus(for user: User) -> Double {
        var result = 0.0
        for attr in user.attributes {
            if attr.total >= 30, let perk = perks[attr.name] { result += perk.bonus }
        }
        result += Double(user.skills.filter { $0.isPassive }.count) * 0.05
        return min(result, 0.50)
    }
    static func activeDescriptions(for user: User) -> [String] {
        var result: [String] = []
        for attr in user.attributes {
            if attr.total >= 30, let perk = perks[attr.name] { result.append(perk.title) }
        }
        let passive = user.skills.filter { $0.isPassive }.count
        if passive > 0 { result.append("Пассивные навыки: +\(passive * 5)% к урону") }
        return result
    }
}
