import SwiftUI
import RealmSwift

// MARK: - Day stats from real history (1. Diary, 2. Heatmap, 3. Markers)
struct CalendarDayStats {
    let date: Date
    let completed: Int
    let total: Int
    let xp: Int
    let pesetasEarned: Int
    let pesetasSpent: Int
    let sleepHours: Double?
    let waterLiters: Double?
    let bosses: [String]
    let achievements: [String]
    let purchases: [String]
    let hasPenalty: Bool
    let hasLargeDeal: Bool
    var ratio: Double { total > 0 ? Double(completed) / Double(total) : 0 }
    var isPerfect: Bool { total > 0 && completed >= total }
    var isMissed: Bool { hasPenalty || (date < Calendar.current.startOfDay(for: Date()) && total > 0 && completed == 0) }
    var markerEmojis: [String] {
        var m: [String] = []
        if !bosses.isEmpty { m.append("\u{2694}\u{FE0F}") }
        if hasLargeDeal { m.append("\u{1F4B0}") }
        if isPerfect { m.append("\u{1F525}") }
        if !achievements.isEmpty { m.append("\u{1F3C6}") }
        if hasPenalty { m.append("\u{1F480}") }
        return m
    }
    static func make(for day: Date, entries: [HistoryEntry], dailies: [Daily]) -> CalendarDayStats {
        let cal = Calendar.current
        let dayEntries = entries.filter { cal.isDate($0.date, inSameDayAs: day) }
        let regular = dailies.filter { !$0.isRandomDaily }
        let completed = dayEntries.filter { $0.kind == "daily_complete" }.count
        let xp = dayEntries.reduce(0) { $0 + $1.xpDelta }
        let earned = dayEntries.filter { $0.pesetasDelta > 0 }.reduce(0) { $0 + $1.pesetasDelta }
        let spent = dayEntries.filter { $0.pesetasDelta < 0 }.reduce(0) { $0 + (-$1.pesetasDelta) }
        let bosses = dayEntries.filter { $0.kind == "boss_defeated" }.map { $0.text.replacingOccurrences(of: "Побеждён босс: ", with: "") }
        let achievements = dayEntries.filter { $0.kind == "achievement" }.map { $0.text.replacingOccurrences(of: "Достижение: ", with: "") }
        let purchases = dayEntries.filter { $0.kind == "purchase" }.map { $0.text }
        let large = dayEntries.contains { abs($0.pesetasDelta) >= 500 }
        let penaltyByDaily = dailies.contains { $0.lastPenaltyDate.map { cal.isDate($0, inSameDayAs: day) } ?? false }
        let penaltyByHistory = dayEntries.contains { $0.kind == "daily_penalty" }
        var sleep: Double? = nil
        var water: Double? = nil
        if let t = dayEntries.first(where: { $0.kind == "tracker_day" })?.text {
            sleep = parseNumber(after: "сон", in: t)
            water = parseNumber(after: "вода", in: t)
        }
        return CalendarDayStats(date: day, completed: completed, total: regular.count, xp: xp, pesetasEarned: earned, pesetasSpent: spent, sleepHours: sleep, waterLiters: water, bosses: bosses, achievements: achievements, purchases: purchases, hasPenalty: penaltyByDaily || penaltyByHistory, hasLargeDeal: large)
    }
    static func parseNumber(after word: String, in text: String) -> Double? {
        guard let r = text.range(of: word) else { return nil }
        let rest = String(text[r.upperBound...])
        let num = rest.split(separator: " ").first.map(String.init) ?? ""
        return Double(num.replacingOccurrences(of: ",", with: "."))
    }
    static func heatColor(ratio: Double, isPerfect: Bool, isMissed: Bool) -> Color {
        if isMissed && ratio == 0 { return Color(red: 0.35, green: 0.15, blue: 0.15) }
        if isPerfect { return AppPalette.gold }
        if ratio <= 0 { return Color.white.opacity(0.05) }
        if ratio < 0.5 { return Color(red: 0.55, green: 0.42, blue: 0.15).opacity(0.55) }
        return Color(red: 0.85, green: 0.65, blue: 0.15).opacity(0.75 + 0.25 * ratio)
    }
}

