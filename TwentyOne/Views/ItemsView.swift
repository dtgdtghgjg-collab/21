import SwiftUI
import RealmSwift
import UniformTypeIdentifiers

let rankMultipliers: [String: Double] = ["F": 1, "E": 2, "D": 4, "C": 8, "B": 16, "A": 32, "S": 64, "SS": 128, "SSS": 256, "R": 512]

let rankBasePrices: [String: Int] = ["F": 4000, "E": 8000, "D": 15000, "C": 30000, "B": 60000, "A": 120000, "S": 250000, "SS": 500000, "SSS": 900000, "R": 2000000]

struct CatalogItem: Identifiable {
    let id: String
    let name: String
    let rank: String
    let desc: String
    let slot: String
    let statName: String
    let statPoints: Int
    var isPinpoon: Bool = false
    var uniqueFeature: String = ""
    var priceMultiplier: Double = 1.0
    var imageName: String { "item_" + id }
    var pricePesetas: Int {
        let base: Double = Double(rankBasePrices[rank] ?? 4000)
        let extraPoints: Double = Double(max(statPoints - 1, 0))
        let statFactor: Double = 1.0 + 0.2 * extraPoints
        let pinpoonFactor: Double = isPinpoon ? 4.0 : 1.0
        let total: Double = base * statFactor * pinpoonFactor * priceMultiplier
        return Int(total)
    }
    var priceXp: Int { pricePesetas / 5 }
}

