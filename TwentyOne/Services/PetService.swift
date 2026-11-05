import Foundation
import Combine
import RealmSwift

/// Pet state lives in UserDefaults only — no Realm migration.
/// Pesetas still live on the existing Realm `User.pesetas` field.
enum PetType: String, CaseIterable, Identifiable {
    case ember
    case mochi
    case pip

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .ember: return "Ember"
        case .mochi: return "Mochi"
        case .pip: return "Pip"
        }
    }

    var displayName: String {
        switch self {
        case .ember: return "Ember — рыжий лисёнок"
        case .mochi: return "Mochi — голубой слайм"
        case .pip: return "Pip — зелёный птенец-росток"
        }
    }

    func imageName(mood: PetMood, idleFrame: Int = 1) -> String {
        switch mood {
        case .idle: return "\(rawValue)_idle_\(idleFrame)"
        case .happy: return "\(rawValue)_happy"
        case .sad: return "\(rawValue)_sad"
        }
    }
}

enum PetMood {
    case idle
    case happy
    case sad
}

final class PetService: ObservableObject {
    static let shared = PetService()
    static let feedCost = 50
    static let xpBonusPercent = 5
    static let fedDuration: TimeInterval = 24 * 60 * 60

    private enum Keys {
        static let type = "pet.type"
        static let lastFed = "pet.lastFed"
    }

    private let defaults = UserDefaults.standard

    @Published private(set) var petType: PetType {
        didSet { defaults.set(petType.rawValue, forKey: Keys.type) }
    }

    @Published private(set) var lastFed: Date? {
        didSet {
            if let lastFed { defaults.set(lastFed, forKey: Keys.lastFed) }
            else { defaults.removeObject(forKey: Keys.lastFed) }
        }
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: Keys.type) ?? ""
        self.petType = PetType(rawValue: raw) ?? .ember
        self.lastFed = UserDefaults.standard.object(forKey: Keys.lastFed) as? Date
    }

    var isHungry: Bool {
        guard let lastFed else { return true }
        return Date().timeIntervalSince(lastFed) >= Self.fedDuration
    }

    var isFed: Bool { !isHungry }

    var xpMultiplier: Double { isFed ? 1.05 : 1.0 }

    func bonusXP(for baseXP: Int) -> Int {
        guard isFed, baseXP > 0 else { return 0 }
        return Int((Double(baseXP) * Double(Self.xpBonusPercent) / 100.0).rounded())
    }

    func xpWithBonus(_ baseXP: Int) -> Int { baseXP + bonusXP(for: baseXP) }

    var timeUntilHungryText: String {
        guard let lastFed, isFed else { return "" }
        let remaining = Self.fedDuration - Date().timeIntervalSince(lastFed)
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        return "\(hours) ч \(minutes) мин"
    }

    func selectPet(_ type: PetType) {
        petType = type
    }

    enum FeedResult {
        case success
        case notEnoughPesetas
        case noUser
    }

    @discardableResult
    func feed() -> FeedResult {
        guard let realm = try? Realm(), let current = realm.objects(User.self).first else { return .noUser }
        guard current.pesetas >= Self.feedCost else { return .notEnoughPesetas }
        let userId = current.id
        var deducted = false
        RealmStore.write { realm in
            guard let live = realm.object(ofType: User.self, forPrimaryKey: userId), live.pesetas >= Self.feedCost else { return }
            live.pesetas -= Self.feedCost
            deducted = true
        }
        guard deducted else { return .notEnoughPesetas }
        lastFed = Date()
        return .success
    }
}
