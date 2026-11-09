import SwiftUI
import RealmSwift

// MARK: - 3. Rank + loan limits

enum HeroRank {
    static func name(for level: Int) -> String {
        switch level {
        case ..<5: return "F"
        case ..<10: return "E"
        case ..<15: return "D"
        case ..<20: return "C"
        case ..<30: return "B"
        case ..<40: return "A"
        case ..<50: return "S"
        case ..<70: return "SS"
        case ..<100: return "SSS"
        default: return "R"
        }
    }
    static func maxLoan(for level: Int) -> Int {
        if level < 5 { return 0 }
        return level * 200
    }
    static let interestPercent = 10
    static let loanTermDays = 7
    static func repayAmount(for principal: Int) -> Int { principal + principal * interestPercent / 100 }
}

// MARK: - 4. Titles

struct TitleDefinition: Identifiable {
    let id: String
    let name: String
    let desc: String
    let icon: String
}

enum TitlesService {
    static let all: [TitleDefinition] = [
        TitleDefinition(id: "novice", name: "Новичок", desc: "Начальный титул", icon: "sprout"),
        TitleDefinition(id: "boss1", name: "Победитель босса", desc: "Победить 1 босса", icon: "shield"),
        TitleDefinition(id: "boss10", name: "Победитель 10 боссов", desc: "Победить 10 боссов", icon: "shield.fill"),
        TitleDefinition(id: "boss25", name: "Гроза боссов", desc: "Победить 25 боссов", icon: "flame"),
        TitleDefinition(id: "worker7", name: "Работяга", desc: "Стрик полных дней 7", icon: "hammer"),
        TitleDefinition(id: "worker21", name: "Трудяга", desc: "Стрик полных дней 21 день", icon: "hammer.fill"),
        TitleDefinition(id: "streakDaily30", name: "Несгибаемый", desc: "Стрик дейлика 30 дней", icon: "link"),
        TitleDefinition(id: "dailies100", name: "Ветеран дейликов", desc: "Выполнить 100 дейликов", icon: "checklist"),
        TitleDefinition(id: "dailies500", name: "Машина привычек", desc: "Выполнить 500 дейликов", icon: "gearshape.2"),
        TitleDefinition(id: "sleepBeauty", name: "Спящая красавица", desc: "Спать дольше цели на 2+ часа в 3 днях трекера", icon: "moon.zzz.fill"),
        TitleDefinition(id: "earlyBird", name: "Ранняя пташка", desc: "Выполнять цель сна 7 дней трекера", icon: "sunrise.fill"),
        TitleDefinition(id: "rich", name: "Магнат песет", desc: "Баланс 100 000 P", icon: "banknote.fill"),
        TitleDefinition(id: "level20", name: "Герой 20 уровня", desc: "Достичь 20 уровня", icon: "star.fill"),
        TitleDefinition(id: "collector30", name: "Коллекционер", desc: "Собрать 30 предметов", icon: "backpack.fill"),
        TitleDefinition(id: "inDebt", name: "В долгу", desc: "Взять заём или уйти в минус", icon: "exclamationmark.triangle.fill")
    ]
    static func isUnlocked(_ id: String, user: User, realm: Realm) -> Bool {
        let bosses = realm.objects(Boss.self).filter { $0.isDefeated }.count
        let dailyStreak = realm.objects(Daily.self).map { $0.streak }.max() ?? 0
        let dailiesDone = realm.objects(HistoryEntry.self).filter { $0.kind == "daily_complete" }.count
        let tracker = realm.objects(HistoryEntry.self).filter { $0.kind == "tracker_day" }
        let goal = realm.objects(AppSettings.self).first?.sleepGoalHours ?? 7
        var overslept = 0
        var goalMet = 0
        for e in tracker {
            if let s = CalendarDayStats.parseNumber(after: "сон", in: e.text) {
                if s >= goal + 2 { overslept += 1 }
                if s >= goal { goalMet += 1 }
            }
        }
        switch id {
        case "novice": return true
        case "boss1": return bosses >= 1
        case "boss10": return bosses >= 10
        case "boss25": return bosses >= 25
        case "worker7": return StreakRewardService.currentStreak() >= 7
        case "worker21": return StreakRewardService.currentStreak() >= 21
        case "streakDaily30": return dailyStreak >= 30
        case "dailies100": return dailiesDone >= 100
        case "dailies500": return dailiesDone >= 500
        case "sleepBeauty": return overslept >= 3
        case "earlyBird": return goalMet >= 7
        case "rich": return user.pesetas >= 100000
        case "level20": return user.level >= 20
        case "collector30": return user.inventory.count >= 30
        case "inDebt": return user.loanAmount > 0 || user.pesetas < 0
        default: return false
        }
    }
    static func current(user: User, realm: Realm) -> TitleDefinition {
        if let t = all.first(where: { $0.id == user.selectedTitleId }), isUnlocked(t.id, user: user, realm: realm) { return t }
        return all[0]
    }
}

