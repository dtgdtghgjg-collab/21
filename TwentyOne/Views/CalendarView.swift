import SwiftUI
import RealmSwift

struct CalendarView: View {
    @ObservedResults(Event.self) var events
    @ObservedResults(Daily.self) var dailies
    @ObservedResults(Boss.self) var bosses
    @State private var month: Date = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
    @State private var selectedDay: Date?
    @State private var showEventForm = false
    @State private var newTitle = ""
    @State private var newDate = Date()
    @State private var newType = "custom"
    @State private var newThreshold = 10
    @State private var selectedDailyId: String?
    @State private var selectedBossId: String?
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Button("<") { changeMonth(by: -1) }
                        Spacer()
                        Text(monthTitle).font(.headline)
                        Spacer()
                        Button(">") { changeMonth(by: 1) }
                    }
                    HStack {
                        ForEach(["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"], id: \.self) { day in
                            Text(day).font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                        }
                    }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(Array(monthCells.enumerated()), id: \.offset) { item in
                            if let day = item.element {
                                Button { openForm(for: day) } label: {
                                    VStack(spacing: 2) {
                                        Text(String(Calendar.current.component(.day, from: day))).font(.body)
                                        Circle().fill(eventsOn(day).isEmpty ? Color.clear : Color.red).frame(width: 6, height: 6)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .background(Calendar.current.isDateInToday(day) ? Color.blue.opacity(0.2) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            } else {
                                Color.clear.frame(height: 44)
                            }
                        }
                    }
                    .gesture(DragGesture().onEnded { value in
                        if value.translation.width < -50 { changeMonth(by: 1) } else if value.translation.width > 50 { changeMonth(by: -1) }
                    })
                    if let selectedDay = selectedDay {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("События дня").font(.headline)
                            if eventsOn(selectedDay).isEmpty {
                                Text("Нет событий").font(.caption).foregroundStyle(.secondary)
                            }
                            ForEach(eventsOn(selectedDay), id: \.id) { event in
                                eventRow(event)
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Грядущие события").font(.headline)
                        if upcomingEvents.isEmpty {
                            Text("Нет грядущих событий").font(.caption).foregroundStyle(.secondary)
                        }
                        ForEach(upcomingEvents, id: \.id) { event in
                            eventRow(event)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Календарь")
            .sheet(isPresented: $showEventForm) {
                NavigationStack {
                    Form {
                        TextField("Название", text: $newTitle)
                        DatePicker("Дата и время", selection: $newDate, displayedComponents: [.date, .hourAndMinute])
                        Picker("Тип", selection: $newType) {
                            Text("Экзамен").tag("exam")
                            Text("Дедлайн").tag("deadline")
                            Text("Праздник").tag("holiday")
                            Text("Драка").tag("fight")
                            Text("Спорт").tag("sport")
                            Text("Свидание").tag("date")
                            Text("Своё").tag("custom")
                        }
                        Stepper("Порог тревоги: " + String(newThreshold) + " дн.", value: $newThreshold, in: 1...30)
                        Picker("Дейлик", selection: $selectedDailyId) {
                            Text("Без дейлика").tag(nil as String?)
                            ForEach(dailies, id: \.id) { daily in
                                Text(daily.title).tag(daily.id.stringValue as String?)
                            }
                        }
                        Picker("Босс", selection: $selectedBossId) {
                            Text("Без босса").tag(nil as String?)
                            ForEach(bosses, id: \.id) { boss in
                                Text(boss.name).tag(boss.id.stringValue as String?)
                            }
                        }
                        Button("Сохранить событие") { addEvent() }.disabled(newTitle.isEmpty)
                    }
                    .navigationTitle("Новое событие")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Отмена") { showEventForm = false }
                        }
                    }
                }
            }
        }
    }
    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: month).capitalized
    }
    var monthCells: [Date?] {
        let calendar = Calendar.current
        let days = calendar.range(of: .day, in: .month, for: month)?.count ?? 30
        let weekday = calendar.component(.weekday, from: month)
        let offset = (weekday + 5) % 7
        var cells: [Date?] = Array(repeating: nil, count: offset)
        for day in 1...days {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: month) {
                cells.append(date)
            }
        }
        return cells
    }
    var upcomingEvents: [Event] {
        let today = Calendar.current.startOfDay(for: Date())
        return events.filter { $0.date >= today }.sorted { $0.date < $1.date }
    }
    func eventsOn(_ day: Date) -> [Event] {
        events.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }
    }
    func daysUntil(_ event: Event) -> Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: event.date)).day ?? 0
    }
    func countdownText(_ event: Event) -> String {
        let left = daysUntil(event)
        if left < 0 { return "прошло" }
        if left == 0 { return "сегодня" }
        return "через " + String(left) + " дн."
    }
    func alarmColor(_ event: Event) -> Color {
        let left = daysUntil(event)
        let threshold = max(event.colorThresholdDays, 1)
        if left < 0 { return Color.gray.opacity(0.15) }
        if left >= threshold { return Color.clear }
        let intensity = 1.0 - Double(left) / Double(threshold)
        return Color.red.opacity(0.15 + 0.55 * intensity)
    }
    func eventRow(_ event: Event) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                Text(countdownText(event) + " · " + event.type).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Удалить") { deleteEvent(event) }.font(.caption)
        }
        .padding(8)
        .background(alarmColor(event))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    func changeMonth(by value: Int) {
        if let next = Calendar.current.date(byAdding: .month, value: value, to: month) {
            month = next
        }
    }
    func openForm(for day: Date) {
        selectedDay = day
        newDate = day
        newTitle = ""
        newType = "custom"
        newThreshold = 10
        selectedDailyId = nil
        selectedBossId = nil
        showEventForm = true
    }
    func addEvent() {
        guard let realm = try? Realm() else { return }
        let event = Event()
        event.title = newTitle
        event.date = newDate
        event.type = newType
        event.colorThresholdDays = newThreshold
        event.linkedDailyId = selectedDailyId
        event.linkedBossId = selectedBossId
        var generatedBoss: Boss? = nil
        if selectedBossId == nil && newType != "custom" {
            let boss = Boss()
            boss.name = newType == "exam" ? "Призрак сессии" : (newType == "deadline" ? "Пожиратель сроков" : (newType == "fight" ? "Дух агрессии" : (newType == "sport" ? "Тень лени" : (newType == "date" ? "Демон неловкости" : "Дух веселья"))))
            boss.rank = newType == "exam" ? "C" : (newType == "deadline" ? "D" : (newType == "fight" ? "B" : (newType == "sport" ? "D" : "E")))
            let calendar = Calendar.current
            let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: newDate)).day ?? 0
            let divisor = max(days, 1)
            let mult = Int(rankMultipliers[boss.rank] ?? 1)
            boss.hp = max(100, 1000 * mult / divisor)
            boss.maxHp = boss.hp
            boss.rewardsPesetas = boss.hp / 2
            boss.rewardsXp = boss.hp / 10
            boss.isEventBoss = true
            boss.eventDate = newDate
            boss.calendarEventLink = event.id.stringValue
            generatedBoss = boss
            event.linkedBossId = boss.id.stringValue
        }
        try? realm.write { realm.add(event); if let generatedBoss = generatedBoss { realm.add(generatedBoss) } }
        showEventForm = false
    }
    func deleteEvent(_ event: Event) {
        guard let realm = try? Realm() else { return }
        let bossId = event.linkedBossId
        let eventId = event.id.stringValue
        try? realm.write {
            for boss in realm.objects(Boss.self) where (boss.id.stringValue == bossId || boss.calendarEventLink == eventId) && !boss.isDefeated { realm.delete(boss); break }
            realm.delete(event)
        }
    }
}
