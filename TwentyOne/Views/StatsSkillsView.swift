import SwiftUI
import RealmSwift

struct StatsSkillsView: View {
    @ObservedResults(User.self) var users
    @State private var newSubName = ""
    @State private var newSubCap = 20
    @State private var newSkillName = ""
    var user: User? { users.first }
    var body: some View {
        List {
            if let user = user {
                ForEach(user.attributes, id: \.id) { attr in
                    DisclosureGroup {
                        ForEach(attr.subAttributes, id: \.id) { sub in
                            HStack {
                                Text(sub.name)
                                Spacer()
                                Text(String(sub.value) + " / " + String(sub.cap))
                                Stepper("", value: Binding(get: { sub.value }, set: { updateSub(sub, to: $0) }), in: 0...sub.cap)
                            }
                        }
                        HStack {
                            TextField("Своя подхарактеристика", text: $newSubName)
                            Stepper("Кап: " + String(newSubCap), value: $newSubCap, in: 1...100)
                            Button("Добавить") { addSub(to: attr) }.disabled(newSubName.isEmpty)
                        }
                    } label: {
                        HStack { Text(attr.name); Spacer(); Text(String(attr.total) + " / 100") }
                    }
                }
            }
            Section("Навыки") {
                if let user = user {
                    ForEach(user.skills, id: \.id) { skill in
                        HStack { Text(skill.name); Spacer(); Text(skill.isPassive ? "пассивный" : "активный").font(.caption) }
                    }
                }
                TextField("Название навыка", text: $newSkillName)
                Button("Добавить навык") { addSkill() }.disabled(newSkillName.isEmpty)
            }
        }
        .navigationTitle("Характеристики и навыки")
        .onAppear { ensureUserAndAttributes() }
    }
    func ensureUserAndAttributes() {
        guard let realm = try? Realm() else { return }
        if realm.objects(User.self).isEmpty { try? realm.write { realm.add(User()) } }
        guard let user = realm.objects(User.self).first, user.attributes.isEmpty else { return }
        let seed: [(String, [String])] = [("Сила", ["Физическая сила", "Выносливость", "Взрывная сила", "Гибкость", "Координация"]), ("Ловкость", ["Реакция", "Баланс", "Точность", "Пластичность", "Скорость"]), ("Интеллект", ["Логика", "Память", "Скорость мышления", "Критическое мышление", "Креативность"]), ("Дух", ["Стрессоустойчивость", "Дисциплина", "Мотивация", "Эмпатия", "Интуиция"]), ("Социальные", ["Коммуникабельность", "Убеждение", "Лидерство", "Слушание", "Нетворкинг"]), ("Творчество", ["Воображение", "Художественный вкус", "Музыкальность", "Писательский навык", "Ремесло"])]
        try? realm.write {
            for (name, subs) in seed {
                let attr = Attribute()
                attr.name = name
                for subName in subs {
                    let sub = SubAttribute()
                    sub.name = subName
                    sub.value = 0
                    sub.cap = 20
                    sub.isCustom = false
                    sub.parentAttributeId = name
                    attr.subAttributes.append(sub)
                }
                user.attributes.append(attr)
            }
        }
    }
    func updateSub(_ sub: SubAttribute, to value: Int) {
        guard let realm = try? Realm() else { return }
        try? realm.write { sub.value = value }
    }
    func addSub(to attr: Attribute) {
        guard let realm = try? Realm() else { return }
        let sub = SubAttribute()
        sub.name = newSubName
        sub.value = 0
        sub.cap = newSubCap
        sub.isCustom = true
        sub.parentAttributeId = attr.name
        try? realm.write { attr.subAttributes.append(sub) }
        newSubName = ""
        newSubCap = 20
    }
    func addSkill() {
        guard let realm = try? Realm(), let user = user else { return }
        let skill = Skill()
        skill.name = newSkillName
        skill.progress = 0
        skill.isPassive = false
        try? realm.write { user.skills.append(skill) }
        newSkillName = ""
    }
}