// MARK: - 6. Legendary days
enum LegendaryDay {
    static func info(for date: Date) -> (emoji: String, title: String, desc: String)? {
        let c = Calendar.current
        let m = c.component(.month, from: date)
        let d = c.component(.day, from: date)
        switch (m, d) {
        case (1, 1): return ("\u{1F384}", "Новый год", "Легендарный день: выполни все дейлики — получишь двойной бонус месяца.")
        case (1, 7): return ("\u{1F384}", "Рождество", "Легендарный день.")
        case (2, 14): return ("\u{2764}\u{FE0F}", "День святого Валентина", "Легендарный день.")
        case (3, 8): return ("\u{1F490}", "8 Марта", "Легендарный день.")
        case (10, 31): return ("\u{1F383}", "Хэллоуин", "Легендарный день: тыквы в календаре, боссы сильнее, награды больше.")
        case (12, 25): return ("\u{1F384}", "Рождество", "Легендарный день.")
        case (12, 31): return ("\u{1F386}", "Новый год", "Легендарный день: последний день года.")
        default: return nil
        }
    }
    static var accountBirthday: Date? {
        if let t = UserDefaults.standard.object(forKey: "accountCreatedDate") as? Date { return t }
        if let realm = try? Realm(), let first = realm.objects(HistoryEntry.self).sorted(byKeyPath: "date").first {
            UserDefaults.standard.set(first.date, forKey: "accountCreatedDate")
            return first.date
        }
        return nil
    }
    static func isAccountBirthday(_ date: Date) -> Bool {
        guard let b = accountBirthday else { return false }
        let c = Calendar.current
        return c.component(.month, from: b) == c.component(.month, from: date) && c.component(.day, from: b) == c.component(.day, from: date)
    }
}

