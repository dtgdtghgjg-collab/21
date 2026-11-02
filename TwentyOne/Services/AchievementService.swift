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
    AchievementDefinition(id: "threeBosses", title: "Три босса", desc: "Победить трёх боссов", reward: 5000)
]

enum AchievementService {
    static func isUnlocked(_ id: String) -> Bool {
        guard let realm = try? Realm(), let user = realm.objects(User.self).first else { return false }
        switch id {
        case "level5": return user.level >= 5
        case "level10": return user.level >= 10
        case "sub10": return user.attributes.flatMap { Array($0.subAttributes) }.contains { $0.value >= 10 }
        case "sub20": return user.attributes.flatMap { Array($0.subAttributes) }.contains { $0.value >= 20 }
        case "streak7": return realm.objects(Daily.self).contains { $0.streak >= 7 }
        case "streak30": return realm.objects(Daily.self).contains { $0.streak >= 30 }
        case "firstBoss": return realm.objects(Boss.self).contains { $0.isDefeated }
        case "threeBosses": return realm.objects(Boss.self).filter { $0.isDefeated }.count >= 3
        default: return false
        }
    }
    static func isClaimed(_ id: String) -> Bool {
        guard let realm = try? Realm(), let s = realm.objects(AppSettings.self).first else { return false }
        return s.achievementsClaimed.components(separatedBy: ",").contains(id)
    }
    static func claim(_ def: AchievementDefinition) -> Bool {
        guard isUnlocked(def.id), !isClaimed(def.id), let realm = try? Realm(), let user = realm.objects(User.self).first, let s = realm.objects(AppSettings.self).first else { return false }
        try? realm.write { user.pesetas += def.reward; if s.achievementsClaimed.isEmpty { s.achievementsClaimed = def.id } else { s.achievementsClaimed += "," + def.id } }
        HistoryService.log("achievement", "Достижение: " + def.title, pesetas: def.reward)
        return true
    }
}
