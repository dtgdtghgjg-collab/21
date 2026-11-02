import Foundation
import RealmSwift

enum HistoryService {
    static func log(_ kind: String, _ text: String, xp: Int = 0, pesetas: Int = 0) {
        guard let realm = try? Realm() else { return }
        let entry = HistoryEntry()
        entry.kind = kind
        entry.text = text
        entry.xpDelta = xp
        entry.pesetasDelta = pesetas
        entry.date = Date()
        try? realm.write { realm.add(entry) }
    }
    static func weeklySummary() -> String {
        guard let realm = try? Realm() else { return "Нет данных за неделю." }
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let entries = realm.objects(HistoryEntry.self).filter { $0.date >= weekAgo }
        let xp = entries.reduce(0) { $0 + $1.xpDelta }
        let pesetas = entries.reduce(0) { $0 + $1.pesetasDelta }
        let dailies = entries.filter { $0.kind == "daily_complete" }.count
        let bosses = entries.filter { $0.kind == "boss_defeated" }.count
        return "Итоги недели: дейликов выполнено " + String(dailies) + ", боссов побеждено " + String(bosses) + ", XP " + String(xp) + ", песеты " + String(pesetas) + "."
    }
}