// MARK: - 4. Month progress + bonus
struct MonthProgressView: View {
    let month: Date
    let entries: [HistoryEntry]
    let totalDailies: Int
    var body: some View {
        let cal = Calendar.current
        let daysInMonth = cal.range(of: .day, in: .month, for: month)?.count ?? 30
        let isCurrent = cal.isDate(month, equalTo: Date(), toGranularity: .month)
        let elapsed = isCurrent ? cal.component(.day, from: Date()) : daysInMonth
        let expected = max(elapsed * max(totalDailies, 1), 1)
        let done = entries.filter { cal.isDate($0.date, equalTo: month, toGranularity: .month) && $0.kind == "daily_complete" }.count
        let pct = Double(done) / Double(expected)
        let key = "monthBonusClaimed_" + monthKey(month)
        let claimed = UserDefaults.standard.bool(forKey: key)
        let isPast = month < (cal.date(from: cal.dateComponents([.year, .month], from: Date())) ?? Date())
        VStack(alignment: .leading, spacing: 8) {
            HStack { Text("Прогресс месяца").font(.headline); Spacer(); Text("\(Int(pct * 100))%").font(.headline) }
            Text("Выполнено \(done) из \(expected) задач за \(monthName(month))")
                .font(.caption).foregroundStyle(.secondary)
            GradientProgressBar(value: Double(done), total: Double(expected), color: AppPalette.gold, height: 10)
            if isPast && pct >= 0.7 && !claimed {
                let bonus = 500 + Int(pct * 1000)
                Button("Забрать бонус месяца: +\(bonus) P") { claimMonthBonus(month: month, bonus: bonus, key: key) }
                    .buttonStyle(TwentyPrimaryButtonStyle(color: AppPalette.gold))
            } else if claimed {
                StatPill(icon: "checkmark.circle.fill", text: "Бонус месяца получен", color: AppPalette.gold)
            } else if isPast {
                Text("Бонус месяца (от 70%) не получен — было \(Int(pct * 100))%").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(TwentyOneTab.history.theme.card.opacity(0.92)))
    }
    func monthKey(_ d: Date) -> String { let f = DateFormatter(); f.dateFormat = "yyyy-MM"; return f.string(from: d) }
    func monthName(_ d: Date) -> String { let f = DateFormatter(); f.locale = Locale(identifier: "ru_RU"); f.dateFormat = "LLLL"; return f.string(from: d).capitalized }
    func claimMonthBonus(month: Date, bonus: Int, key: String) {
        RealmStore.write { realm in if let u = RealmStore.user(in: realm) { u.pesetas += bonus } }
        UserDefaults.standard.set(true, forKey: key)
        HistoryService.log("month_bonus", "Бонус месяца \(monthName(month)): +\(bonus) P", pesetas: bonus)
        Haptics.success(); SoundService.coin()
    }
}

// MARK: - 1. Day diary sheet
struct DayDiaryView: View {
    let day: Date
    let stats: CalendarDayStats
    let events: [Event]
    let onAddEvent: () -> Void
    @ObservedResults(MoodEntry.self) var moods
    @State private var mood = 3
    @State private var energy = 3
    @State private var savedMessage: String?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                let legendary = LegendaryDay.info(for: day)
                if let legendary = legendary {
                    HStack(spacing: 10) { Text(legendary.emoji).font(.title); VStack(alignment: .leading) { Text(legendary.title).font(.headline); Text(legendary.desc).font(.caption).foregroundStyle(.secondary) } }
                        .padding(12).background(RoundedRectangle(cornerRadius: 16).fill(AppPalette.gold.opacity(0.18)))
                }
                if LegendaryDay.isAccountBirthday(day) {
                    HStack(spacing: 10) { Text("\u{1F382}").font(.title); VStack(alignment: .leading) { Text("День рождения персонажа").font(.headline); Text("В этот день был создан аккаунт.").font(.caption).foregroundStyle(.secondary) } }
                        .padding(12).background(RoundedRectangle(cornerRadius: 16).fill(Color.purple.opacity(0.18)))
                }
                Text("Дейлики: \(stats.completed) из \(stats.total)").font(.headline)
                GradientProgressBar(value: Double(stats.completed), total: Double(max(stats.total, 1)), color: stats.isPerfect ? AppPalette.gold : TwentyOneTab.history.theme.accent, height: 10)
                if stats.isPerfect { StatPill(icon: "flame.fill", text: "Идеальный день", color: Color(red: 1.0, green: 0.55, blue: 0.20)) }
                HStack(spacing: 8) {
                    StatPill(icon: "star.fill", text: "\(stats.xp) XP", color: TwentyOneTab.history.theme.accent)
                    StatPill(icon: "banknote.fill", text: "+\(stats.pesetasEarned) P", color: AppPalette.gold)
                    if stats.pesetasSpent > 0 { StatPill(icon: "banknote.fill", text: "-\(stats.pesetasSpent) P", color: .red) }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Сон и вода").font(.headline)
                    if let s = stats.sleepHours { Text("Сон: \(String(format: "%.1f", s)) ч").font(.subheadline) } else { Text("Сон: не отмечен").font(.subheadline).foregroundStyle(.secondary) }
                    if let w = stats.waterLiters { Text("Вода: \(String(format: "%.2f", w)) л").font(.subheadline) } else { Text("Вода: не отмечена").font(.subheadline).foregroundStyle(.secondary) }
                    if stats.sleepHours == nil && stats.waterLiters == nil { Text("Отмечается в Дейликах в разделе «Сон и вода». Данные прошлых дней берутся из истории трекера.").font(.caption).foregroundStyle(.secondary) }
                }
                if !stats.bosses.isEmpty {
                    VStack(alignment: .leading, spacing: 4) { Text("Боссы").font(.headline); ForEach(stats.bosses, id: \.self) { Text("\u{2694}\u{FE0F} Побеждён босс: \($0)").font(.subheadline) } }
                }
                if stats.hasPenalty {
                    HStack(spacing: 8) { Text("\u{1F480}").font(.title2); Text("Пропущено: получен штраф, стрик сгорел.").font(.subheadline) }
                        .padding(10).background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.15)))
                }
                if !stats.achievements.isEmpty {
                    VStack(alignment: .leading, spacing: 4) { Text("Достижения").font(.headline); ForEach(stats.achievements, id: \.self) { Text("\u{1F3C6} \($0)").font(.subheadline) } }
                }
                if !stats.purchases.isEmpty {
                    VStack(alignment: .leading, spacing: 4) { Text("Покупки").font(.headline); ForEach(stats.purchases, id: \.self) { Text($0).font(.caption).foregroundStyle(.secondary) } }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Настроение и энергия").font(.headline)
                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { v in
                            Button { mood = v } label: { Text(["\u{1F62B}", "\u{1F615}", "\u{1F610}", "\u{1F642}", "\u{1F604}"][v - 1]).font(.title2).padding(6).background(Circle().fill(mood == v ? AppPalette.gold.opacity(0.3) : Color.clear)) }.buttonStyle(.plain)
                        }
                    }
                    HStack { Text("Энергия: \(energy)/5"); Slider(value: Binding(get: { Double(energy) }, set: { energy = Int($0) }), in: 1...5, step: 1) }
                    Button("Сохранить настроение") { saveMood() }.buttonStyle(TwentyPrimaryButtonStyle(color: TwentyOneTab.history.theme.accent))
                    if let savedMessage = savedMessage { Text(savedMessage).font(.caption).foregroundStyle(.secondary) }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("События дня").font(.headline)
                    if events.isEmpty { Text("Нет событий").font(.caption).foregroundStyle(.secondary) }
                    ForEach(events, id: \.id) { e in Text("\(e.title) · \(e.type)").font(.subheadline) }
                    Button("Добавить событие на этот день") { onAddEvent() }.buttonStyle(TwentySecondaryButtonStyle(color: TwentyOneTab.history.theme.accent))
                }
            }
            .padding()
        }
        .onAppear { loadMood() }
    }
    func loadMood() {
        if let m = moods.first(where: { Calendar.current.isDate($0.date, inSameDayAs: day) }) { mood = m.mood; energy = m.energy }
    }
    func saveMood() {
        let d = Calendar.current.startOfDay(for: day)
        let m = mood; let e = energy
        RealmStore.write { realm in
            if let live = realm.objects(MoodEntry.self).first(where: { Calendar.current.isDate($0.date, inSameDayAs: d) }) { live.mood = m; live.energy = e } else { let entry = MoodEntry(); entry.date = d; entry.mood = m; entry.energy = e; realm.add(entry) }
        }
        savedMessage = "Сохранено: настроение \(mood)/5, энергия \(energy)/5"
        Haptics.success()
    }
}