let regularCatalog: [CatalogItem] = [
    CatalogItem(id: "reg-notebook", name: "Потрепанный блокнот", rank: "F", desc: "Для заметок — как у Лайта из «Тетради смерти»", slot: "Аксессуар", statName: "Интеллект", statPoints: 1),
    CatalogItem(id: "reg-mug", name: "Кружка кофе", rank: "F", desc: "Бодрит", slot: "Аксессуар", statName: "Скорость мышления", statPoints: 1),
    CatalogItem(id: "reg-textbook", name: "Учебник логики", rank: "E", desc: "Основы логики", slot: "Инструмент", statName: "Логика", statPoints: 2),
    CatalogItem(id: "reg-sneakers", name: "Спортивные кроссовки", rank: "E", desc: "Быстрые ноги", slot: "Тело", statName: "Скорость мышления", statPoints: 1),
    CatalogItem(id: "reg-helmet", name: "Шлем сосредоточения", rank: "D", desc: "Фокус", slot: "Голова", statName: "Интеллект", statPoints: 2),
    CatalogItem(id: "reg-cloak", name: "Плащ отличника", rank: "D", desc: "Для отличников", slot: "Тело", statName: "Критическое мышление", statPoints: 2),
    CatalogItem(id: "reg-sword", name: "Меч дедлайнов", rank: "C", desc: "Режет сроки", slot: "Инструмент", statName: "Логика", statPoints: 3),
    CatalogItem(id: "reg-glasses", name: "Очки аналитика", rank: "C", desc: "Видят суть", slot: "Голова", statName: "Критическое мышление", statPoints: 3),
    CatalogItem(id: "reg-journal", name: "Дневник привычек", rank: "F", desc: "Трекинг каждый день", slot: "Аксессуар", statName: "Дисциплина", statPoints: 1),
    CatalogItem(id: "reg-bottle", name: "Бутылка воды", rank: "F", desc: "Пей больше воды", slot: "Аксессуар", statName: "Выносливость", statPoints: 1),
    CatalogItem(id: "reg-timer", name: "Таймер фокуса", rank: "F", desc: "25 минут работы", slot: "Инструмент", statName: "Скорость мышления", statPoints: 1),
    CatalogItem(id: "reg-plant", name: "Растение на столе", rank: "F", desc: "Живой уголок", slot: "Аксессуар", statName: "Воображение", statPoints: 1),
    CatalogItem(id: "reg-dumbbell", name: "Гантель новичка", rank: "E", desc: "Первый вес", slot: "Инструмент", statName: "Физическая сила", statPoints: 2),
    CatalogItem(id: "reg-rope", name: "Скакалка", rank: "F", desc: "Кардио и координация", slot: "Инструмент", statName: "Координация", statPoints: 1),
    CatalogItem(id: "reg-yogamat", name: "Коврик для йоги", rank: "E", desc: "Гибкость каждый день", slot: "Тело", statName: "Гибкость", statPoints: 2),
    CatalogItem(id: "reg-ball", name: "Мяч для реакции", rank: "F", desc: "Лови быстрее", slot: "Инструмент", statName: "Реакция", statPoints: 1),
    CatalogItem(id: "reg-balance", name: "Баланс-борд", rank: "D", desc: "Устойчивость", slot: "Инструмент", statName: "Баланс", statPoints: 2),
    CatalogItem(id: "reg-darts", name: "Дартс", rank: "E", desc: "Меткость", slot: "Инструмент", statName: "Точность", statPoints: 2),
    CatalogItem(id: "reg-chess", name: "Шахматы", rank: "D", desc: "Стратегия", slot: "Инструмент", statName: "Логика", statPoints: 2),
    CatalogItem(id: "reg-flashcards", name: "Карточки памяти", rank: "E", desc: "Повторение", slot: "Аксессуар", statName: "Память", statPoints: 2),
    CatalogItem(id: "reg-puzzle", name: "Пазл на 1000 деталей", rank: "D", desc: "Терпение и анализ", slot: "Аксессуар", statName: "Критическое мышление", statPoints: 2),
    CatalogItem(id: "reg-meditation", name: "Подушка для медитации", rank: "E", desc: "Спокойствие", slot: "Аксессуар", statName: "Стрессоустойчивость", statPoints: 2),
    CatalogItem(id: "reg-planner", name: "Планер на неделю", rank: "D", desc: "Порядок в делах", slot: "Аксессуар", statName: "Дисциплина", statPoints: 2),
    CatalogItem(id: "reg-motivation", name: "Постер мотивации", rank: "F", desc: "На стену", slot: "Аксессуар", statName: "Мотивация", statPoints: 1),
    CatalogItem(id: "reg-mic", name: "Микрофон для выступлений", rank: "C", desc: "Голос уверенности", slot: "Инструмент", statName: "Убеждение", statPoints: 3),
    CatalogItem(id: "reg-cardgame", name: "Настольная игра", rank: "D", desc: "Игра с друзьями", slot: "Инструмент", statName: "Нетворкинг", statPoints: 2),
    CatalogItem(id: "reg-headset", name: "Гарнитура переговорщика", rank: "C", desc: "Слушай внимательно", slot: "Голова", statName: "Слушание", statPoints: 3),
    CatalogItem(id: "reg-sketchbook", name: "Скетчбук", rank: "E", desc: "Рисуй каждый день", slot: "Аксессуар", statName: "Воображение", statPoints: 2),
    CatalogItem(id: "reg-guitar", name: "Укулеле", rank: "C", desc: "Музыка каждый вечер", slot: "Инструмент", statName: "Музыкальность", statPoints: 3),
    CatalogItem(id: "reg-pen", name: "Перьевая ручка", rank: "D", desc: "Пиши красиво", slot: "Инструмент", statName: "Писательский навык", statPoints: 2),
    CatalogItem(id: "reg-craft", name: "Набор для ремесла", rank: "D", desc: "Сделай руками", slot: "Инструмент", statName: "Ремесло", statPoints: 2),
    CatalogItem(id: "reg-paint", name: "Краски и кисти", rank: "C", desc: "Цвет и вкус", slot: "Инструмент", statName: "Художественный вкус", statPoints: 3),
    CatalogItem(id: "reg-kunai", name: "Кунай Наруто", rank: "F", desc: "Отсылка: Наруто", slot: "Инструмент", statName: "Точность", statPoints: 1),
    CatalogItem(id: "reg-ramen", name: "Рамен Ичираку", rank: "F", desc: "Отсылка: Наруто", slot: "Аксессуар", statName: "Выносливость", statPoints: 1),
    CatalogItem(id: "reg-headband", name: "Повязка Конохи", rank: "E", desc: "Отсылка: Наруто", slot: "Голова", statName: "Дисциплина", statPoints: 2),
    CatalogItem(id: "reg-rasengan", name: "Тренажёр Расенгана", rank: "D", desc: "Отсылка: Наруто", slot: "Инструмент", statName: "Взрывная сила", statPoints: 2),
    CatalogItem(id: "reg-sharingan", name: "Линзы Шарингана", rank: "C", desc: "Отсылка: Наруто", slot: "Голова", statName: "Реакция", statPoints: 3),
    CatalogItem(id: "reg-pokeball", name: "Покебол", rank: "F", desc: "Отсылка: Покемон", slot: "Аксессуар", statName: "Нетворкинг", statPoints: 1),
    CatalogItem(id: "reg-pikachu", name: "Плюшевый Пикачу", rank: "F", desc: "Отсылка: Покемон", slot: "Аксессуар", statName: "Мотивация", statPoints: 1),
    CatalogItem(id: "reg-ashcap", name: "Кепка Эша", rank: "E", desc: "Отсылка: Покемон", slot: "Голова", statName: "Скорость", statPoints: 2),
    CatalogItem(id: "reg-ocarina", name: "Окарина Линка", rank: "E", desc: "Отсылка: Зельда", slot: "Инструмент", statName: "Музыкальность", statPoints: 2),
    CatalogItem(id: "reg-triforce", name: "Кулон Трайфорс", rank: "D", desc: "Отсылка: Зельда", slot: "Аксессуар", statName: "Интуиция", statPoints: 2),
    CatalogItem(id: "reg-mario-cap", name: "Кепка Марио", rank: "F", desc: "Отсылка: Марио", slot: "Голова", statName: "Баланс", statPoints: 1),
    CatalogItem(id: "reg-mario-mushroom", name: "Гриб Марио", rank: "E", desc: "Отсылка: Марио", slot: "Аксессуар", statName: "Физическая сила", statPoints: 2),
    CatalogItem(id: "reg-sonic-shoes", name: "Кроссовки Соника", rank: "E", desc: "Отсылка: Соник", slot: "Тело", statName: "Скорость", statPoints: 1),
    CatalogItem(id: "reg-pacman", name: "Вишенка Пакмана", rank: "F", desc: "Отсылка: Пакман", slot: "Аксессуар", statName: "Реакция", statPoints: 1),
    CatalogItem(id: "reg-tetris", name: "Кубик Тетриса", rank: "E", desc: "Отсылка: Тетрис", slot: "Аксессуар", statName: "Логика", statPoints: 2),
    CatalogItem(id: "reg-minecraft-pickaxe", name: "Кирка Майнкрафта", rank: "D", desc: "Отсылка: Майнкрафт", slot: "Инструмент", statName: "Ремесло", statPoints: 2),
    CatalogItem(id: "reg-creeper", name: "Футболка Крипера", rank: "F", desc: "Отсылка: Майнкрафт", slot: "Тело", statName: "Стрессоустойчивость", statPoints: 1),
    CatalogItem(id: "reg-portal-gun", name: "Портал-ган", rank: "C", desc: "Отсылка: Portal", slot: "Инструмент", statName: "Креативность", statPoints: 3),
    CatalogItem(id: "reg-half-life", name: "Лом Гордона", rank: "D", desc: "Отсылка: Half-Life", slot: "Инструмент", statName: "Физическая сила", statPoints: 2),
    CatalogItem(id: "reg-skyrim-helmet", name: "Шлем Довакина", rank: "C", desc: "Отсылка: Скайрим", slot: "Голова", statName: "Дисциплина", statPoints: 3),
    CatalogItem(id: "reg-fallout-pipboy", name: "Пип-бой", rank: "E", desc: "Отсылка: Fallout", slot: "Аксессуар", statName: "Память", statPoints: 2),
    CatalogItem(id: "reg-witcher-medallion", name: "Медальон Ведьмака", rank: "D", desc: "Отсылка: Ведьмак", slot: "Аксессуар", statName: "Интуиция", statPoints: 2),
    CatalogItem(id: "reg-witcher-sword", name: "Меч Ведьмака", rank: "C", desc: "Отсылка: Ведьмак", slot: "Инструмент", statName: "Точность", statPoints: 3),
    CatalogItem(id: "reg-cyberdeck", name: "Кибердека", rank: "E", desc: "Отсылка: Киберпанк", slot: "Инструмент", statName: "Логика", statPoints: 2),
    CatalogItem(id: "reg-neon-jacket", name: "Неоновая куртка", rank: "D", desc: "Отсылка: Киберпанк", slot: "Тело", statName: "Пластичность", statPoints: 2),
    CatalogItem(id: "reg-matrix-glasses", name: "Очки Нео", rank: "C", desc: "Отсылка: Матрица", slot: "Голова", statName: "Критическое мышление", statPoints: 3),
    CatalogItem(id: "reg-terminator-chip", name: "Чип Терминатора", rank: "D", desc: "Отсылка: Терминатор", slot: "Голова", statName: "Скорость мышления", statPoints: 2),
    CatalogItem(id: "reg-backfuture", name: "Кеды Марти", rank: "E", desc: "Отсылка: Назад в будущее", slot: "Тело", statName: "Скорость", statPoints: 2),
    CatalogItem(id: "reg-ghost-trap", name: "Ловушка охотников", rank: "D", desc: "Отсылка: Охотники за привидениями", slot: "Инструмент", statName: "Реакция", statPoints: 2),
    CatalogItem(id: "reg-jurassic-amber", name: "Янтарь с комаром", rank: "E", desc: "Отсылка: Парк Юрского периода", slot: "Аксессуар", statName: "Память", statPoints: 2),
    CatalogItem(id: "reg-indiana-hat", name: "Шляпа Индианы", rank: "D", desc: "Отсылка: Индиана Джонс", slot: "Голова", statName: "Убеждение", statPoints: 2),
    CatalogItem(id: "reg-pirates-compass", name: "Компас Джека Воробья", rank: "E", desc: "Отсылка: Пираты Карибского моря", slot: "Аксессуар", statName: "Интуиция", statPoints: 2),
    CatalogItem(id: "reg-hogwarts-letter", name: "Письмо из Хогвартса", rank: "F", desc: "Отсылка: Гарри Поттер", slot: "Аксессуар", statName: "Воображение", statPoints: 1),
    CatalogItem(id: "reg-hermione-bag", name: "Сумка Гермионы", rank: "D", desc: "Отсылка: Гарри Поттер", slot: "Аксессуар", statName: "Логика", statPoints: 2),
    CatalogItem(id: "reg-ron-chess", name: "Шахматы Рона", rank: "D", desc: "Отсылка: Гарри Поттер", slot: "Инструмент", statName: "Логика", statPoints: 2),
    CatalogItem(id: "reg-dobby-sock", name: "Носок Добби", rank: "F", desc: "Отсылка: Гарри Поттер", slot: "Аксессуар", statName: "Эмпатия", statPoints: 1),
    CatalogItem(id: "reg-nimbus", name: "Метла Нимбус", rank: "C", desc: "Отсылка: Гарри Поттер", slot: "Инструмент", statName: "Скорость", statPoints: 3),
    CatalogItem(id: "reg-golden-snitch", name: "Золотой снитч", rank: "E", desc: "Отсылка: Гарри Поттер", slot: "Аксессуар", statName: "Реакция", statPoints: 2),
    CatalogItem(id: "reg-lotr-map", name: "Карта Средиземья", rank: "E", desc: "Отсылка: Властелин колец", slot: "Аксессуар", statName: "Память", statPoints: 2),
    CatalogItem(id: "reg-hobbit-pipe", name: "Трубка хоббита", rank: "F", desc: "Отсылка: Властелин колец", slot: "Аксессуар", statName: "Стрессоустойчивость", statPoints: 1),
    CatalogItem(id: "reg-gandalf-hat", name: "Шляпа Гэндальфа", rank: "D", desc: "Отсылка: Властелин колец", slot: "Голова", statName: "Интуиция", statPoints: 2),
    CatalogItem(id: "reg-aragorn-cloak", name: "Плащ Арагорна", rank: "D", desc: "Отсылка: Властелин колец", slot: "Тело", statName: "Выносливость", statPoints: 2),
    CatalogItem(id: "reg-legolas-bow", name: "Лук Леголаса", rank: "C", desc: "Отсылка: Властелин колец", slot: "Инструмент", statName: "Точность", statPoints: 3),
    CatalogItem(id: "reg-gimli-axe", name: "Топор Гимли", rank: "C", desc: "Отсылка: Властелин колец", slot: "Инструмент", statName: "Физическая сила", statPoints: 3),
    CatalogItem(id: "reg-frodo-ring", name: "Копия Кольца", rank: "F", desc: "Отсылка: Властелин колец", slot: "Аксессуар", statName: "Дисциплина", statPoints: 1),
    CatalogItem(id: "reg-sw-blaster", name: "Бластер Хана Соло", rank: "D", desc: "Отсылка: Звёздные войны", slot: "Инструмент", statName: "Точность", statPoints: 2),
    CatalogItem(id: "reg-sw-droid", name: "Мини-дроид R2", rank: "E", desc: "Отсылка: Звёздные войны", slot: "Аксессуар", statName: "Логика", statPoints: 2),
    CatalogItem(id: "reg-sw-robe", name: "Роба джедая", rank: "D", desc: "Отсылка: Звёздные войны", slot: "Тело", statName: "Дисциплина", statPoints: 2),
    CatalogItem(id: "reg-sw-holocron", name: "Голокрон", rank: "E", desc: "Отсылка: Звёздные войны", slot: "Аксессуар", statName: "Память", statPoints: 2),
    CatalogItem(id: "reg-marvel-shield", name: "Мини-щит Кэпа", rank: "D", desc: "Отсылка: Марвел", slot: "Тело", statName: "Выносливость", statPoints: 2),
    CatalogItem(id: "reg-marvel-web", name: "Паутина Человека-паука", rank: "E", desc: "Отсылка: Марвел", slot: "Инструмент", statName: "Координация", statPoints: 2),
    CatalogItem(id: "reg-marvel-arc", name: "Реактор Старка", rank: "C", desc: "Отсылка: Марвел", slot: "Аксессуар", statName: "Креативность", statPoints: 3),
    CatalogItem(id: "reg-bat-belt", name: "Пояс Бэтмена", rank: "D", desc: "Отсылка: DC", slot: "Аксессуар", statName: "Логика", statPoints: 2),
    CatalogItem(id: "reg-bat-batarang", name: "Бэтаранг", rank: "E", desc: "Отсылка: DC", slot: "Инструмент", statName: "Точность", statPoints: 2),
    CatalogItem(id: "reg-superman-cape", name: "Плащ Супермена", rank: "C", desc: "Отсылка: DC", slot: "Тело", statName: "Физическая сила", statPoints: 3),
    CatalogItem(id: "reg-wonder-lasso", name: "Лассо Чудо-женщины", rank: "D", desc: "Отсылка: DC", slot: "Инструмент", statName: "Убеждение", statPoints: 2),
    CatalogItem(id: "reg-attack-scout", name: "Плащ разведкорпуса", rank: "D", desc: "Отсылка: Атака титанов", slot: "Тело", statName: "Скорость", statPoints: 2),
    CatalogItem(id: "reg-eren-key", name: "Ключ Эрена", rank: "E", desc: "Отсылка: Атака титанов", slot: "Аксессуар", statName: "Память", statPoints: 2),
    CatalogItem(id: "reg-mikasa-scarf", name: "Шарф Микасы", rank: "F", desc: "Отсылка: Атака титанов", slot: "Тело", statName: "Стрессоустойчивость", statPoints: 1),
    CatalogItem(id: "reg-demon-sword", name: "Катана Тандзиро", rank: "C", desc: "Отсылка: Клинок демонов", slot: "Инструмент", statName: "Реакция", statPoints: 3),
    CatalogItem(id: "reg-nezuko-bamboo", name: "Бамбук Незуко", rank: "F", desc: "Отсылка: Клинок демонов", slot: "Аксессуар", statName: "Дисциплина", statPoints: 1),
    CatalogItem(id: "reg-onepiece-hat", name: "Соломенная шляпа Луффи", rank: "E", desc: "Отсылка: One Piece", slot: "Голова", statName: "Мотивация", statPoints: 2),
    CatalogItem(id: "reg-onepiece-map", name: "Карта Гранд Лайн", rank: "D", desc: "Отсылка: One Piece", slot: "Аксессуар", statName: "Нетворкинг", statPoints: 2),
    CatalogItem(id: "reg-bleach-zanpakuto", name: "Деревянный меч Ичиго", rank: "D", desc: "Отсылка: Блич", slot: "Инструмент", statName: "Физическая сила", statPoints: 2),
    CatalogItem(id: "reg-db-scouter", name: "Скаутер Саяна", rank: "E", desc: "Отсылка: Драгонболл", slot: "Голова", statName: "Скорость мышления", statPoints: 2),
    CatalogItem(id: "reg-db-capsule", name: "Капсула Корпорации", rank: "E", desc: "Отсылка: Драгонболл", slot: "Аксессуар", statName: "Ремесло", statPoints: 2),
    CatalogItem(id: "reg-jjk-cursed", name: "Палец Сукуны", rank: "D", desc: "Отсылка: Jujutsu Kaisen", slot: "Аксессуар", statName: "Стрессоустойчивость", statPoints: 2),
    CatalogItem(id: "reg-mha-notebook", name: "Тетрадь Деку", rank: "F", desc: "Отсылка: Моя геройская академия", slot: "Аксессуар", statName: "Мотивация", statPoints: 1),
    CatalogItem(id: "reg-sailor-brooch", name: "Брошь Сейлор Мун", rank: "E", desc: "Отсылка: Сейлор Мун", slot: "Аксессуар", statName: "Воображение", statPoints: 2),
    CatalogItem(id: "reg-ghibli-totoro", name: "Плюшевый Тоторо", rank: "F", desc: "Отсылка: Тоторо", slot: "Аксессуар", statName: "Эмпатия", statPoints: 1)
]

