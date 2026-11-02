import SwiftUI
import RealmSwift
import PhotosUI

struct ProfileView: View {
    @ObservedResults(User.self) var users
    @State private var name = ""
    @State private var phone = ""
    @State private var newKey = ""
    @State private var newValue = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showLevelUp = false

    var user: User? {
        users.first
    }

    var body: some View {
        NavigationStack {
            List {
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
                if let user = user {
                    Section("Уровень и баланс") {
                        Text("Уровень: " + String(user.level))
                        Text("Песеты: " + String(user.pesetas) + " P")
                        Text("XP: " + String(user.xp) + " / " + String(User.xpForNextLevel(user.level)))
                        ProgressView(value: Double(user.xp), total: Double(max(User.xpForNextLevel(user.level), 1)))
                        Button("Добавить 100 XP (тест)") {
                            addXP(100)
                        }
                    }
                    Section("Кастомные поля") {
                        ForEach(user.customFields, id: .key) { field in
                            HStack {
                                Text(field.key)
                                Spacer()
                                Text(field.value)
                            }
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
            }
            .navigationTitle("Профиль")
            .onAppear {
                ensureUser()
                name = user?.name ?? ""
                phone = user?.phone ?? ""
            }
            .onChange(of: selectedPhoto) { _, item in
                loadAvatar(from: item)
            }
            .alert("Новый уровень!", isPresented: $showLevelUp) {
                Button("OK", role: .cancel) {}
            }
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
                    .overlay(Text(String(name.prefix(1))).foregroundStyle(.white).font(.title))
            }
        }
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
        }
    }

    func addXP(_ amount: Int) {
        guard let realm = try? Realm(), let user = user else { return }
        var leveledUp = false
        try? realm.write {
            user.xp += amount
            while user.xp >= User.xpForNextLevel(user.level) {
                user.xp -= User.xpForNextLevel(user.level)
                user.level += 1
                leveledUp = true
            }
        }
        if leveledUp {
            showLevelUp = true
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

    func loadAvatar(from item: PhotosPickerItem?) {
        guard let item = item else { return }
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self) else { return }
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("avatar.jpg")
            guard let url = url else { return }
            try? data.write(to: url)
            guard let realm = try? Realm(), let user = user else { return }
            try? realm.write {
                user.avatarPath = url.path
            }
        }
    }
}
