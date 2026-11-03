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
                                        Text("\(Calendar.current.component(.day, from: day))").font(.body)
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
                            Text("Работа").tag("work")
                            Text("Собеседование").tag("interview")
                            Text("Выступление").tag("presentation")
                            Text("Поездка").tag("trip")
                            Text("Здоровье").tag("health")
                            Text("Учёба").tag("study")
                            Text("Свадьба").tag("wedding")
                            Text("День рождения").tag("birthday")
                            Text("Выпускной").tag("graduation")
                            Text("Концерт").tag("concert")
                            Text("Театр").tag("theater")
                            Text("Кино").tag("cinema")
                            Text("Музей").tag("museum")
                            Text("Выставка").tag("exhibition")
                            Text("Конференция").tag("conference")
                            Text("Хакатон").tag("hackathon")
                            Text("Марафон").tag("marathon")
                            Text("Турнир").tag("tournament")
                            Text("Соревнование").tag("competition")
                            Text("Прослушивание").tag("audition")
                            Text("Репетиция").tag("rehearsal")
                            Text("Запись").tag("recording")
                            Text("Фотосессия").tag("photoshoot")
                            Text("Вечеринка").tag("party")
                            Text("Пикник").tag("picnic")
                            Text("Поход").tag("camping")
                            Text("Рыбалка").tag("fishing")
                            Text("Охота").tag("hunting")
                            Text("Садоводство").tag("gardening")
                            Text("Готовка").tag("cooking")
                            Text("Выпечка").tag("baking")
                            Text("Уборка").tag("cleaning")
                            Text("Переезд").tag("moving")
                            Text("Ремонт").tag("repair")
                            Text("Покупки").tag("shopping")
                            Text("Распродажа").tag("sale")
                            Text("Аукцион").tag("auction")
                            Text("Лотерея").tag("lottery")
                            Text("Азартная игра").tag("gambling")
                            Text("Инвестиции").tag("investment")
                            Text("Бизнес-встреча").tag("business")
                            Text("Стартап").tag("startup")
                            Text("Питч").tag("pitch")
                            Text("Нетворкинг").tag("networking")
                            Text("Наставничество").tag("mentoring")
                            Text("Волонтёрство").tag("volunteering")
                            Text("Благотворительность").tag("charity")
                            Text("Пожертвование").tag("donation")
                            Text("Религиозный обряд").tag("religion")
                            Text("Медитация").tag("meditation")
                            Text("Йога").tag("yoga")
                            Text("Тренировка в зале").tag("gym")
                            Text("Плавание").tag("swimming")
                            Text("Велопрогулка").tag("cycling")
                            Text("Бег").tag("running")
                            Text("Скалолазание").tag("climbing")
                            Text("Лыжи").tag("skiing")
                            Text("Сёрфинг").tag("surfing")
                            Text("Дайвинг").tag("diving")
                            Text("Полёт").tag("flying")
                            Text("Вождение").tag("driving")
                            Text("Контрольная").tag("quiz")
                            Text("Домашка").tag("homework")
                            Text("Лекция").tag("lecture")
                            Text("Семинар").tag("seminar")
                            Text("Мастер-класс").tag("workshop")
                            Text("Курс").tag("course")
                            Text("Изучение языка").tag("language")
                            Text("Чтение").tag("reading")
                            Text("Писательство").tag("writing")
                            Text("Рисование").tag("drawing")
                            Text("Музыка").tag("music")
                            Text("Танцы").tag("dance")
                            Text("Пение").tag("singing")
                            Text("Актёрство").tag("acting")
                            Text("Фотография").tag("photography")
                            Text("Видеосъёмка").tag("videography")
                            Text("Игровой турнир").tag("gaming")
                            Text("Стрим").tag("streaming")
                            Text("Блог").tag("blogging")
                            Text("Подкаст").tag("podcast")
                            Text("Ярмарка вакансий").tag("jobfair")
                            Text("Повышение").tag("promotion")
                            Text("Увольнение").tag("dismissal")
                            Text("Выход на пенсию").tag("retirement")
                            Text("Годовщина").tag("anniversary")
                            Text("Встреча выпускников").tag("reunion")
                            Text("Семейный ужин").tag("family")
                            Text("Встреча друзей").tag("friends")
                            Text("Соседи").tag("neighbor")
                            Text("Питомец").tag("pet")
                            Text("Приём у врача").tag("doctor")
                            Text("Фестиваль").tag("festival")
                            Text("Своё").tag("custom")
                        }
                        Stepper("Порог тревоги: \(newThreshold) дн.", value: $newThreshold, in: 1...30)
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
        return "через \(left) дн."
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
                Text("\(countdownText(event)) · \(event.type)").font(.caption).foregroundStyle(.secondary)
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
            let bossDefs: [String: (String, String)] = ["exam": ("Призрак сессии", "C"),
                "deadline": ("Пожиратель сроков", "D"),
                "fight": ("Дух агрессии", "B"),
                "sport": ("Тень лени", "D"),
                "date": ("Демон неловкости", "E"),
                "holiday": ("Дух веселья", "E"),
                "work": ("Начальник-надзиратель", "B"),
                "interview": ("Судья собеседования", "C"),
                "presentation": ("Страх сцены", "C"),
                "trip": ("Дух дороги", "D"),
                "health": ("Вирус слабости", "D"),
                "study": ("Хранитель учебников", "C"),
                "wedding": ("Дух клятв", "B"),
                "birthday": ("Торт-монстр", "D"),
                "graduation": ("Призрак диплома", "C"),
                "concert": ("Громовой рокер", "B"),
                "theater": ("Маска трагедии", "C"),
                "cinema": ("Проектор кошмаров", "D"),
                "museum": ("Страж экспонатов", "C"),
                "exhibition": ("Куратор теней", "D"),
                "conference": ("Докладчик-вампир", "C"),
                "hackathon": ("Баг-монстр", "B"),
                "marathon": ("Бегущий призрак", "C"),
                "tournament": ("Чемпион арены", "B"),
                "competition": ("Судья строгости", "C"),
                "audition": ("Критик безжалостный", "C"),
                "rehearsal": ("Двойник сцены", "D"),
                "recording": ("Эхо студии", "D"),
                "photoshoot": ("Вспышка тьмы", "E"),
                "party": ("Король танцпола", "D"),
                "picnic": ("Муравьиный король", "E"),
                "camping": ("Лесной дух", "C"),
                "fishing": ("Глубинный монстр", "D"),
                "hunting": ("Тень леса", "C"),
                "gardening": ("Сорняк-гигант", "E"),
                "cooking": ("Шеф-демон", "D"),
                "baking": ("Дух духовки", "E"),
                "cleaning": ("Пыльный голем", "E"),
                "moving": ("Коробочный голем", "D"),
                "repair": ("Ржавый голем", "D"),
                "shopping": ("Кошельковый вор", "E"),
                "sale": ("Ажиотажный демон", "D"),
                "auction": ("Молот судьбы", "C"),
                "lottery": ("Фортуна капризная", "B"),
                "gambling": ("Карточный шулер", "C"),
                "investment": ("Бык и медведь", "B"),
                "business": ("Акула переговоров", "B"),
                "startup": ("Единорог-иллюзия", "A"),
                "pitch": ("Инвестор-скептик", "C"),
                "networking": ("Паук связей", "D"),
                "mentoring": ("Мудрец строгий", "C"),
                "volunteering": ("Ангел помощи", "E"),
                "charity": ("Золотой страж", "D"),
                "donation": ("Щедрый призрак", "E"),
                "religion": ("Хранитель храма", "C"),
                "meditation": ("Внутренний демон", "B"),
                "yoga": ("Мастер позы", "D"),
                "gym": ("Железный титан", "C"),
                "swimming": ("Водяной дух", "C"),
                "cycling": ("Ветряной всадник", "D"),
                "running": ("Спринтер тени", "D"),
                "climbing": ("Каменный страж", "C"),
                "skiing": ("Снежный король", "B"),
                "surfing": ("Волна-гигант", "B"),
                "diving": ("Глубинный страж", "B"),
                "flying": ("Небесный дракон", "A"),
                "driving": ("Дорожный демон", "C"),
                "quiz": ("Дух контрольной", "D"),
                "homework": ("Гора тетрадей", "E"),
                "lecture": ("Профессор-монстр", "C"),
                "seminar": ("Дискуссант-тролль", "D"),
                "workshop": ("Мастер-ремесленник", "C"),
                "course": ("Хранитель знаний", "C"),
                "language": ("Полиглот-призрак", "D"),
                "reading": ("Книжный червь-гигант", "E"),
                "writing": ("Муза капризная", "C"),
                "drawing": ("Холст-портал", "D"),
                "music": ("Нотный демон", "D"),
                "dance": ("Ритм-страж", "D"),
                "singing": ("Сирена сцены", "C"),
                "acting": ("Лицедей-оборотень", "B"),
                "photography": ("Объектив-всевидящий", "D"),
                "videography": ("Кадр-ловушка", "D"),
                "gaming": ("Финальный босс игры", "A"),
                "streaming": ("Чат-тролль", "D"),
                "blogging": ("Алгоритм-монстр", "C"),
                "podcast": ("Голос из эфира", "D"),
                "jobfair": ("Рекрутер-охотник", "C"),
                "promotion": ("Лестница карьеры", "B"),
                "dismissal": ("Бумажный дракон", "B"),
                "retirement": ("Хранитель времени", "A"),
                "anniversary": ("Хранитель воспоминаний", "D"),
                "reunion": ("Призрак прошлого", "C"),
                "family": ("Глава семьи", "D"),
                "friends": ("Ностальгия-монстр", "E"),
                "neighbor": ("Шумный сосед", "E"),
                "pet": ("Пушистый тиран", "E"),
                "doctor": ("Диагноз-призрак", "C"),
                "festival": ("Фестивальный гигант", "B")]
            let bossDef = bossDefs[newType] ?? ("Дух веселья", "E")
            boss.name = bossDef.0
            boss.rank = bossDef.1
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
