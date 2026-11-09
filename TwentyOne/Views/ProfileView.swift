import SwiftUI
import RealmSwift
import PhotosUI
import UniformTypeIdentifiers

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
    @State private var wallpaperTab: Int = 0
    @State private var backupURL: URL?
    @State private var showBackupImporter = false
    @State private var backupMessage: String?
    @State private var profileTab = 0
    @State private var loanSlider: Double = 500
    @State private var loanMessage: String?

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
                if let user = user { economyBarSection(user) }
                Section {
                    Picker("Раздел профиля", selection: $profileTab) {
                        Text("Герой").tag(0)
                        Text("Характеристики").tag(1)
                        Text("Банк").tag(2)
                        Text("Настройки").tag(3)
                    }
                    .pickerStyle(.segmented)
                }
                if profileTab == 0 {
                    petSection
                    if let user = user { equippedSection(user) }
                } else if profileTab == 1 {
                    if let user = user {
                        Section { RadarChartView(attributes: Array(user.attributes)) }
                        Section("Ключевые статы") { ProfileKeyStatsView() }
                    }
                    linksSection
                } else if profileTab == 2 {
                    if let user = user {
                        levelBalanceSection(user)
                        loanSection(user)
                        Section { BankStatsView() }
                    }
                } else {
                    Section { TitlesPickerView() }
                    appearanceSection
                    if let user = user {
                        profileDetailsSection
                        customFieldsSection(user)
                    }
                    linksSection
                    backupSection
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.background(for: 0))
            .tint(TwentyOneTab.profile.theme.accent)
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
            .fileImporter(isPresented: $showBackupImporter, allowedContentTypes: [UTType(filenameExtension: "json21") ?? .json]) { result in if let url = try? result.get() { let ok = ProgressBackupService.importURL(url); backupMessage = ok ? "Прогресс импортирован" : "Не удалось импортировать прогресс"; if ok { Haptics.success(); SoundService.success() } else { Haptics.error() } } }
            .alert("Новый уровень!", isPresented: $showLevelUp) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    @ViewBuilder
    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    avatarView
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Имя", text: $name).font(.system(size: 20, weight: .bold, design: .rounded))
                        TextField("Телефон", text: $phone).font(.subheadline).foregroundStyle(.secondary)
                        if let user = user, let realm = try? Realm() { Text(TitlesService.current(user: user, realm: realm).name).font(.subheadline.weight(.semibold)).foregroundStyle(AppPalette.gold) }
                        if let user = user { HStack(spacing: 8) { StatPill(icon: "star.fill", text: "Уровень \(user.level)", color: TwentyOneTab.profile.theme.accent); StatPill(icon: "medal.fill", text: "Ранг \(HeroRank.name(for: user.level))", color: AppPalette.gold); StatPill(icon: "banknote.fill", text: "\(user.pesetas) P", color: AppPalette.gold) } }
                        if let user = user, user.loanAmount > 0 || user.pesetas < 0 { HStack(spacing: 6) { Image("debt_badge").resizable().interpolation(.none).scaledToFit().frame(width: 24, height: 24); Text("В долгу").font(.caption.weight(.bold)).foregroundStyle(.red) } }
                    }
                }
                HStack(spacing: 10) {
                    Button("Сохранить профиль") { saveProfile() }.buttonStyle(TwentyPrimaryButtonStyle(color: TwentyOneTab.profile.theme.accent))
                    PhotosPicker(selection: $selectedPhoto, matching: .images) { Text("Выбрать аватар") }
                }
            }
            .padding(.vertical, 6)
            .listRowBackground(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(TwentyOneTab.profile.theme.heroGradient).overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Color.white.opacity(0.12), lineWidth: 1)))
        }
    }

    @ViewBuilder
    private var backupSection: some View {
        Section("Прогресс") {
            Button("Экспортировать прогресс") { backupURL = ProgressBackupService.exportURL(); Haptics.tap(); SoundService.coin() }
            if let backupURL = backupURL { ShareLink(item: backupURL) { Text("Поделиться файлом прогресса") } }
            Button("Импортировать прогресс") { showBackupImporter = true }
            if let backupMessage = backupMessage { Text(backupMessage).font(.caption).foregroundStyle(.secondary) }
        }
    }

    @ViewBuilder
    private var petSection: some View {
        Section("Питомец") { PetView() }
    }

    @ViewBuilder
    private func economyBarSection(_ user: User) -> some View {
        Section {
            HStack(spacing: 8) {
                StatPill(icon: "banknote.fill", text: "\(user.pesetas) P", color: AppPalette.gold)
                StatPill(icon: "star.fill", text: "Уровень \(user.level)", color: TwentyOneTab.profile.theme.accent)
                StatPill(icon: "medal.fill", text: "Ранг \(HeroRank.name(for: user.level))", color: AppPalette.gold)
                if user.loanAmount > 0 || user.pesetas < 0 { StatPill(icon: "exclamationmark.triangle.fill", text: "В долгу", color: .red) }
            }
        }
    }

    @ViewBuilder
    private func equippedSection(_ user: User) -> some View {
        Section("Экипировка") {
            if user.equipped.isEmpty { Text("Ничего не экипировано").font(.caption).foregroundStyle(.secondary) }
            else { ForEach(user.equipped, id: \.id) { item in HStack(spacing: 8) { RankBadge(rank: item.rank); Text(item.name); Spacer(); Text(item.slot).font(.caption).foregroundStyle(.secondary) } } }
        }
    }

    @ViewBuilder
    private var appearanceSection: some View {
        Section("Оформление") {
            Toggle("Тёмная тема", isOn: Binding(get: { theme.isDark }, set: { theme.isDark = $0 }))
            Toggle("Свайпы между вкладками", isOn: Binding(get: { theme.swipeEnabled }, set: { theme.swipeEnabled = $0 }))
            Toggle("Свайпы по кругу", isOn: Binding(get: { theme.swipeCyclic }, set: { theme.swipeCyclic = $0 })).disabled(!theme.swipeEnabled)
            Toggle("Звуки интерфейса", isOn: Binding(get: { SoundService.enabled }, set: { UserDefaults.standard.set($0, forKey: "soundsEnabled") }))
            Picker("Иконка приложения", selection: Binding(get: { AppIconService.currentName }, set: { AppIconService.setIcon($0) })) { Text("Стандартная").tag("default"); Text("Золотая").tag("AppIcon-Gold"); Text("Фиолетовая").tag("AppIcon-Purple"); Text("Чёрная").tag("AppIcon-Black") }
            Picker("Вкладка для обоев", selection: $wallpaperTab) {
                Text("Профиль").tag(0)
                Text("Дейлики").tag(1)
                Text("Календарь").tag(2)
                Text("Предметы").tag(3)
                Text("Боссы").tag(4)
            }
            Text("Встроенные обои").font(.caption).foregroundStyle(.secondary)
            ForEach(AppTheme.bundledWallpapers, id: \.self) { name in
                Button(name) { theme.setWallpaper("bundled:" + name, for: wallpaperTab) }
            }
            PhotosPicker(selection: $selectedWallpaper, matching: .images) {
                Text(theme.wallpaperPath(for: wallpaperTab).isEmpty ? "Выбрать обои" : "Сменить обои")
            }
            Toggle("Обои на всех экранах", isOn: Binding(get: { theme.wallpaperAllScreens }, set: { theme.wallpaperAllScreens = $0 }))
            if !theme.wallpaperPath(for: wallpaperTab).isEmpty {
                Button("Убрать обои") { theme.clearWallpaper(for: wallpaperTab) }
            }
        }
    }

    @ViewBuilder
    private func levelBalanceSection(_ user: User) -> some View {
        Section("Уровень и баланс") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    StatPill(icon: "star.fill", text: "Уровень \(user.level)", color: TwentyOneTab.profile.theme.accent)
                    StatPill(icon: "banknote.fill", text: "\(user.pesetas) P", color: AppPalette.gold)
                }
                Text(xpText).font(.caption).foregroundStyle(.secondary)
                GradientProgressBar(value: Double(user.xp), total: xpProgressTotal, color: TwentyOneTab.profile.theme.accent)
                if user.pesetas < 0 {
                    Text("ДОЛГ: баланс ниже нуля").font(.headline).foregroundStyle(.red)
                    Text(debtRemainingText(user)).foregroundStyle(.red)
                    Text(debtInsuranceText(user)).font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
            .listRowBackground(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(TwentyOneTab.profile.theme.card.opacity(0.92)))
        }
    }

    private func debtInsuranceText(_ user: User) -> String {
        user.inventory.contains(where: { $0.uniqueFeature == "death_insurance" }) ? "Страховка от смерти: есть, отменит один вайп" : "Страховки от смерти нет"
    }

    @ViewBuilder
    private func loanSection(_ user: User) -> some View {
        Section("Заём") {
            if user.loanAmount > 0 {
                Text("Активный заём: взято \(user.loanPrincipal) P, к возврату \(user.loanAmount) P")
                if let due = user.loanDueDate { Text("Срок возврата: \(due.formatted(date: .abbreviated, time: .omitted))") }
                Button("Вернуть заём") { repayLoan() }.disabled(user.pesetas < user.loanAmount)
            } else if user.level < 5 {
                Text("Заём открывается с 5 уровня")
            } else {
                let maxLoan = HeroRank.maxLoan(for: user.level)
                Text("Вы берете в долг \(Int(loanSlider)) песет. Максимум для вашего ранга: \(maxLoan)")
                Slider(value: $loanSlider, in: 100...Double(max(maxLoan, 100)), step: 50)
                Text("Вернуть через \(HeroRank.loanTermDays) дней: \(HeroRank.repayAmount(for: Int(loanSlider))) P (+\(HeroRank.interestPercent)%)").font(.caption).foregroundStyle(.secondary)
                Button("Взять в долг \(Int(loanSlider)) P") { takeLoan(amount: Int(loanSlider)) }
                if let loanMessage = loanMessage { Text(loanMessage).font(.caption).foregroundStyle(.secondary) }
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
                    .frame(width: 76, height: 76)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(StreakRewardService.frameUnlocked ? AppPalette.gold : Color.white.opacity(0.30), lineWidth: StreakRewardService.frameUnlocked ? 4 : 2))
            } else {
                Circle()
                    .fill(TwentyOneTab.profile.theme.accentGradient)
                    .frame(width: 76, height: 76)
                    .overlay(Text("\(name.prefix(1))").foregroundStyle(.white).font(.system(size: 30, weight: .bold, design: .rounded)))
                    .overlay(Circle().strokeBorder(StreakRewardService.frameUnlocked ? AppPalette.gold : Color.white.opacity(0.30), lineWidth: StreakRewardService.frameUnlocked ? 4 : 2))
            }
        }
        .shadow(color: Color.black.opacity(0.30), radius: 10, x: 0, y: 5)
        .overlay(alignment: .topTrailing) { if let user = user, user.loanAmount > 0 || user.pesetas < 0 { Image("debt_badge").resizable().interpolation(.none).scaledToFit().frame(width: 28, height: 28).offset(x: 6, y: -6) } }
    }

    func checkDebt() {
        _ = DebtService.evaluate()
        name = users.first?.name ?? ""
        phone = users.first?.phone ?? ""
    }
    func takeLoan(amount: Int) {
        guard let current = user, current.loanAmount == 0, current.level >= 5 else { return }
        let principal = min(max(amount, 100), HeroRank.maxLoan(for: current.level))
        let repay = HeroRank.repayAmount(for: principal)
        let userId = current.id
        RealmStore.write { realm in
            guard let live = realm.object(ofType: User.self, forPrimaryKey: userId), live.loanAmount == 0, live.level >= 5 else { return }
            live.pesetas += principal; live.loanPrincipal = principal; live.loanAmount = repay; live.loanTakenAt = Date(); live.loanDueDate = Calendar.current.date(byAdding: .day, value: HeroRank.loanTermDays, to: Date())
        }
        HistoryService.log("loan_taken", "Взят заём: \(principal) P, вернуть \(repay) P", pesetas: principal)
        loanMessage = "Взято \(principal) P, вернуть \(repay) P"
        Haptics.success(); SoundService.coin()
    }
    func takeLoan() { takeLoan(amount: 500) }
    func repayLoan() {
        guard let current = user, current.pesetas >= current.loanAmount else { return }
        let userId = current.id
        RealmStore.write { realm in
            guard let live = realm.object(ofType: User.self, forPrimaryKey: userId), live.pesetas >= live.loanAmount else { return }
            live.pesetas -= live.loanAmount; live.loanAmount = 0; live.loanDueDate = nil
        }
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
        guard let userId = user?.id else { return }
        let newName = name; let newPhone = phone; let newAbout = about; let newGoals = goals; let newInterests = interests
        RealmStore.write { realm in
            guard let live = realm.object(ofType: User.self, forPrimaryKey: userId) else { return }
            live.name = newName; live.phone = newPhone; live.aboutText = newAbout; live.goalsText = newGoals; live.interestsText = newInterests
        }
    }



    func addCustomField() {
        guard let userId = user?.id else { return }
        let fieldKey = newKey
        let fieldValue = newValue
        RealmStore.write { realm in
            guard let live = realm.object(ofType: User.self, forPrimaryKey: userId) else { return }
            let field = KeyValue()
            field.key = fieldKey
            field.value = fieldValue
            live.customFields.append(field)
        }
        newKey = ""
        newValue = ""
    }

    func deleteFields(at offsets: IndexSet) {
        guard let userId = user?.id else { return }
        RealmStore.write { realm in
            guard let live = realm.object(ofType: User.self, forPrimaryKey: userId) else { return }
            for index in offsets.sorted().reversed() { if index < live.customFields.count { live.customFields.remove(at: index) } }
        }
    }

    func loadWallpaper(from item: PhotosPickerItem?) {
        guard let item = item else { return }
        let tab = wallpaperTab
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self) else { return }
            let fileName = "wallpaper_tab" + String(tab) + "_" + String(Int(Date().timeIntervalSince1970)) + ".jpg"
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName)
            guard let url = url else { return }
            try? data.write(to: url)
            let path = url.path
            await MainActor.run { theme.setWallpaper(path, for: tab); theme.wallpaperPath = path }
        }
    }
    func loadAvatar(from item: PhotosPickerItem?) {
        guard let item = item, let userId = user?.id else { return }
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self) else { return }
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("avatar.jpg")
            guard let url = url else { return }
            try? data.write(to: url)
            let path = url.path
            await MainActor.run { RealmStore.write { realm in realm.object(ofType: User.self, forPrimaryKey: userId)?.avatarPath = path } }
        }
    }
}