let blackCatalog: [CatalogItem] = [
    CatalogItem(id: "black-ring", name: "Кольцо гения", rank: "B", desc: "Редкое кольцо", slot: "Аксессуар", statName: "Интеллект", statPoints: 2),
    CatalogItem(id: "black-armor", name: "Броня сессии", rank: "B", desc: "Выдержит сессию", slot: "Тело", statName: "Логика", statPoints: 2),
    CatalogItem(id: "black-crown", name: "Корона знаний", rank: "A", desc: "Корона", slot: "Голова", statName: "Интеллект", statPoints: 3),
    CatalogItem(id: "black-blade", name: "Клинок мудрости", rank: "S", desc: "Очень редкий", slot: "Инструмент", statName: "Логика", statPoints: 4),
    CatalogItem(id: "black-orb", name: "Сфера провидца", rank: "SS", desc: "Почти легенда", slot: "Аксессуар", statName: "Критическое мышление", statPoints: 5),
    CatalogItem(id: "black-relic", name: "Реликвия 21", rank: "R", desc: "Легендарная", slot: "Голова", statName: "Интеллект", statPoints: 8),
    CatalogItem(id: "black-insurance", name: "Страховка от смерти", rank: "R", desc: "Уникальная фича death_insurance: сгорает и отменяет один вайп", slot: "Аксессуар", statName: "Интуиция", statPoints: 1),
    CatalogItem(id: "unique-death-note", name: "Тетрадь смерти", rank: "S", desc: "Как у Лайта из «Тетради смерти»: фича boss_damage_boost", slot: "Аксессуар", statName: "Критическое мышление", statPoints: 4, uniqueFeature: "boss_damage_boost"),
    CatalogItem(id: "unique-time-turner", name: "Маховик времени", rank: "A", desc: "Как у Гермионы: фича no_penalty_once_per_week", slot: "Аксессуар", statName: "Память", statPoints: 3, uniqueFeature: "no_penalty_once_per_week"),
    CatalogItem(id: "black-katana", name: "Катана самурая", rank: "S", desc: "Острый как решение", slot: "Инструмент", statName: "Точность", statPoints: 4),
    CatalogItem(id: "black-grimoire", name: "Гримуар знаний", rank: "SS", desc: "Древние знания", slot: "Инструмент", statName: "Память", statPoints: 5),
    CatalogItem(id: "black-dragon", name: "Драконья броня", rank: "S", desc: "Не пробить", slot: "Тело", statName: "Физическая сила", statPoints: 4),
    CatalogItem(id: "black-teleport", name: "Сапоги телепорта", rank: "A", desc: "Шаг сквозь день", slot: "Тело", statName: "Скорость", statPoints: 3),
    CatalogItem(id: "black-mask", name: "Маска переговорщика", rank: "A", desc: "Убеждает без слов", slot: "Голова", statName: "Убеждение", statPoints: 3),
    CatalogItem(id: "black-wand", name: "Волшебная палочка", rank: "A", desc: "Креативная магия", slot: "Инструмент", statName: "Креативность", statPoints: 3, uniqueFeature: "boss_damage_boost"),
    CatalogItem(id: "black-shield", name: "Щит стойкости", rank: "B", desc: "Держит удар", slot: "Тело", statName: "Выносливость", statPoints: 2),
    CatalogItem(id: "black-arcane", name: "Аркана Таро", rank: "SS", desc: "Предвидение", slot: "Аксессуар", statName: "Интуиция", statPoints: 5),
    CatalogItem(id: "black-vr", name: "VR-шлем будущего", rank: "B", desc: "Другой мир", slot: "Голова", statName: "Скорость мышления", statPoints: 2),
    CatalogItem(id: "black-ai", name: "Чип ИИ-помощника", rank: "S", desc: "Думает вместе с тобой", slot: "Голова", statName: "Логика", statPoints: 4),
    CatalogItem(id: "black-hourglass", name: "Песочные часы вечности", rank: "SSS", desc: "Время на твоей стороне", slot: "Аксессуар", statName: "Дисциплина", statPoints: 6),
    CatalogItem(id: "black-excalibur", name: "Экскалибур", rank: "SSS", desc: "Легендарный меч", slot: "Инструмент", statName: "Физическая сила", statPoints: 6),
    CatalogItem(id: "black-philosopher", name: "Философский камень", rank: "SS", desc: "Мудрость веков", slot: "Аксессуар", statName: "Критическое мышление", statPoints: 5),
    CatalogItem(id: "black-infinity", name: "Перчатка бесконечности", rank: "R", desc: "Сила всех камней", slot: "Аксессуар", statName: "Креативность", statPoints: 8),
    CatalogItem(id: "black-one-ring", name: "Кольцо всевластия", rank: "R", desc: "Одно кольцо", slot: "Аксессуар", statName: "Убеждение", statPoints: 8, uniqueFeature: "boss_damage_boost"),
    CatalogItem(id: "black-lightsaber", name: "Лайтсабер", rank: "S", desc: "Да пребудет с тобой сила", slot: "Инструмент", statName: "Реакция", statPoints: 4),
    CatalogItem(id: "black-mjolnir", name: "Мьёльнир", rank: "S", desc: "Отсылка: Марвел", slot: "Инструмент", statName: "Физическая сила", statPoints: 4),
    CatalogItem(id: "black-stormbreaker", name: "Секира Громовержца", rank: "SS", desc: "Отсылка: Марвел", slot: "Инструмент", statName: "Физическая сила", statPoints: 5),
    CatalogItem(id: "black-vibranium", name: "Щит из вибраниума", rank: "S", desc: "Отсылка: Марвел", slot: "Тело", statName: "Выносливость", statPoints: 4),
    CatalogItem(id: "black-ironman", name: "Костюм Железного человека", rank: "SS", desc: "Отсылка: Марвел", slot: "Тело", statName: "Креативность", statPoints: 5),
    CatalogItem(id: "black-spider-suit", name: "Костюм Человека-паука", rank: "A", desc: "Отсылка: Марвел", slot: "Тело", statName: "Координация", statPoints: 3),
    CatalogItem(id: "black-batsuit", name: "Костюм Бэтмена", rank: "A", desc: "Отсылка: DC", slot: "Тело", statName: "Логика", statPoints: 3),
    CatalogItem(id: "black-superman-suit", name: "Костюм Супермена", rank: "S", desc: "Отсылка: DC", slot: "Тело", statName: "Физическая сила", statPoints: 4),
    CatalogItem(id: "black-wonder-armor", name: "Доспех Чудо-женщины", rank: "A", desc: "Отсылка: DC", slot: "Тело", statName: "Выносливость", statPoints: 3),
    CatalogItem(id: "black-flash-ring", name: "Кольцо Флэша", rank: "A", desc: "Отсылка: DC", slot: "Аксессуар", statName: "Скорость", statPoints: 3),
    CatalogItem(id: "black-green-lantern", name: "Кольцо Зелёного Фонаря", rank: "S", desc: "Отсылка: DC", slot: "Аксессуар", statName: "Воображение", statPoints: 4),
    CatalogItem(id: "black-deathstar", name: "Мини Звезда Смерти", rank: "R", desc: "Отсылка: Звёздные войны", slot: "Аксессуар", statName: "Логика", statPoints: 8),
    CatalogItem(id: "black-millennium", name: "Сокол Тысячелетия", rank: "S", desc: "Отсылка: Звёздные войны", slot: "Инструмент", statName: "Скорость", statPoints: 4),
    CatalogItem(id: "black-yoda-saber", name: "Меч Йоды", rank: "S", desc: "Отсылка: Звёздные войны", slot: "Инструмент", statName: "Реакция", statPoints: 4),
    CatalogItem(id: "black-vader-helmet", name: "Шлем Вейдера", rank: "A", desc: "Отсылка: Звёздные войны", slot: "Голова", statName: "Дисциплина", statPoints: 3),
    CatalogItem(id: "black-force-crystal", name: "Кристалл Силы", rank: "SS", desc: "Отсылка: Звёздные войны", slot: "Аксессуар", statName: "Интуиция", statPoints: 5),
    CatalogItem(id: "black-elder-wand", name: "Бузинная палочка", rank: "SSS", desc: "Отсылка: Гарри Поттер", slot: "Инструмент", statName: "Креативность", statPoints: 6),
    CatalogItem(id: "black-invisibility", name: "Плащ-невидимка", rank: "SS", desc: "Отсылка: Гарри Поттер", slot: "Тело", statName: "Пластичность", statPoints: 5),
    CatalogItem(id: "black-resurrection", name: "Камень воскрешения", rank: "R", desc: "Отсылка: Гарри Поттер", slot: "Аксессуар", statName: "Интуиция", statPoints: 8),
    CatalogItem(id: "black-sorting", name: "Шляпа-распределитель", rank: "A", desc: "Отсылка: Гарри Поттер", slot: "Голова", statName: "Логика", statPoints: 3),
    CatalogItem(id: "black-horcrux", name: "Медальон Слизерина", rank: "S", desc: "Отсылка: Гарри Поттер", slot: "Аксессуар", statName: "Стрессоустойчивость", statPoints: 4),
    CatalogItem(id: "black-anduril", name: "Андурил", rank: "S", desc: "Отсылка: Властелин колец", slot: "Инструмент", statName: "Физическая сила", statPoints: 4),
    CatalogItem(id: "black-sting", name: "Жало Бильбо", rank: "A", desc: "Отсылка: Властелин колец", slot: "Инструмент", statName: "Точность", statPoints: 3),
    CatalogItem(id: "black-palantir", name: "Палантир", rank: "SS", desc: "Отсылка: Властелин колец", slot: "Аксессуар", statName: "Интуиция", statPoints: 5),
    CatalogItem(id: "black-mithril", name: "Кольчуга из мифрила", rank: "S", desc: "Отсылка: Властелин колец", slot: "Тело", statName: "Выносливость", statPoints: 4),
    CatalogItem(id: "black-silmaril", name: "Сильмарил", rank: "SSS", desc: "Отсылка: Властелин колец", slot: "Аксессуар", statName: "Художественный вкус", statPoints: 6),
    CatalogItem(id: "black-arkstone", name: "Аркенстон", rank: "SS", desc: "Отсылка: Властелин колец", slot: "Аксессуар", statName: "Убеждение", statPoints: 5),
    CatalogItem(id: "black-dragon-ball", name: "Драгонболл 4 звезды", rank: "A", desc: "Отсылка: Драгонболл", slot: "Аксессуар", statName: "Мотивация", statPoints: 3),
    CatalogItem(id: "black-senzu", name: "Сензу-боб", rank: "S", desc: "Отсылка: Драгонболл", slot: "Аксессуар", statName: "Выносливость", statPoints: 4),
    CatalogItem(id: "black-capsule-corp", name: "Капсула Хой-Пой", rank: "A", desc: "Отсылка: Драгонболл", slot: "Аксессуар", statName: "Ремесло", statPoints: 3),
    CatalogItem(id: "black-nimbus-cloud", name: "Летающее облако", rank: "A", desc: "Отсылка: Драгонболл", slot: "Инструмент", statName: "Скорость", statPoints: 3),
    CatalogItem(id: "black-z-sword", name: "Меч Z", rank: "S", desc: "Отсылка: Драгонболл", slot: "Инструмент", statName: "Физическая сила", statPoints: 4),
    CatalogItem(id: "black-sharingan-mangekyo", name: "Мангекё Шаринган", rank: "SS", desc: "Отсылка: Наруто", slot: "Голова", statName: "Реакция", statPoints: 5),
    CatalogItem(id: "black-rinnegan", name: "Риннеган", rank: "SSS", desc: "Отсылка: Наруто", slot: "Голова", statName: "Интуиция", statPoints: 6),
    CatalogItem(id: "black-kurama", name: "Чакра Курамы", rank: "SS", desc: "Отсылка: Наруто", slot: "Аксессуар", statName: "Взрывная сила", statPoints: 5),
    CatalogItem(id: "black-susanoo", name: "Доспех Сусаноо", rank: "S", desc: "Отсылка: Наруто", slot: "Тело", statName: "Выносливость", statPoints: 4),
    CatalogItem(id: "black-hokage-cloak", name: "Плащ Хокаге", rank: "A", desc: "Отсылка: Наруто", slot: "Тело", statName: "Лидерство", statPoints: 3),
    CatalogItem(id: "black-devil-fruit", name: "Дьявольский плод", rank: "S", desc: "Отсылка: One Piece", slot: "Аксессуар", statName: "Креативность", statPoints: 4),
    CatalogItem(id: "black-enma", name: "Энма", rank: "SS", desc: "Отсылка: One Piece", slot: "Инструмент", statName: "Точность", statPoints: 5),
    CatalogItem(id: "black-haki-armament", name: "Хаки вооружения", rank: "A", desc: "Отсылка: One Piece", slot: "Тело", statName: "Физическая сила", statPoints: 3),
    CatalogItem(id: "black-conqueror", name: "Королевская воля", rank: "S", desc: "Отсылка: One Piece", slot: "Аксессуар", statName: "Убеждение", statPoints: 4),
    CatalogItem(id: "black-nichirin", name: "Клинок Ничирин", rank: "A", desc: "Отсылка: Клинок демонов", slot: "Инструмент", statName: "Реакция", statPoints: 3),
    CatalogItem(id: "black-breath-sun", name: "Дыхание Солнца", rank: "S", desc: "Отсылка: Клинок демонов", slot: "Аксессуар", statName: "Взрывная сила", statPoints: 4),
    CatalogItem(id: "black-titan-serum", name: "Сыворотка титана", rank: "B", desc: "Отсылка: Атака титанов", slot: "Тело", statName: "Физическая сила", statPoints: 2),
    CatalogItem(id: "black-attack-blade", name: "Клинок разведкорпуса", rank: "B", desc: "Отсылка: Атака титанов", slot: "Инструмент", statName: "Точность", statPoints: 2),
    CatalogItem(id: "black-founding", name: "Титан-основатель", rank: "SSS", desc: "Отсылка: Атака титанов", slot: "Тело", statName: "Физическая сила", statPoints: 6),
    CatalogItem(id: "black-stand-arrow", name: "Стрела Стенда", rank: "A", desc: "Отсылка: JoJo", slot: "Аксессуар", statName: "Интуиция", statPoints: 3),
    CatalogItem(id: "black-gold-experience", name: "Голд Экспириенс", rank: "S", desc: "Отсылка: JoJo", slot: "Аксессуар", statName: "Креативность", statPoints: 4),
    CatalogItem(id: "black-star-platinum", name: "Стар Платинум", rank: "SS", desc: "Отсылка: JoJo", slot: "Инструмент", statName: "Скорость", statPoints: 5),
    CatalogItem(id: "black-jojo-hat", name: "Шляпа Джотаро", rank: "B", desc: "Отсылка: JoJo", slot: "Голова", statName: "Дисциплина", statPoints: 2),
    CatalogItem(id: "black-bankai", name: "Банкай Ичиго", rank: "SS", desc: "Отсылка: Блич", slot: "Инструмент", statName: "Физическая сила", statPoints: 5),
    CatalogItem(id: "black-hogyoku", name: "Хогёку", rank: "R", desc: "Отсылка: Блич", slot: "Аксессуар", statName: "Креативность", statPoints: 8),
    CatalogItem(id: "black-soul-reaper", name: "Плащ синигами", rank: "A", desc: "Отсылка: Блич", slot: "Тело", statName: "Скорость", statPoints: 3),
    CatalogItem(id: "black-cursed-energy", name: "Проклятая энергия", rank: "S", desc: "Отсылка: Jujutsu Kaisen", slot: "Аксессуар", statName: "Стрессоустойчивость", statPoints: 4),
    CatalogItem(id: "black-gojo-blindfold", name: "Повязка Годжо", rank: "SS", desc: "Отсылка: Jujutsu Kaisen", slot: "Голова", statName: "Интуиция", statPoints: 5),
    CatalogItem(id: "black-sukuna-finger", name: "Палец Сукуны", rank: "S", desc: "Отсылка: Jujutsu Kaisen", slot: "Аксессуар", statName: "Взрывная сила", statPoints: 4),
    CatalogItem(id: "black-domain", name: "Расширение территории", rank: "SSS", desc: "Отсылка: Jujutsu Kaisen", slot: "Аксессуар", statName: "Логика", statPoints: 6),
    CatalogItem(id: "black-oneforall", name: "Один за всех", rank: "SS", desc: "Отсылка: Моя геройская академия", slot: "Тело", statName: "Физическая сила", statPoints: 5),
    CatalogItem(id: "black-eraserhead", name: "Шарф Айзавы", rank: "A", desc: "Отсылка: Моя геройская академия", slot: "Тело", statName: "Реакция", statPoints: 3),
    CatalogItem(id: "black-allmight-suit", name: "Костюм Всемогущего", rank: "S", desc: "Отсылка: Моя геройская академия", slot: "Тело", statName: "Физическая сила", statPoints: 4),
    CatalogItem(id: "black-deku-gloves", name: "Перчатки Деку", rank: "A", desc: "Отсылка: Моя геройская академия", slot: "Аксессуар", statName: "Точность", statPoints: 3),
    CatalogItem(id: "black-masterball", name: "Мастер-болл", rank: "R", desc: "Отсылка: Покемон", slot: "Аксессуар", statName: "Нетворкинг", statPoints: 8),
    CatalogItem(id: "black-charizard", name: "Крыло Чаризарда", rank: "A", desc: "Отсылка: Покемон", slot: "Тело", statName: "Скорость", statPoints: 3),
    CatalogItem(id: "black-mewtwo-psychic", name: "Психика Мьюту", rank: "SS", desc: "Отсылка: Покемон", slot: "Голова", statName: "Скорость мышления", statPoints: 5),
    CatalogItem(id: "black-master-sword", name: "Мастер-меч", rank: "S", desc: "Отсылка: Зельда", slot: "Инструмент", statName: "Физическая сила", statPoints: 4),
    CatalogItem(id: "black-hylian-shield", name: "Щит Хайлиан", rank: "A", desc: "Отсылка: Зельда", slot: "Тело", statName: "Выносливость", statPoints: 3),
    CatalogItem(id: "black-triforce-power", name: "Трайфорс Силы", rank: "SSS", desc: "Отсылка: Зельда", slot: "Аксессуар", statName: "Физическая сила", statPoints: 6),
    CatalogItem(id: "black-mario-star", name: "Суперзвезда", rank: "A", desc: "Отсылка: Марио", slot: "Аксессуар", statName: "Скорость", statPoints: 3),
    CatalogItem(id: "black-netherite", name: "Незеритовая броня", rank: "S", desc: "Отсылка: Майнкрафт", slot: "Тело", statName: "Выносливость", statPoints: 4),
    CatalogItem(id: "black-ender-pearl", name: "Жемчуг Края", rank: "A", desc: "Отсылка: Майнкрафт", slot: "Аксессуар", statName: "Скорость", statPoints: 3),
    CatalogItem(id: "black-portal-cake", name: "Торт из Portal", rank: "B", desc: "Отсылка: Portal", slot: "Аксессуар", statName: "Мотивация", statPoints: 2),
    CatalogItem(id: "black-hev-suit", name: "Костюм HEV", rank: "A", desc: "Отсылка: Half-Life", slot: "Тело", statName: "Выносливость", statPoints: 3),
    CatalogItem(id: "black-dragon-soul", name: "Душа дракона", rank: "SS", desc: "Отсылка: Скайрим", slot: "Аксессуар", statName: "Креативность", statPoints: 5),
    CatalogItem(id: "black-vault-suit", name: "Костюм Убежища", rank: "B", desc: "Отсылка: Fallout", slot: "Тело", statName: "Стрессоустойчивость", statPoints: 2),
    CatalogItem(id: "black-witcher-mutation", name: "Мутация ведьмака", rank: "S", desc: "Отсылка: Ведьмак", slot: "Тело", statName: "Физическая сила", statPoints: 4),
    CatalogItem(id: "black-sandevistan", name: "Сандевистан", rank: "S", desc: "Отсылка: Киберпанк", slot: "Голова", statName: "Реакция", statPoints: 4),
    CatalogItem(id: "black-neon-katana", name: "Неоновая катана", rank: "A", desc: "Отсылка: Киберпанк", slot: "Инструмент", statName: "Точность", statPoints: 3)
]

