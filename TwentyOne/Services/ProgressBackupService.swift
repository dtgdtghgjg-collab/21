import Foundation
import RealmSwift

enum ProgressBackupService {
    struct Snapshot: Codable { var name: String; var level: Int; var xp: Int; var pesetas: Int; var achievementsClaimed: String; var sleepGoalHours: Double; var waterGoalLiters: Double }
    static func exportURL() -> URL? {
        guard let realm = try? Realm(), let user = realm.objects(User.self).first else { return nil }
        let s = realm.objects(AppSettings.self).first
        let snapshot = Snapshot(name: user.name, level: user.level, xp: user.xp, pesetas: user.pesetas, achievementsClaimed: s?.achievementsClaimed ?? "", sleepGoalHours: s?.sleepGoalHours ?? 7, waterGoalLiters: s?.waterGoalLiters ?? 1.5)
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(snapshot), let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("exports") else { return nil }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("progress_21.json21")
        do { try data.write(to: url); return url } catch { return nil }
    }
    static func importURL(_ url: URL) -> Bool {
        let scoped = url.startAccessingSecurityScopedResource(); defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url), let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else { return false }
        RealmStore.write { realm in
            guard let liveUser = RealmStore.user(in: realm) else { return }
            liveUser.name = String(snapshot.name.prefix(80))
            liveUser.level = min(max(snapshot.level, 1), 200)
            liveUser.xp = max(snapshot.xp, 0)
            liveUser.pesetas = min(max(snapshot.pesetas, -100000), 2000000000)
            let s = RealmStore.settings(in: realm) ?? realm.create(AppSettings.self, value: ["id": "main"])
            s.achievementsClaimed = snapshot.achievementsClaimed
            s.sleepGoalHours = min(max(snapshot.sleepGoalHours, 4), 12)
            s.waterGoalLiters = min(max(snapshot.waterGoalLiters, 0.5), 4)
        }
        return true
    }
}
