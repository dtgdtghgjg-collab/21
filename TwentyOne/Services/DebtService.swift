import Foundation
import RealmSwift

enum DebtOutcome { case ok, inDebt, insuranceUsed, wiped }

struct DebtService {
    static let graceInterval: TimeInterval = 72 * 60 * 60
    static func remainingSeconds(for user: User, now: Date = Date()) -> Int? {
        guard user.pesetas < 0, let started = user.debtStartedAt else { return nil }
        return max(Int(graceInterval - now.timeIntervalSince(started)), 0)
    }
    static func evaluate(now: Date = Date()) -> DebtOutcome {
        guard let realm = try? Realm(), let user = realm.objects(User.self).first else { return .ok }
        if user.pesetas >= 0 {
            if user.debtStartedAt != nil { try? realm.write { user.debtStartedAt = nil } }
            return .ok
        }
        if user.debtStartedAt == nil {
            try? realm.write { user.debtStartedAt = now }
            return .inDebt
        }
        guard let started = user.debtStartedAt, now.timeIntervalSince(started) >= graceInterval else { return .inDebt }
        if let insurance = user.inventory.first(where: { $0.uniqueFeature == "death_insurance" }) {
            try? realm.write {
                var invIdx: Int? = nil
                for (i, inv) in user.inventory.enumerated() { if inv.id == insurance.id { invIdx = i; break } }
                if let invIdx = invIdx { user.inventory.remove(at: invIdx) }
                var eqIdx: Int? = nil
                for (i, eq) in user.equipped.enumerated() { if eq.id == insurance.id { eqIdx = i; break } }
                if let eqIdx = eqIdx { user.equipped.remove(at: eqIdx) }
                realm.delete(insurance)
                user.pesetas = 0
                user.debtStartedAt = nil
            }
            return .insuranceUsed
        }
        wipe(realm: realm)
        return .wiped
    }
    static func wipe(realm: Realm) {
        try? realm.write {
            realm.delete(realm.objects(Daily.self))
            realm.delete(realm.objects(Event.self))
            realm.delete(realm.objects(Boss.self))
            realm.delete(realm.objects(Item.self))
            realm.delete(realm.objects(Skill.self))
            realm.delete(realm.objects(Attribute.self))
            realm.delete(realm.objects(SubAttribute.self))
            realm.delete(realm.objects(User.self))
            if let s = realm.objects(AppSettings.self).first { s.firstItemGiven = false; s.marketPurchased = ""; s.lootboxLastDate = nil }
            realm.add(User())
        }
    }
}
