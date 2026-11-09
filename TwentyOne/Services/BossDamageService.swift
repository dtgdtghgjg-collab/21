import Foundation
import RealmSwift

enum BossDamageService {
    static let manualAttackCost = 50
    static let fantasyNames = ["Слизь", "Теневой Гоблин", "Лич", "Дракон", "Тёмный демон"]
    static let realNames = ["Преподаватель", "Налоговый инспектор", "Дедлайн", "Экзаменатор", "Начальник"]
    static let realTypes = ["teacher", "inspector", "deadline", "examiner", "chief"]
    static func playerPower(user: User) -> Int {
        let a = user.attributes.reduce(0) { $0 + $1.total }
        let e = user.equipped.reduce(0) { $0 + $1.statModifiers.values.reduce(0, +) }
        return a + e
    }
    static func damageForDaily(xpReward: Int, subTotal: Int, equippedPower: Int) -> Int {
        var d = 8 + xpReward / 5 + subTotal / 10 + equippedPower / 15
        if Int.random(in: 1...10) == 1 { d *= 2 }
        return max(1, d)
    }
    static func currentBoss(in realm: Realm) -> Boss? {
        realm.objects(Boss.self).filter { !$0.isDefeated && !$0.departed }.sorted { ($0.orderIndex ?? Int.max) < ($1.orderIndex ?? Int.max) }.first
    }
    static func applyDailyDamage(xpReward: Int, subAttributeId: String?) -> (damage: Int, victory: Bool, bossName: String) {
        var damage = 0
        var victory = false
        var bossName = ""
        var rewardXp = 0
        var rewardPesetas = 0
        RealmStore.write { realm in
            guard let user = RealmStore.user(in: realm), let boss = currentBoss(in: realm) else { return }
            let subTotal: Int = {
                guard let id = subAttributeId, let oid = try? ObjectId(string: id), let sub = realm.object(ofType: SubAttribute.self, forPrimaryKey: oid) else { return 0 }
                return sub.value
            }()
            let equippedPower = user.equipped.reduce(0) { $0 + $1.statModifiers.values.reduce(0, +) }
            let d = damageForDaily(xpReward: xpReward, subTotal: subTotal, equippedPower: equippedPower)
            boss.hp = max(0, boss.hp - d)
            damage = d
            bossName = boss.name
            if boss.hp == 0 {
                victory = true
                rewardXp = boss.rewardsXp
                rewardPesetas = boss.rewardsPesetas
                boss.isDefeated = true
                user.pesetas += boss.rewardsPesetas
                user.xp += boss.rewardsXp
                while user.xp >= User.xpForNextLevel(user.level) { user.xp -= User.xpForNextLevel(user.level); user.level += 1 }
                spawnNextBoss(realm: realm, user: user)
            }
        }
        if damage > 0 { HistoryService.log("boss_damage", "Урон боссу " + bossName + ": -" + String(damage), xp: 0, pesetas: 0) }
        if victory { HistoryService.log("boss_defeated", "Побеждён босс: " + bossName, xp: rewardXp, pesetas: rewardPesetas) }
        return (damage, victory, bossName)
    }
    static func manualAttack() -> (damage: Int, victory: Bool) {
        var damage = 0
        RealmStore.write { realm in
            guard let user = RealmStore.user(in: realm), let boss = currentBoss(in: realm), user.pesetas >= manualAttackCost, boss.hp > 1 else { return }
            let d = min(Int.random(in: 1...3), boss.hp - 1)
            user.pesetas -= manualAttackCost
            boss.hp -= d
            damage = d
        }
        if damage > 0 { HistoryService.log("boss_damage", "Ручная атака: -" + String(damage), xp: 0, pesetas: -manualAttackCost) }
        return (damage, false)
    }
    static func spawnNextBoss(realm: Realm, user: User) {
        let defeated = realm.objects(Boss.self).filter { $0.isDefeated }.count
        let isReal = defeated % 2 == 1
        let power = playerPower(user: user)
        let hp = max(10, power) * 5 + user.level * 50
        let boss = Boss()
        boss.name = isReal ? realNames[defeated % realNames.count] : fantasyNames[defeated % fantasyNames.count]
        boss.category = isReal ? "seasonal_real" : "dark_fantasy"
        let spawnIndex = defeated / 2
        boss.spriteName = isReal ? "boss_real_" + realTypes[spawnIndex % realTypes.count] + "_" + String(format: "%02d", (spawnIndex / realTypes.count % 10) + 1) : String(format: "boss_fantasy_%02d", (spawnIndex % 50) + 1)
        boss.rank = user.level >= 10 ? "A" : (user.level >= 5 ? "C" : "F")
        boss.hp = hp
        boss.maxHp = hp
        let strongest = user.attributes.max { $0.total < $1.total }
        boss.requiredAttributeName = strongest?.name ?? ""
        boss.requiredAttributeValue = max(0, (strongest?.total ?? 0) / 2)
        boss.rewardsPesetas = hp / 2
        boss.rewardsXp = hp / 10
        boss.orderIndex = defeated + 1
        realm.add(boss)
    }
}