// MARK: - 7. Mood / energy line chart (no Charts dependency, iOS 17 safe)
struct MoodLineChartView: View {
    let month: Date
    @ObservedResults(MoodEntry.self) var moods
    var body: some View {
        let cal = Calendar.current
        let days = (cal.range(of: .day, in: .month, for: month)?.count ?? 30)
        let points: [(Int, Int, Int)] = (1...days).compactMap { d in
            guard let date = cal.date(byAdding: .day, value: d - 1, to: month), let m = moods.first(where: { cal.isDate($0.date, inSameDayAs: date) }) else { return nil }
            return (d, m.mood, m.energy)
        }
        VStack(alignment: .leading, spacing: 8) {
            Text("Настроение и энергия").font(.headline)
            if points.isEmpty {
                Text("Пока нет отметок настроения в этом месяце. Открой любой день и отметь настроение в дневнике.").font(.caption).foregroundStyle(.secondary)
            } else {
                GeometryReader { geo in
                    ZStack {
                        linePath(points: points.map { ($0.0, $0.2) }, days: days, size: geo.size, color: Color(red: 0.30, green: 0.58, blue: 1.0))
                        linePath(points: points.map { ($0.0, $0.1) }, days: days, size: geo.size, color: AppPalette.gold)
                        ForEach(points, id: \.0) { p in
                            Circle().fill(AppPalette.gold).frame(width: 7, height: 7)
                                .position(x: xPos(day: p.0, days: days, width: geo.size.width), y: yPos(value: p.1, height: geo.size.height))
                        }
                    }
                }
                .frame(height: 120)
                HStack(spacing: 12) { Text("\u{1F7E1} Настроение").font(.caption); Text("\u{1F535} Энергия").font(.caption) }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(TwentyOneTab.history.theme.card.opacity(0.92)))
    }
    func xPos(day: Int, days: Int, width: CGFloat) -> CGFloat { days <= 1 ? width / 2 : CGFloat(day - 1) / CGFloat(max(days - 1, 1)) * width }
    func yPos(value: Int, height: CGFloat) -> CGFloat { height - (CGFloat(value - 1) / 4.0 * (height - 16) + 8) }
    func linePath(points: [(Int, Int)], days: Int, size: CGSize, color: Color) -> some View {
        Path { p in
            guard let first = points.first else { return }
            p.move(to: CGPoint(x: xPos(day: first.0, days: days, width: size.width), y: yPos(value: first.1, height: size.height)))
            for pt in points.dropFirst() { p.addLine(to: CGPoint(x: xPos(day: pt.0, days: days, width: size.width), y: yPos(value: pt.1, height: size.height))) }
        }.stroke(color, lineWidth: 2)
    }
}

// MARK: - 5. Year stats
struct YearStatsView: View {
    let year: Int
    let entries: [HistoryEntry]
    let totalDailies: Int
    var body: some View {
        let cal = Calendar.current
        let months = (1...12).map { m -> (Int, Int, Int, Int, Double) in
            let start = cal.date(from: DateComponents(year: year, month: m, day: 1)) ?? Date()
            let days = cal.range(of: .day, in: .month, for: start)?.count ?? 30
            let isCurrentYearMonth = cal.component(.year, from: Date()) == year && cal.component(.month, from: Date()) == m
            let elapsed = isCurrentYearMonth ? cal.component(.day, from: Date()) : days
            let monthEntries = entries.filter { cal.component(.year, from: $0.date) == year && cal.component(.month, from: $0.date) == m }
            let done = monthEntries.filter { $0.kind == "daily_complete" }.count
            let xp = monthEntries.reduce(0) { $0 + $1.xpDelta }
            let perfect = Set(monthEntries.filter { $0.kind == "daily_complete" }.map { cal.startOfDay(for: $0.date) }).count
            let pct = Double(done) / Double(max(elapsed * max(totalDailies, 1), 1))
            return (m, done, xp, perfect, pct)
        }
        let best = months.max(by: { $0.4 < $1.4 })
        VStack(alignment: .leading, spacing: 12) {
            Text("Год \(year): свиток продуктивности").font(.headline)
            Text("Лучший месяц: \(monthName(best?.0 ?? 1)) — \(Int((best?.4 ?? 0) * 100))%").font(.subheadline).foregroundStyle(.secondary)
            ForEach(months, id: \.0) { m in
                VStack(alignment: .leading, spacing: 4) {
                    HStack { Text(monthName(m.0)).font(.subheadline.weight(.semibold)); if m.0 == best?.0 { Text("\u{1F451} лучший").font(.caption) }; Spacer(); Text("\(Int(m.4 * 100))% · \(m.2) XP").font(.caption).foregroundStyle(.secondary) }
                    GradientProgressBar(value: m.4, total: 1.0, color: m.0 == best?.0 ? AppPalette.gold : TwentyOneTab.history.theme.accent, height: 8)
                    Text("Дейликов: \(m.1) · дней с выполнением: \(m.3)").font(.caption).foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(TwentyOneTab.history.theme.card.opacity(0.92)))
    }
    func monthName(_ m: Int) -> String { let f = DateFormatter(); f.locale = Locale(identifier: "ru_RU"); f.dateFormat = "LLLL"; let d = Calendar.current.date(from: DateComponents(year: year, month: m, day: 1)) ?? Date(); return f.string(from: d).capitalized }
}