struct TitlesPickerView: View {
    @ObservedResults(User.self) var users
    var user: User? { users.first }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Титулы").font(.headline)
            if let user = user, let realm = try? Realm() {
                Text("Текущий: \(TitlesService.current(user: user, realm: realm).name)").font(.subheadline).foregroundStyle(AppPalette.gold)
                ForEach(TitlesService.all) { def in
                    let unlocked = TitlesService.isUnlocked(def.id, user: user, realm: realm)
                    HStack(spacing: 10) {
                        Image(systemName: unlocked ? def.icon : "lock.fill").foregroundStyle(unlocked ? AppPalette.gold : Color.white.opacity(0.4))
                        VStack(alignment: .leading, spacing: 2) { Text(def.name).font(.subheadline.weight(.semibold)); Text(def.desc).font(.caption).foregroundStyle(.secondary) }
                        Spacer()
                        if unlocked {
                            Button(user.selectedTitleId == def.id ? "Выбран" : "Выбрать") { select(def.id) }.buttonStyle(TwentySecondaryButtonStyle(color: TwentyOneTab.profile.theme.accent)).disabled(user.selectedTitleId == def.id)
                        } else { Text("Закрыт").font(.caption).foregroundStyle(.secondary) }
                    }
                }
            }
        }
    }
    func select(_ id: String) {
        guard let userId = user?.id else { return }
        RealmStore.write { realm in realm.object(ofType: User.self, forPrimaryKey: userId)?.selectedTitleId = id }
        Haptics.success()
    }
}

// MARK: - 6. Key stats under the chart

struct ProfileKeyStatsView: View {
    @ObservedResults(HistoryEntry.self) var entries
    @ObservedResults(Boss.self) var bosses
    var body: some View {
        let dailiesDone = entries.filter { $0.kind == "daily_complete" }.count
        let bossesDone = bosses.filter { $0.isDefeated }.count
        let daysInGame: Int = {
            if let b = LegendaryDay.accountBirthday { return max(Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: b), to: Calendar.current.startOfDay(for: Date())).day ?? 0, 0) + 1 }
            return 1
        }()
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            statCard(icon: "flame.fill", value: "\(StreakRewardService.currentStreak())", label: "Текущий стрик", color: Color(red: 1.0, green: 0.55, blue: 0.20))
            statCard(icon: "shield.fill", value: "\(bossesDone)", label: "Побеждено боссов", color: TwentyOneTab.bosses.theme.accent)
            statCard(icon: "checklist", value: "\(dailiesDone)", label: "Выполнено дейликов", color: TwentyOneTab.dailies.theme.accent)
            statCard(icon: "calendar", value: "\(daysInGame)", label: "Всего в игре дней", color: TwentyOneTab.history.theme.accent)
        }
    }
    func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value).font(.system(size: 22, weight: .bold, design: .rounded))
            Text(label).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(TwentyOneTab.profile.theme.card.opacity(0.92)))
    }
}

// MARK: - 5. Radar chart for attributes (no Charts dependency)

