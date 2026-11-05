import Foundation
import RealmSwift

struct AchievementDefinition { let id: String; let title: String; let desc: String; let reward: Int }

let achievementDefinitions: [AchievementDefinition] = [
    AchievementDefinition(id: "level5", title: "Уровень 5", desc: "Достичь 5 уровня", reward: 1000),
    AchievementDefinition(id: "level10", title: "Уровень 10", desc: "Достичь 10 уровня", reward: 5000),
    AchievementDefinition(id: "sub10", title: "Подхарактеристика 10", desc: "Любая подхарактеристика 10", reward: 500),
    AchievementDefinition(id: "sub20", title: "Подхарактеристика 20", desc: "Любая подхарактеристика 20", reward: 2000),
    AchievementDefinition(id: "streak7", title: "Стрик 7 дней", desc: "Стрик дейлика 7 дней", reward: 1000),
    AchievementDefinition(id: "streak30", title: "Стрик 30 дней", desc: "Стрик дейлика 30 дней", reward: 5000),
    AchievementDefinition(id: "firstBoss", title: "Первый босс", desc: "Победить первого босса", reward: 2000),
    AchievementDefinition(id: "threeBosses", title: "Три босса", desc: "Победить трёх боссов", reward: 5000),
    AchievementDefinition(id: "level20", title: "Уровень 20", desc: "Достичь 20 уровня", reward: 15000),
    AchievementDefinition(id: "level30", title: "Уровень 30", desc: "Достичь 30 уровня", reward: 30000),
    AchievementDefinition(id: "attr50", title: "Атрибут 50", desc: "Любой атрибут 50", reward: 2000),
    AchievementDefinition(id: "attr100", title: "Атрибут 100", desc: "Любой атрибут 100", reward: 10000),
    AchievementDefinition(id: "streak60", title: "Стрик 60 дней", desc: "Стрик дейлика 60 дней", reward: 10000),
    AchievementDefinition(id: "streak100", title: "Стрик 100 дней", desc: "Стрик дейлика 100 дней", reward: 20000),
    AchievementDefinition(id: "fiveBosses", title: "Пять боссов", desc: "Победить пять боссов", reward: 10000),
    AchievementDefinition(id: "tenBosses", title: "Десять боссов", desc: "Победить десять боссов", reward: 20000),
    AchievementDefinition(id: "collector10", title: "Коллекционер 10", desc: "Собрать 10 предметов", reward: 2000),
    AchievementDefinition(id: "collector30", title: "Коллекционер 30", desc: "Собрать 30 предметов", reward: 8000),
    AchievementDefinition(id: "rich100k", title: "100 000 песет", desc: "Накопить 100 000 песет", reward: 5000),
    AchievementDefinition(id: "rich1m", title: "Миллионер", desc: "Накопить 1 000 000 песет", reward: 20000),
    AchievementDefinition(id: "skillPassive", title: "Первый пассивный навык", desc: "Кристаллизовать навык в пассивный", reward: 3000),
    AchievementDefinition(id: "subTriple20", title: "Три максимума", desc: "Три подхарактеристики по 20", reward: 5000),
    AchievementDefinition(id: "lvl15", title: "Уровень 15", desc: "Достичь 15 уровня", reward: 8000),
    AchievementDefinition(id: "lvl25", title: "Уровень 25", desc: "Достичь 25 уровня", reward: 12000),
    AchievementDefinition(id: "lvl35", title: "Уровень 35", desc: "Достичь 35 уровня", reward: 20000),
    AchievementDefinition(id: "lvl40", title: "Уровень 40", desc: "Достичь 40 уровня", reward: 25000),
    AchievementDefinition(id: "lvl45", title: "Уровень 45", desc: "Достичь 45 уровня", reward: 30000),
    AchievementDefinition(id: "lvl50", title: "Уровень 50", desc: "Достичь 50 уровня", reward: 40000),
    AchievementDefinition(id: "lvl55", title: "Уровень 55", desc: "Достичь 55 уровня", reward: 45000),
    AchievementDefinition(id: "lvl60", title: "Уровень 60", desc: "Достичь 60 уровня", reward: 50000),
    AchievementDefinition(id: "lvl65", title: "Уровень 65", desc: "Достичь 65 уровня", reward: 55000),
    AchievementDefinition(id: "lvl70", title: "Уровень 70", desc: "Достичь 70 уровня", reward: 60000),
    AchievementDefinition(id: "lvl75", title: "Уровень 75", desc: "Достичь 75 уровня", reward: 70000),
    AchievementDefinition(id: "lvl80", title: "Уровень 80", desc: "Достичь 80 уровня", reward: 80000),
    AchievementDefinition(id: "lvl85", title: "Уровень 85", desc: "Достичь 85 уровня", reward: 90000),
    AchievementDefinition(id: "lvl90", title: "Уровень 90", desc: "Достичь 90 уровня", reward: 100000),
    AchievementDefinition(id: "lvl95", title: "Уровень 95", desc: "Достичь 95 уровня", reward: 120000),
    AchievementDefinition(id: "lvl100", title: "Уровень 100", desc: "Достичь 100 уровня", reward: 200000),
    AchievementDefinition(id: "streak14", title: "Стрик 14 дней", desc: "Стрик дейлика 14 дней", reward: 1500),
    AchievementDefinition(id: "streak21", title: "Стрик 21 день", desc: "Стрик дейлика 21 день", reward: 2500),
    AchievementDefinition(id: "streak40", title: "Стрик 40 дней", desc: "Стрик дейлика 40 дней", reward: 6000),
    AchievementDefinition(id: "streak45", title: "Стрик 45 дней", desc: "Стрик дейлика 45 дней", reward: 7000),
    AchievementDefinition(id: "streak50", title: "Стрик 50 дней", desc: "Стрик дейлика 50 дней", reward: 8000),
    AchievementDefinition(id: "streak70", title: "Стрик 70 дней", desc: "Стрик дейлика 70 дней", reward: 12000),
    AchievementDefinition(id: "streak80", title: "Стрик 80 дней", desc: "Стрик дейлика 80 дней", reward: 14000),
    AchievementDefinition(id: "streak90", title: "Стрик 90 дней", desc: "Стрик дейлика 90 дней", reward: 16000),
    AchievementDefinition(id: "streak120", title: "Стрик 120 дней", desc: "Стрик дейлика 120 дней", reward: 25000),
    AchievementDefinition(id: "streak150", title: "Стрик 150 дней", desc: "Стрик дейлика 150 дней", reward: 30000),
    AchievementDefinition(id: "streak180", title: "Стрик 180 дней", desc: "Стрик дейлика 180 дней", reward: 35000),
    AchievementDefinition(id: "streak200", title: "Стрик 200 дней", desc: "Стрик дейлика 200 дней", reward: 40000),
    AchievementDefinition(id: "streak250", title: "Стрик 250 дней", desc: "Стрик дейлика 250 дней", reward: 50000),
    AchievementDefinition(id: "streak300", title: "Стрик 300 дней", desc: "Стрик дейлика 300 дней", reward: 60000),
    AchievementDefinition(id: "streak365", title: "Стрик 365 дней", desc: "Стрик дейлика 365 дней", reward: 100000),
    AchievementDefinition(id: "boss2", title: "Боссы 2", desc: "Победить 2 боссов", reward: 3000),
    AchievementDefinition(id: "boss4", title: "Боссы 4", desc: "Победить 4 боссов", reward: 6000),
    AchievementDefinition(id: "boss6", title: "Боссы 6", desc: "Победить 6 боссов", reward: 8000),
    AchievementDefinition(id: "boss8", title: "Боссы 8", desc: "Победить 8 боссов", reward: 12000),
    AchievementDefinition(id: "boss12", title: "Боссы 12", desc: "Победить 12 боссов", reward: 18000),
    AchievementDefinition(id: "boss15", title: "Боссы 15", desc: "Победить 15 боссов", reward: 25000),
    AchievementDefinition(id: "boss20", title: "Боссы 20", desc: "Победить 20 боссов", reward: 35000),
    AchievementDefinition(id: "boss25", title: "Боссы 25", desc: "Победить 25 боссов", reward: 45000),
    AchievementDefinition(id: "boss30", title: "Боссы 30", desc: "Победить 30 боссов", reward: 55000),
    AchievementDefinition(id: "boss40", title: "Боссы 40", desc: "Победить 40 боссов", reward: 70000),
    AchievementDefinition(id: "boss50", title: "Боссы 50", desc: "Победить 50 боссов", reward: 90000),
    AchievementDefinition(id: "boss60", title: "Боссы 60", desc: "Победить 60 боссов", reward: 110000),
    AchievementDefinition(id: "boss75", title: "Боссы 75", desc: "Победить 75 боссов", reward: 140000),
    AchievementDefinition(id: "boss90", title: "Боссы 90", desc: "Победить 90 боссов", reward: 170000),
    AchievementDefinition(id: "boss100", title: "Боссы 100", desc: "Победить 100 боссов", reward: 200000),
    AchievementDefinition(id: "coll5", title: "Коллекционер 5", desc: "Собрать 5 предметов", reward: 1000),
    AchievementDefinition(id: "coll15", title: "Коллекционер 15", desc: "Собрать 15 предметов", reward: 3000),
    AchievementDefinition(id: "coll20", title: "Коллекционер 20", desc: "Собрать 20 предметов", reward: 4000),
    AchievementDefinition(id: "coll25", title: "Коллекционер 25", desc: "Собрать 25 предметов", reward: 6000),
    AchievementDefinition(id: "coll40", title: "Коллекционер 40", desc: "Собрать 40 предметов", reward: 10000),
    AchievementDefinition(id: "coll50", title: "Коллекционер 50", desc: "Собрать 50 предметов", reward: 15000),
    AchievementDefinition(id: "coll60", title: "Коллекционер 60", desc: "Собрать 60 предметов", reward: 20000),
    AchievementDefinition(id: "coll75", title: "Коллекционер 75", desc: "Собрать 75 предметов", reward: 25000),
    AchievementDefinition(id: "coll100", title: "Коллекционер 100", desc: "Собрать 100 предметов", reward: 40000),
    AchievementDefinition(id: "coll125", title: "Коллекционер 125", desc: "Собрать 125 предметов", reward: 50000),
    AchievementDefinition(id: "coll150", title: "Коллекционер 150", desc: "Собрать 150 предметов", reward: 60000),
    AchievementDefinition(id: "coll200", title: "Коллекционер 200", desc: "Собрать 200 предметов", reward: 80000),
    AchievementDefinition(id: "pesetas10000", title: "Богатство 10k", desc: "Накопить 10000 песет", reward: 2000),
    AchievementDefinition(id: "pesetas50000", title: "Богатство 50k", desc: "Накопить 50000 песет", reward: 5000),
    AchievementDefinition(id: "pesetas200000", title: "Богатство 200k", desc: "Накопить 200000 песет", reward: 10000),
    AchievementDefinition(id: "pesetas500000", title: "Богатство 500k", desc: "Накопить 500000 песет", reward: 15000),
    AchievementDefinition(id: "pesetas2000000", title: "Богатство 2M", desc: "Накопить 2000000 песет", reward: 30000),
    AchievementDefinition(id: "pesetas5000000", title: "Богатство 5M", desc: "Накопить 5000000 песет", reward: 50000),
    AchievementDefinition(id: "pesetas10000000", title: "Богатство 10M", desc: "Накопить 10000000 песет", reward: 80000),
    AchievementDefinition(id: "pesetas50000000", title: "Богатство 50M", desc: "Накопить 50000000 песет", reward: 150000),
    AchievementDefinition(id: "skill2", title: "Навыки 2", desc: "Кристаллизовать 2 навыка", reward: 5000),
    AchievementDefinition(id: "skill3", title: "Навыки 3", desc: "Кристаллизовать 3 навыка", reward: 8000),
    AchievementDefinition(id: "skill5", title: "Навыки 5", desc: "Кристаллизовать 5 навыков", reward: 15000),
    AchievementDefinition(id: "skill10", title: "Навыки 10", desc: "Кристаллизовать 10 навыков", reward: 30000),
    AchievementDefinition(id: "subcount5", title: "Максимумы 5", desc: "5 подхарактеристик по 20", reward: 10000),
    AchievementDefinition(id: "subcount10", title: "Максимумы 10", desc: "10 подхарактеристик по 20", reward: 20000),
    AchievementDefinition(id: "subcount15", title: "Максимумы 15", desc: "15 подхарактеристик по 20", reward: 30000),
    AchievementDefinition(id: "subcount20", title: "Максимумы 20", desc: "20 подхарактеристик по 20", reward: 40000),
    AchievementDefinition(id: "subcount25", title: "Максимумы 25", desc: "25 подхарактеристик по 20", reward: 50000),
    AchievementDefinition(id: "subcount30", title: "Максимумы 30", desc: "30 подхарактеристик по 20", reward: 80000),
    AchievementDefinition(id: "total300", title: "Сумма 300", desc: "Сумма атрибутов 300", reward: 10000),
    AchievementDefinition(id: "total400", title: "Сумма 400", desc: "Сумма атрибутов 400", reward: 20000),
    AchievementDefinition(id: "total500", title: "Сумма 500", desc: "Сумма атрибутов 500", reward: 40000),
    AchievementDefinition(id: "total600", title: "Сумма 600", desc: "Сумма атрибутов 600", reward: 80000)
]