struct ItemsView: View {
    @ObservedResults(User.self) var users
    @ObservedResults(AppSettings.self) var settingsList
    @State private var selectedTab = 0
    @State private var showImporter = false
    @State private var importMessage: String?
    @State private var exportURL: URL?
    var user: User? { users.first }
    var settings: AppSettings? { settingsList.first }
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Раздел", selection: $selectedTab) {
                    Text("Мои").tag(0)
                    Text("Рынок").tag(1)
                    Text("Черный рынок").tag(2)
                    Text("Создать").tag(3)
                }.pickerStyle(.segmented).padding(.horizontal)
                if selectedTab == 0 { inventoryView }
                else if selectedTab == 1 { marketList(isBlack: false) }
                else if selectedTab == 3 { CustomItemView() }
                else { blackMarketView }
            }
            .navigationTitle("Предметы")
            .onAppear { ensureUser(); ensureSettings(); ensureFirstItem(); ensureBlackMarketSchedule() }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [UTType(filenameExtension: "json21") ?? .json]) { result in if let url = try? result.get() { importMessage = Json21Service.importFile(url) } }
        }
    }
    var inventoryView: some View {
        SwiftUI.List {
            Section(".json21") {
                Button("Импортировать .json21") { showImporter = true }
                if let importMessage = importMessage { Text("Импортировано: " + importMessage) }
                if let exportURL = exportURL { ShareLink(item: exportURL) { Text("Поделиться экспортом") } }
            }
            Section("Лутбокс (1 раз в неделю)") {
                if lootboxAvailable() { Button("Открыть лутбокс") { openLootbox() } }
                else { Text("Уже открыт на этой неделе") }
            }
            Section("Экипировано") {
                if let user = user {
                    if user.equipped.isEmpty { Text("Ничего не экипировано").font(.caption).foregroundStyle(.secondary) }
                    ForEach(user.equipped, id: \.id) { item in Text(item.name + " (" + item.slot + ")") }
                }
            }
            Section("Мои предметы") {
                if let user = user {
                    ForEach(user.inventory, id: \.id) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name + " [" + item.rank + "]")
                            Text(item.slot + " - " + String(item.costPesetas) + " P - прочность " + String(item.durability) + "/" + String(item.maxDurability)).font(.caption).foregroundStyle(.secondary)
                            HStack {
                                Button(item.isEquipped ? "Снять" : "Экипировать") { toggleEquip(item) }
                                Button("Переработать (+" + String(recycleValue(item)) + " P)") { recycle(item) }
                                Button("Экспорт .json21") { exportURL = Json21Service.exportItemFile(item) }
                            }.font(.caption)
                        }
                    }
                }
            }
        }
    }
    func marketList(isBlack: Bool) -> some View {
        SwiftUI.List {
            ForEach(marketItems(isBlack: isBlack)) { catalog in
                VStack(alignment: .leading, spacing: 4) {
                    Text(catalog.name + " [" + catalog.rank + "]")
                    Text(catalog.slot + " - " + catalog.statName + " +" + String(catalog.statPoints)).font(.caption).foregroundStyle(.secondary)
                    Text(String(catalog.pricePesetas) + " P, " + String(catalog.priceXp) + " XP").font(.caption)
                    Button("Купить") { buy(catalog) }.disabled((user?.pesetas ?? 0) < catalog.pricePesetas)
                }
            }
        }
    }
    var blackMarketView: some View {
        Group {
            if isBlackOpen() {
                VStack(alignment: .leading) {
                    Text("Черный рынок открыт").font(.headline).padding(.horizontal)
                    marketList(isBlack: true)
                }
            } else {
                VStack(spacing: 8) {
                    Text("Черный рынок закрыт")
                    if let next = settings?.blackMarketNextDate { Text("Следующее появление: " + next.formatted(date: .abbreviated, time: .omitted)) }
                    else { Text("Расписание появится после первого запуска") }
                    Text("Появляется спорадически: раз в 2 недели - 2 месяца, открыт 3 дня").font(.caption).foregroundStyle(.secondary)
                }.padding()
            }
        }
    }
    func ensureUser() {
        guard let realm = try? Realm() else { return }
        if realm.objects(User.self).isEmpty { try? realm.write { realm.add(User()) } }
    }
    func ensureSettings() {
        guard let realm = try? Realm() else { return }
        try? realm.write {
            if realm.objects(AppSettings.self).isEmpty { realm.add(AppSettings()) }
            if let s = realm.objects(AppSettings.self).first {
                if let d = s.marketDate, !Calendar.current.isDateInToday(d) { s.marketPurchased = "" }
                s.marketDate = Date()
            }
        }
    }
    func ensureFirstItem() {
        guard let realm = try? Realm(), let user = realm.objects(User.self).first, let s = realm.objects(AppSettings.self).first else { return }
        if s.firstItemGiven { return }
        let item = Item()
        item.name = "Талисман новичка"
        item.rank = "F"
        item.itemDescription = "Декоративный талисман первого дня"
        item.slot = "Аксессуар"
        item.costPesetas = 0
        item.costXp = 0
        item.acquiredAt = Date()
        try? realm.write { user.inventory.append(item); s.firstItemGiven = true }
    }
    func ensureBlackMarketSchedule() {
        guard let realm = try? Realm(), let s = realm.objects(AppSettings.self).first else { return }
        let today = Calendar.current.startOfDay(for: Date())
        try? realm.write {
            if s.blackMarketNextDate == nil {
                s.blackMarketNextDate = Calendar.current.date(byAdding: .day, value: Int.random(in: 14...60), to: today)
            } else if let until = s.blackMarketVisibleUntil {
                if today > until {
                    s.blackMarketNextDate = Calendar.current.date(byAdding: .day, value: Int.random(in: 14...60), to: today)
                    s.blackMarketVisibleUntil = nil
                }
            } else if let next = s.blackMarketNextDate, s.blackMarketVisibleUntil == nil, today >= Calendar.current.startOfDay(for: next) {
                s.blackMarketVisibleUntil = Calendar.current.date(byAdding: .day, value: 2, to: Calendar.current.startOfDay(for: next))
            }
        }
    }
    func isBlackOpen() -> Bool {
        guard let next = settings?.blackMarketNextDate, let until = settings?.blackMarketVisibleUntil else { return false }
        let today = Date()
        return today >= next && today <= until
    }
    func isPurchased(_ catalog: CatalogItem) -> Bool {
        guard let s = settings else { return false }
        return s.marketPurchased.components(separatedBy: ",").contains(catalog.id)
    }
    func marketItems(isBlack: Bool) -> [CatalogItem] {
        let catalog = isBlack ? blackCatalog : regularCatalog
        let day = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        var result: [CatalogItem] = []
        for i in 0..<10 {
            let idx = (day * 7 + i * 5 + (isBlack ? 3 : 0)) % catalog.count
            var entry = catalog[idx]
            if (day * 31 + i * 17) % 20 == 0 { entry.isPinpoon = true }
            entry.priceMultiplier = 0.8 + Double((day * 37 + i * 53) % 221) / 100.0
            result.append(entry)
        }
        return result.filter { !isPurchased($0) }
    }
    func lootboxAvailable() -> Bool {
        guard let last = settings?.lootboxLastDate else { return true }
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: last), to: Calendar.current.startOfDay(for: Date())).day ?? 0
        return days >= 7
    }
    func rollRank(level: Int) -> String {
        let weights: [(String, Double)] = [("F", 97), ("E", 3 + Double(level) * 0.5), ("D", 0.4 + Double(level) * 0.1), ("C", 0.15), ("B", 0.07), ("A", 0.03), ("S", 0.01), ("SS", 0.005), ("SSS", 0.001), ("R", 0.0005)]
        let total = weights.reduce(0) { $0 + $1.1 }
        var r = Double.random(in: 0..<total)
        for w in weights {
            if r < w.1 { return w.0 }
            r -= w.1
        }
        return "F"
    }
    func openLootbox() {
        guard let realm = try? Realm(), let user = user, let s = realm.objects(AppSettings.self).first else { return }
        if !lootboxAvailable() { return }
        let rank = rollRank(level: user.level)
        let points: [String: Int] = ["F": 1, "E": 1, "D": 2, "C": 2, "B": 3, "A": 3, "S": 4, "SS": 5, "SSS": 6, "R": 8]
        let pts = points[rank] ?? 1
        let slot = ["Голова", "Тело", "Инструмент", "Аксессуар"].randomElement() ?? "Аксессуар"
        let statName = user.attributes.flatMap { Array($0.subAttributes) }.randomElement()?.name ?? "Логика"
        let lootBase: Double = Double(rankBasePrices[rank] ?? 500)
        let lootFactor: Double = 1.0 + 0.2 * Double(max(pts - 1, 0))
        let price: Int = Int(lootBase * lootFactor)
        let item = Item()
        item.name = "Трофей из лутбокса (" + rank + ")"
        item.rank = rank
        item.itemDescription = "Выпал из еженедельного лутбокса"
        item.slot = slot
        item.costPesetas = price
        item.costXp = price / 5
        item.statModifiers[statName] = pts
        item.acquiredAt = Date()
        try? realm.write { user.inventory.append(item); s.lootboxLastDate = Date() }
    }
    func buy(_ catalog: CatalogItem) {
        guard let realm = try? Realm(), let user = user, let s = realm.objects(AppSettings.self).first else { return }
        if user.pesetas < catalog.pricePesetas { return }
        let item = Item()
        item.name = catalog.name
        item.rank = catalog.rank
        item.itemDescription = catalog.desc
        item.slot = catalog.slot
        item.costPesetas = catalog.pricePesetas
        item.costXp = catalog.priceXp
        item.statModifiers[catalog.statName] = catalog.statPoints
        item.isIndestructible = catalog.isPinpoon
        item.uniqueFeature = catalog.uniqueFeature
        if catalog.id == "black-insurance" { item.uniqueFeature = "death_insurance" }
        item.acquiredAt = Date()
        try? realm.write {
            user.pesetas -= catalog.pricePesetas
            user.inventory.append(item)
            if s.marketPurchased.isEmpty { s.marketPurchased = catalog.id } else { s.marketPurchased += "," + catalog.id }
        }
        HistoryService.log("purchase", "Куплен предмет: " + catalog.name, pesetas: -catalog.pricePesetas)
    }
    func toggleEquip(_ item: Item) {
        guard let realm = try? Realm(), let user = user else { return }
        try? realm.write {
            if item.isEquipped {
                item.isEquipped = false
                var idx: Int? = nil
                for (i, eq) in user.equipped.enumerated() { if eq.id == item.id { idx = i; break } }
                if let idx = idx { user.equipped.remove(at: idx) }
            } else {
                for other in Array(user.equipped) where other.slot == item.slot {
                    other.isEquipped = false
                    var idx: Int? = nil
                    for (i, eq) in user.equipped.enumerated() { if eq.id == other.id { idx = i; break } }
                    if let idx = idx { user.equipped.remove(at: idx) }
                }
                item.isEquipped = true
                user.equipped.append(item)
            }
        }
    }
    func recycleValue(_ item: Item) -> Int {
        let days = Calendar.current.dateComponents([.day], from: item.acquiredAt, to: Date()).day ?? 0
        let weeks = max(0, days / 7)
        let durabilityFactor = Double(item.durability) / Double(max(item.maxDurability, 1))
        let value = Double(item.costPesetas) * 0.5 * durabilityFactor * pow(0.9, Double(weeks))
        return Int(value.rounded(.down))
    }
    func recycle(_ item: Item) {
        guard let realm = try? Realm(), let user = user else { return }
        let value = recycleValue(item)
        try? realm.write {
            user.pesetas += value
            var eIdx: Int? = nil
            for (i, eq) in user.equipped.enumerated() { if eq.id == item.id { eIdx = i; break } }
            if let eIdx = eIdx { user.equipped.remove(at: eIdx) }
            var iIdx: Int? = nil
            for (i, inv) in user.inventory.enumerated() { if inv.id == item.id { iIdx = i; break } }
            if let iIdx = iIdx { user.inventory.remove(at: iIdx) }
            realm.delete(item)
        }
    }
}