struct RadarChartView: View {
    let attributes: [Attribute]
    var body: some View {
        let values = attributes.map { min(Double($0.total) / 100.0, 1.0) }
        VStack(alignment: .leading, spacing: 8) {
            Text("Диаграмма характеристик").font(.headline)
            if attributes.isEmpty { Text("Характеристики появятся после первого открытия вкладки характеристик.").font(.caption).foregroundStyle(.secondary) }
            else {
                GeometryReader { geo in
                    let side = min(geo.size.width, geo.size.height)
                    let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                    ZStack {
                        ForEach([0.33, 0.66, 1.0], id: \.self) { ring in polygonPath(values: Array(repeating: ring, count: values.count), center: center, radius: side / 2 - 28).stroke(Color.white.opacity(0.15), lineWidth: 1) }
                        polygonPath(values: values, center: center, radius: side / 2 - 28).fill(TwentyOneTab.profile.theme.accent.opacity(0.35))
                        polygonPath(values: values, center: center, radius: side / 2 - 28).stroke(TwentyOneTab.profile.theme.accent, lineWidth: 2)
                        ForEach(Array(attributes.enumerated()), id: \.offset) { idx, attr in
                            let p = point(index: idx, count: values.count, value: 1.12, center: center, radius: side / 2 - 28)
                            Text(attr.name).font(.caption2).position(x: p.x, y: p.y)
                        }
                    }
                }.frame(height: 260)
                ForEach(attributes, id: \.id) { attr in HStack { Text(attr.name).font(.caption); Spacer(); Text("\(attr.total) / 100").font(.caption).foregroundStyle(.secondary) } }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(TwentyOneTab.profile.theme.card.opacity(0.92)))
    }
    func point(index: Int, count: Int, value: Double, center: CGPoint, radius: CGFloat) -> CGPoint {
        let angle = (Double(index) / Double(max(count, 1))) * 2 * Double.pi - Double.pi / 2
        return CGPoint(x: center.x + CGFloat(cos(angle) * value) * radius, y: center.y + CGFloat(sin(angle) * value) * radius)
    }
    func polygonPath(values: [Double], center: CGPoint, radius: CGFloat) -> Path {
        Path { p in
            guard !values.isEmpty else { return }
            for (i, v) in values.enumerated() {
                let pt = point(index: i, count: values.count, value: v, center: center, radius: radius)
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            p.closeSubpath()
        }
    }
}

// MARK: - 3/5. Bank: earnings stats from history

struct BankStatsView: View {
    @ObservedResults(HistoryEntry.self) var entries
    var body: some View {
        let earned = entries.filter { $0.pesetasDelta > 0 }.reduce(0) { $0 + $1.pesetasDelta }
        let spent = entries.filter { $0.pesetasDelta < 0 }.reduce(0) { $0 + (-$1.pesetasDelta) }
        let xpTotal = entries.reduce(0) { $0 + $1.xpDelta }
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weekEarned = entries.filter { $0.date >= weekAgo && $0.pesetasDelta > 0 }.reduce(0) { $0 + $1.pesetasDelta }
        VStack(alignment: .leading, spacing: 8) {
            Text("Статистика заработка").font(.headline)
            HStack(spacing: 8) { StatPill(icon: "banknote.fill", text: "Заработано: +\(earned) P", color: AppPalette.gold); StatPill(icon: "banknote.fill", text: "Потрачено: -\(spent) P", color: .red) }
            HStack(spacing: 8) { StatPill(icon: "star.fill", text: "XP из истории: \(xpTotal)", color: TwentyOneTab.profile.theme.accent); StatPill(icon: "calendar", text: "За 7 дней: +\(weekEarned) P", color: TwentyOneTab.dailies.theme.accent) }
            Text("Считается по журналу истории: дейлики, боссы, достижения, бонусы месяца минус покупки и штрафы.").font(.caption).foregroundStyle(.secondary)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(TwentyOneTab.profile.theme.card.opacity(0.92)))
    }
}