enum AchievementService {
    static func isUnlocked(_ id: String) -> Bool {
        guard let realm = try? Realm(), let user = realm.objects(User.self).first else { return false }
        if id.hasPrefix("lvl"), let n = Int(id.dropFirst(3)) { return user.level >= n }
        if id.hasPrefix("streak"), let n = Int(id.dropFirst(6)) { return realm.objects(Daily.self).contains { $0.streak >= n } }
        if id.hasPrefix("boss"), let n = Int(id.dropFirst(4)) { return realm.objects(Boss.self).filter { $0.isDefeated }.count >= n }
        if id.hasPrefix("coll"), let n = Int(id.dropFirst(4)) { return user.inventory.count >= n }
        if id.hasPrefix("pesetas"), let n = Int(id.dropFirst(7)) { return user.pesetas >= n }
        if id.hasPrefix("skill"), let n = Int(id.dropFirst(5)) { return user.skills.filter { $0.isPassive }.count >= n }
        if id.hasPrefix("subcount"), let n = Int(id.dropFirst(8)) { return user.attributes.flatMap { Array($0.subAttributes) }.filter { $0.value >= 20 }.count >= n }
        if id.hasPrefix("total"), let n = Int(id.dropFirst(5)) { return user.attributes.reduce(0) { $0 + $1.total } >= n }
        switch id {
        case "level5": return user.level >= 5
        case "level10": return user.level >= 10
        case "sub10": return user.attributes.flatMap { Array($0.subAttributes) }.contains { $0.value >= 10 }
        case "sub20": return user.attributes.flatMap { Array($0.subAttributes) }.contains { $0.value >= 20 }
        case "streak7": return realm.objects(Daily.self).contains { $0.streak >= 7 }
        case "streak30": return realm.objects(Daily.self).contains { $0.streak >= 30 }
        case "firstBoss": return realm.objects(Boss.self).contains { $0.isDefeated }
        case "threeBosses": return realm.objects(Boss.self).filter { $0.isDefeated }.count >= 3
        case "level20": return user.level >= 20
        case "level30": return user.level >= 30
        case "attr50": return user.attributes.contains { $0.total >= 50 }
        case "attr100": return user.attributes.contains { $0.total >= 100 }
        case "streak60": return realm.objects(Daily.self).contains { $0.streak >= 60 }
        case "streak100": return realm.objects(Daily.self).contains { $0.streak >= 100 }
        case "fiveBosses": return realm.objects(Boss.self).filter { $0.isDefeated }.count >= 5
        case "tenBosses": return realm.objects(Boss.self).filter { $0.isDefeated }.count >= 10
        case "collector10": return user.inventory.count >= 10
        case "collector30": return user.inventory.count >= 30
        case "rich100k": return user.pesetas >= 100000
        case "rich1m": return user.pesetas >= 1000000
        case "skillPassive": return user.skills.contains { $0.isPassive }
        case "subTriple20": return user.attributes.flatMap { Array($0.subAttributes) }.filter { $0.value >= 20 }.count >= 3
        default: return false
        }
    }
    static func isClaimed(_ id: String) -> Bool {
        guard let realm = try? Realm(), let s = realm.objects(AppSettings.self).first else { return false }
        return s.achievementsClaimed.components(separatedBy: ",").contains(id)
    }
    static func claim(_ def: AchievementDefinition) -> Bool {
        guard isUnlocked(def.id), !isClaimed(def.id), let realm = try? Realm(), let user = realm.objects(User.self).first else { return false }
        var claimed = false
        try? realm.write {
            let s = realm.objects(AppSettings.self).first ?? realm.create(AppSettings.self, value: ["id": "main"])
            user.pesetas += def.reward
            if s.achievementsClaimed.isEmpty { s.achievementsClaimed = def.id } else { s.achievementsClaimed += "," + def.id }
            claimed = true
        }
        if claimed { HistoryService.log("achievement", "Достижение: " + def.title, pesetas: def.reward) }
        return claimed
    }
}
