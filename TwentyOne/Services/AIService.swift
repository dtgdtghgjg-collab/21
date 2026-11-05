import Foundation
import RealmSwift

struct AIService {
    static func characterStatsText() -> String {
        guard let realm = try? Realm(), let user = realm.objects(User.self).first else { return "Профиль не создан." }
        var text = "Уровень \(user.level), XP \(user.xp), песеты \(user.pesetas). Характеристики: "
        for attr in user.attributes { text += "\(attr.name) \(attr.total) ("; for sub in attr.subAttributes { text += "\(sub.name) \(sub.value); " }; text += "); " }
        text += "Навыки: "
        for skill in user.skills { text += skill.name + (skill.isPassive ? " (пассивный); " : "; ") }
        return text
    }
    static func itemDetailsText(name: String) -> String {
        guard let realm = try? Realm(), let user = realm.objects(User.self).first else { return "Профиль не создан." }
        let lower = name.lowercased()
        for item in user.inventory where item.name.lowercased().contains(lower) {
            return "\(item.name) [\(item.rank)], слот \(item.slot), \(item.costPesetas) P, \(item.costXp) XP, \(item.itemDescription)"
        }
        return "Предмет не найден: " + name
    }
    static func evaluateTaskText(description: String) -> String {
        let xp = 10 + min(description.count / 5, 90)
        return "Предлагаемая ценность: \(xp) XP, \(xp * 5) P. Это предложение, финально решаете вы."
    }
    static func activeBossText() -> String {
        guard let realm = try? Realm() else { return "Боссов нет." }
        for boss in realm.objects(Boss.self) where !boss.isDefeated {
            return "\(boss.name) [\(boss.rank)], HP \(boss.hp) / \(boss.maxHp), награда \(boss.rewardsPesetas) P, \(boss.rewardsXp) XP"
        }
        return "Все боссы побеждены."
    }
    static func toolContext(for message: String) -> String {
        let lower = message.lowercased()
        if lower.contains("стат") { return characterStatsText() }
        if lower.contains("недел") { return HistoryService.weeklySummary() }
        if lower.contains("босс") { return activeBossText() }
        if lower.contains("оцени") { return evaluateTaskText(description: message) }
        if lower.contains("предмет") {
            guard let realm = try? Realm(), let user = realm.objects(User.self).first else { return "Профиль не создан." }
            for item in user.inventory where lower.contains(item.name.lowercased()) { return itemDetailsText(name: item.name) }
            var list = "Предметы: "
            for item in user.inventory { list += item.name + " [" + item.rank + "]; " }
            return list
        }
        return ""
    }
    static func fallbackAnswer(for message: String) -> String {
        let ctx = toolContext(for: message)
        if ctx.isEmpty { return "Ollama недоступна, работает локальный калькулятор. Спросите про статы, босса, предмет или оценку дейлика." }
        return "Ollama недоступна, локальный ответ: " + ctx
    }
    static func askOllama(prompt: String, host: String, model: String) async -> String? {
        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedHost.isEmpty || trimmedHost.contains(" ") || trimmedHost.contains("@") { return nil }
        var base = trimmedHost
        if !base.hasPrefix("http") { base = "http://" + base + ":11434" }
        let allowedHost = base.hasPrefix("http://localhost") || base.hasPrefix("http://127.") || base.hasPrefix("http://192.168.") || base.hasPrefix("http://10.") || base.hasPrefix("http://172.")
        if !allowedHost { return nil }
        guard let url = URL(string: base + "/api/generate") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["model": model, "prompt": prompt, "stream": false]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let response = json["response"] as? String { return response }
        } catch { return nil }
        return nil
    }
    static func answer(message: String, host: String, model: String = "qwen2.5:8b-instruct") async -> String {
        let ctx = toolContext(for: message)
        let prompt = ctx.isEmpty ? message : "Контекст из игры: " + ctx + ". Вопрос игрока: " + message
        if let reply = await askOllama(prompt: prompt, host: host, model: model) { return reply }
        return fallbackAnswer(for: message)
    }
}