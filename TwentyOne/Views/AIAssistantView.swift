import SwiftUI
import RealmSwift

struct ChatLine: Identifiable {
    let id = UUID()
    let role: String
    let text: String
}

struct AIAssistantView: View {
    @ObservedResults(AppSettings.self) var settingsList
    @State private var messages: [ChatLine] = []
    @State private var input = ""
    @State private var host = ""
    @State private var model = "qwen2.5:8b-instruct"
    @State private var isLoading = false
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    TextField("LAN IP Ollama, например 192.168.1.10", text: $host)
                    TextField("Модель", text: $model)
                    Button("Сохранить") { saveHost() }
                }.padding(.horizontal)
                SwiftUI.List(messages) { line in
                    VStack(alignment: .leading) {
                        Text(line.role).font(.caption).foregroundStyle(.secondary)
                        Text(line.text)
                    }
                }
                HStack {
                    Button("Статы") { send("Покажи мои статы") }
                    Button("Босс") { send("Кто активный босс?") }
                    Button("Оцени") { send("Оцени дейлик: прочитать книгу 30 минут") }
                    Button("Неделя") { send("Покажи итоги недели") }
                }.padding(.horizontal)
                HStack {
                    TextField("Сообщение", text: $input)
                    Button(isLoading ? "..." : "Отправить") { send(input) }.disabled(input.isEmpty || isLoading)
                }.padding()
            }
            .navigationTitle("ИИ-ассистент")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Закрыть") { dismiss() } } }
            .onAppear { ensureSettings() }
        }
    }
    func ensureSettings() {
        guard let realm = try? Realm() else { return }
        try? realm.write { if realm.objects(AppSettings.self).isEmpty { realm.add(AppSettings()) } }
        host = realm.objects(AppSettings.self).first?.ollamaHost ?? ""
        model = realm.objects(AppSettings.self).first?.ollamaModel ?? "qwen2.5:8b-instruct"
        if messages.isEmpty { messages.append(ChatLine(role: "Ассистент", text: "Привет! Спроси про статы, предметы, босса или оценку дейлика. Если Ollama недоступна, отвечу локальным калькулятором.")) }
    }
    func saveHost() {
        let newHost = host; let newModel = model
        RealmStore.write { realm in
            if let s = RealmStore.settings(in: realm) { s.ollamaHost = newHost; s.ollamaModel = newModel } else { let s = AppSettings(); s.ollamaHost = newHost; s.ollamaModel = newModel; realm.add(s) }
        }
    }
    func send(_ text: String) {
        guard !text.isEmpty, !isLoading else { return }
        messages.append(ChatLine(role: "Вы", text: text))
        input = ""
        isLoading = true
        let currentHost = host
        let currentModel = model
        Task {
            let reply = await AIService.answer(message: text, host: currentHost, model: currentModel)
            messages.append(ChatLine(role: "Ассистент", text: reply))
            isLoading = false
        }
    }
}