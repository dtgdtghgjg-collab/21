import SwiftUI
import RealmSwift
import PhotosUI

struct ProfileView: View {
    @ObservedResults(User.self) var users
    @State private var name = ""
    @State private var phone = ""
    @State private var about = ""
    @State private var goals = ""
    @State private var interests = ""
    @State private var newKey = ""
    @State private var newValue = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showLevelUp = false
    @EnvironmentObject var theme: AppTheme
    @State private var selectedWallpaper: PhotosPickerItem?

    var user: User? {
        users.first
    }
    var xpText: String {
        guard let user = user else { return "" }
        return "XP: \(user.xp) / \(User.xpForNextLevel(user.level))"
    }
    var xpProgressTotal: Double {
        guard let user = user else { return 1 }
        return Double(max(User.xpForNextLevel(user.level), 1))
    }

    var body: some View {
        NavigationStack {
            SwiftUI.List {
                headerSection
                linksSection
                appearanceSection
                if let user = user {
                    levelBalanceSection(user)
                    loanSection(user)
                    profileDetailsSection
                    customFieldsSection(user)
                }
            }
            .navigationTitle("Профиль")
            .onAppear {
                ensureUser()
                checkDebt()
                name = user?.name ?? ""
                phone = user?.phone ?? ""
                about = user?.aboutText ?? ""
                goals = user?.goalsText ?? ""
                interests = user?.interestsText ?? ""
            }
            .onChange(of: selectedPhoto) { _, item in
                loadAvatar(from: item)
            }
            .onChange(of: selectedWallpaper) { _, item in
                loadWallpaper(from: item)
            }
            .alert("Новый уровень!", isPresented: $showLevelUp) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    @ViewBuilder
    private var headerSection: some View {
        Section {
            HStack {
                avatarView
                VStack(alignment: .leading) {
                    TextField("Имя", text: $name)
                    TextField("Телефон", text: $phone)
                }
            }
            Button("Сохранить профиль") {
                saveProfile()
            }
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Text("Выбрать аватар")
            }
        }
    }

    @ViewBuilder
    private var appearanceSection: some View {
        Section("Оформление") {
            Toggle("Тёмная тема", isOn: Binding(get: { theme.isDark }, set: { theme.isDark = $0 }))
            Picker("Акцент", selection: Binding(get: { theme.accentName }, set: { theme.accentName = $0 })) {
                Text("Синий").tag("blue")
                Text("Красный").tag("red")
                Text("Зелёный").tag("green")
                Text("Фиолетовый").tag("purple")
                Text("Оранжевый").tag("orange")
            }
            PhotosPicker(selection: $selectedWallpaper, matching: .images) {
                Text(theme.wallpaperPath.isEmpty ? "Выбрать обои" : "Сменить обои")
            }
            Toggle("Обои на всех экранах", isOn: Binding(get: { theme.wallpaperAllScreens }, set: { theme.wallpaperAllScreens = $0 }))
            if !theme.wallpaperPath.isEmpty {
                Button("Убрать обои") { theme.wallpaperPath = "" }
            }
        }
    }

    @ViewBuilder
    private func levelBalanceSection(_ user: User) -> some View {
        Section("Уровень и баланс") {
            Text("Уровень: \(user.level)")
            Text("Песеты: \(user.pesetas) P")
            Text(xpText)
            ProgressView(value: Double(user.xp), total: xpProgressTotal)
            if user.pesetas < 0 {
                Text("ДОЛГ: баланс ниже нуля").foregroundStyle(.red)
                Text(debtRemainingText(user)).foregroundStyle(.red)
                Text(debtInsuranceText(user)).font(.caption)
            }
        }
    }

    private func debtInsuranceText(_ user: User) -> String {
        user.inventory.contains(where: { $0.uniqueFeature == "death_insurance" }) ? "Страховка от смерти: есть, отменит один вайп" : "Страховки от смерти нет"
    }

    @ViewBuilder
    private func loanSection(_ user: User) -> some View {
        Section("Заём") {
            if user.loanAmount > 0 {
                Text("Активный заём: \(user.loanAmount) P к возврату")
                if let due = user.loanDueDate { Text("Срок возврата: \(due.formatted(date: .abbreviated, time: .omitted))") }
                Button("Вернуть заём") { repayLoan() }.disabled(user.pesetas < user.loanAmount)
            } else {
                if user.level < 5 { Text("Заём открывается с 5 уровня") } else { Text("500 P сейчас, вернуть 550 P через 7 дней"); Button("Взять в долг 500 P") { takeLoan() } }
            }
        }
    }

    @ViewBuilder
    private func customFieldsSection(_ user: User) -> some View {
        Section("Кастомные поля") {
            ForEach(user.customFields, id: \.key) { field in
                fieldRow(field)
            }
            .onDelete { indexSet in
                deleteFields(at: indexSet)
            }
            HStack {
                TextField("Ключ", text: $newKey)
                TextField("Значение", text: $newValue)
                Button("Добавить") {
                    addCustomField()
                }
                .disabled(newKey.isEmpty)
            }
        }
    }

    private func fieldRow(_ field: KeyValue) -> some View {
        HStack {
            Text(field.key)
            Spacer()
            Text(field.value)
        }
    }

    @ViewBuilder
    private var linksSection: some View {
        Section("Характеристики и навыки") {
            NavigationLink("Характеристики и навыки") {
                StatsSkillsView()
            }
        }
        Section("История") {
            NavigationLink("История и активность") {
                ActivityView()
            }
        }
        Section("Достижения") {
            NavigationLink("Достижения") {
                AchievementsView()
            }
        }
        Section("Музыка") {
            NavigationLink("Музыка для вкладок") {
                MusicSettingsView()
            }
        }
        Section("Разработчик") {
            NavigationLink("Настройки разработчика") {
                DeveloperSettingsView()
            }
        }
    }

    @ViewBuilder
    private var profileDetailsSection: some View {
        Section("Полный профиль") {
            TextField("О себе", text: $about)
            TextField("Цели", text: $goals)
            TextField("Интересы", text: $interests)
            Button("Сохранить подробности") { saveProfile() }
        }
    }

    var avatarView: some View {
        Group {
            if let user = user, !user.avatarPath.isEmpty, let uiImage = UIImage(contentsOfFile: user.avatarPath) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 64, height: 64)
                    .overlay(Text("\(name.prefix(1))").foregroundStyle(.white).font(.title))
            }
        }
    }

    func checkDebt() {
        _ = DebtService.evaluate()
        name = users.first?.name ?? ""
        phone = users.first?.phone ?? ""
    }
    func takeLoan() {
        guard let realm = try? Realm(), let user = user, user.loanAmount == 0, user.level >= 5 else { return }
        try? realm.write { user.pesetas += 500; user.loanAmount = 550; user.loanDueDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) }
    }
    func repayLoan() {
        guard let realm = try? Realm(), let user = user, user.pesetas >= user.loanAmount else { return }
        try? realm.write { user.pesetas -= user.loanAmount; user.loanAmount = 0; user.loanDueDate = nil }
    }
    func debtRemainingText(_ user: User) -> String {
        guard let seconds = DebtService.remainingSeconds(for: user) else { return "" }
        let hours: Int = seconds / 3600
        let minutes: Int = (seconds % 3600) / 60
        let secs: Int = seconds % 60
        return "До вайпа: \(hours) ч \(minutes) мин \(secs) с"
    }

    func ensureUser() {
        guard let realm = try? Realm() else { return }
        if realm.objects(User.self).isEmpty {
            try? realm.write {
                realm.add(User())
            }
        }
    }

    func saveProfile() {
        guard let realm = try? Realm(), let user = user else { return }
        try? realm.write {
            user.name = name
            user.phone = phone
            user.aboutText = about
            user.goalsText = goals
            user.interestsText = interests
        }
    }



    func addCustomField() {
        guard let realm = try? Realm(), let user = user else { return }
        let field = KeyValue()
        field.key = newKey
        field.value = newValue
        try? realm.write {
            user.customFields.append(field)
        }
        newKey = ""
        newValue = ""
    }

    func deleteFields(at offsets: IndexSet) {
        guard let realm = try? Realm(), let user = user else { return }
        try? realm.write {
            user.customFields.remove(atOffsets: offsets)
        }
    }

    func loadWallpaper(from item: PhotosPickerItem?) {
        guard let item = item else { return }
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self) else { return }
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("wallpaper.jpg")
            guard let url = url else { return }
            try? data.write(to: url)
            theme.wallpaperPath = url.path
        }
    }
    func loadAvatar(from item: PhotosPickerItem?) {
        guard let item = item else { return }
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self) else { return }
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("avatar.jpg")
            guard let url = url else { return }
            try? data.write(to: url)
            guard let realm = try? await Realm(), let user = user else { return }
            try? realm.write {
                user.avatarPath = url.path
            }
        }
    }
}
