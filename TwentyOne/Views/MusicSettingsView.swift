import SwiftUI
import RealmSwift
import UniformTypeIdentifiers

struct MusicSettingsView: View {
    @ObservedResults(AppSettings.self) var settingsList
    @State private var importingTab: Int?
    @State private var showImporter = false
    var settings: AppSettings? { settingsList.first }
    let tabNames = ["Профиль", "Дейлики", "Календарь", "Предметы", "Боссы"]
    var body: some View {
        SwiftUI.List {
            Section("Общие") {
                Toggle("Фоновая музыка", isOn: Binding(get: { settings?.musicEnabled ?? false }, set: { v in update { $0.musicEnabled = v } }))
                Toggle("Зацикливать отрезок", isOn: Binding(get: { settings?.musicLoop ?? true }, set: { v in update { $0.musicLoop = v } }))
                Text("Начало: \(Int(settings?.musicStartSeconds ?? 0)) сек")
                Slider(value: Binding(get: { settings?.musicStartSeconds ?? 0 }, set: { v in update { $0.musicStartSeconds = v } }), in: 0...300, step: 1)
                Text("Конец: \(Int(settings?.musicEndSeconds ?? 0)) сек (0 = до конца)")
                Slider(value: Binding(get: { settings?.musicEndSeconds ?? 0 }, set: { v in update { $0.musicEndSeconds = v } }), in: 0...300, step: 1)
                Text("Играет отрезок от начала до конца. Если конец 0, играет до конца трека. При зацикливании возвращается к началу.")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Остановить музыку") { MusicService.shared.stop() }
            }
            Section("Треки по вкладкам") {
                ForEach(0..<5, id: \.self) { tab in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tabNames[tab])
                        Text(fileName(for: tab)).font(.caption).foregroundStyle(.secondary)
                        HStack {
                            Button("Выбрать файл") { importingTab = tab; showImporter = true }
                            if !(path(for: tab)?.isEmpty ?? true) {
                                Button("Слушать") { MusicService.shared.stop(); MusicService.shared.play(for: tab) }
                                Button("Убрать") { clear(tab: tab) }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Музыка")
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.audio]) { result in
            if let url = try? result.get(), let tab = importingTab { importTrack(url: url, tab: tab) }
        }
        .onAppear { ensureSettings() }
    }
    func ensureSettings() {
        guard let realm = try? Realm() else { return }
        try? realm.write { if realm.objects(AppSettings.self).isEmpty { realm.add(AppSettings()) } }
    }
    func update(_ block: (AppSettings) -> Void) {
        guard let realm = try? Realm(), let s = realm.objects(AppSettings.self).first else { return }
        try? realm.write { block(s) }
    }
    func path(for tab: Int) -> String? {
        guard let s = settings else { return nil }
        switch tab {
        case 0: return s.musicProfilePath
        case 1: return s.musicDailiesPath
        case 2: return s.musicCalendarPath
        case 3: return s.musicItemsPath
        default: return s.musicBossesPath
        }
    }
    func fileName(for tab: Int) -> String {
        guard let p = path(for: tab), !p.isEmpty else { return "Нет трека" }
        return URL(fileURLWithPath: p).lastPathComponent
    }
    func clear(tab: Int) {
        MusicService.shared.stop()
        update { s in
            switch tab {
            case 0: s.musicProfilePath = ""
            case 1: s.musicDailiesPath = ""
            case 2: s.musicCalendarPath = ""
            case 3: s.musicItemsPath = ""
            default: s.musicBossesPath = ""
            }
        }
    }
    func importTrack(url: URL, tab: Int) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url) else { return }
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let dest = dir.appendingPathComponent("music_tab" + String(tab) + "_" + url.lastPathComponent)
        try? data.write(to: dest)
        update { s in
            switch tab {
            case 0: s.musicProfilePath = dest.path
            case 1: s.musicDailiesPath = dest.path
            case 2: s.musicCalendarPath = dest.path
            case 3: s.musicItemsPath = dest.path
            default: s.musicBossesPath = dest.path
            }
        }
    }
}