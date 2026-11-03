import SwiftUI
import RealmSwift

struct StatsSkillsView: View {
    @ObservedResults(User.self) var users
    @State private var newSubName = ""
    @State private var newSubCap = 20
    @State private var newSkillName = ""
    var user: User? { users.first }
    var body: some View {
        SwiftUI.List {
            if let user = user {
                ForEach(user.attributes, id: \.id) { attr in
                    DisclosureGroup {
                        ForEach(attr.subAttributes, id: \.id) { sub in
                            HStack {
                                Text(sub.name)
                                Spacer()
                                Text("\(sub.value) / \(sub.cap)")
                                Stepper("", value: Binding(get: { sub.value }, set: { updateSub(sub, to: $0) }), in: 0...sub.cap)
                            }
                        }
                        HStack {
                            TextField("Своя подхарактеристика", text: $newSubName)
                            Stepper("Кап: \(newSubCap)", value: $newSubCap, in: 1...100)
                            Button("Добавить") { addSub(to: attr) }.disabled(newSubName.isEmpty)
                        }
                    } label: {
                        HStack { Text(attr.name); Spacer(); Text("\(attr.total) / 100") }
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
        let id = sub.id
        RealmStore.write { realm in realm.object(ofType: SubAttribute.self, forPrimaryKey: id)?.value = value }
    }
    func addSub(to attr: Attribute) {
        let attrId = attr.id
        let subName = newSubName
        let subCap = newSubCap
        let parentName = attr.name
        RealmStore.write { realm in
            guard let liveAttr = realm.object(ofType: Attribute.self, forPrimaryKey: attrId) else { return }
            let sub = SubAttribute()
            sub.name = subName
            sub.value = 0
            sub.cap = subCap
            sub.isCustom = true
            sub.parentAttributeId = parentName
            liveAttr.subAttributes.append(sub)
        }
        newSubName = ""
        newSubCap = 20
    }
    func addSkill() {
        guard let userId = user?.id else { return }
        let skillName = newSkillName
        RealmStore.write { realm in
            guard let liveUser = realm.object(ofType: User.self, forPrimaryKey: userId) else { return }
            let skill = Skill()
            skill.name = skillName
            skill.progress = 0
            skill.isPassive = false
            liveUser.skills.append(skill)
        }
        newSkillName = ""
    }
}
