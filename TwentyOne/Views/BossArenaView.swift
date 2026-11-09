import SwiftUI
import RealmSwift

struct BossArenaView: View {
    let boss: Boss
    @State private var shake = false
    @State private var floatingDamage: Int?
    @State private var lastHp: Int?
    @State private var showHitEffect = false
    @State private var showDeathEffect = false
    @State private var showSpawnEffect = false
    var spriteName: String {
        if !boss.spriteName.isEmpty { return boss.spriteName }
        if boss.category == "seasonal_real" { return "boss_real_teacher_01" }
        switch boss.name {
        case "Теневой Гоблин": return "boss_fantasy_02"
        case "Лич": return "boss_fantasy_03"
        case "Дракон", "Дракон Смауг": return "boss_fantasy_04"
        case "Тёмный демон": return "boss_fantasy_05"
        default: return "boss_fantasy_01"
        }
    }
    var isReal: Bool { boss.category == "seasonal_real" }
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                StatPill(icon: isReal ? "briefcase.fill" : "moon.fill", text: isReal ? "Сезонный / Реальный" : "Дарк Фентези", color: TwentyOneTab.bosses.theme.accent)
                RankBadge(rank: boss.rank)
                Spacer()
                StatPill(icon: "gift.fill", text: "\(boss.rewardsPesetas) P / \(boss.rewardsXp) XP", color: AppPalette.gold)
            }
            Text(boss.name).font(.system(size: 24, weight: .black, design: .rounded)).multilineTextAlignment(.center)
            ZStack(alignment: .top) {
                Image(spriteName).resizable().interpolation(.none).scaledToFit().frame(width: 260, height: 213)
                if showSpawnEffect { AnimatedEffectView(namePrefix: "fx_smoke_toxic").frame(width: 220, height: 220).offset(y: 10) }
                if showHitEffect { AnimatedEffectView(namePrefix: "fx_explosion_ember").frame(width: 200, height: 200) }
                if showDeathEffect { AnimatedEffectView(namePrefix: "fx_explosion_earth").frame(width: 290, height: 290).offset(y: -30) }
                if let floatingDamage = floatingDamage { Text("-\(floatingDamage)").font(.system(size: 34, weight: .black, design: .rounded)).foregroundStyle(.red).offset(y: 8).transition(.move(edge: .top).combined(with: .opacity)) }
            }
            .offset(x: shake ? -7 : 0)
            VStack(spacing: 6) {
                HStack { Text("HP: \(boss.hp) / \(boss.maxHp)").font(.headline); Spacer(); Text("\(boss.maxHp > 0 ? boss.hp * 100 / boss.maxHp : 0)%").font(.caption).foregroundStyle(.secondary) }
                GradientProgressBar(value: Double(boss.hp), total: Double(max(boss.maxHp, 1)), color: .red, height: 18)
            }
            Button("Атаковать за \(BossDamageService.manualAttackCost) P") { manualAttack() }.buttonStyle(TwentyPrimaryButtonStyle(color: TwentyOneTab.bosses.theme.accent)).disabled(boss.hp <= 1)
            Text("Ручная атака: 1–3 урона и не добивает ниже 1 HP. Основной урон босс получает от выполненных дейликов.").font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
        .onAppear { lastHp = boss.hp; triggerSpawn() }
        .onChange(of: boss.hp) { oldHp, newHp in
            let from = lastHp ?? oldHp
            if newHp < from { if newHp == 0 { triggerDeath(damage: from - newHp) } else { showHit(damage: from - newHp) } }
            lastHp = newHp
        }
        .onChange(of: boss.spriteName) { _, _ in triggerSpawn() }
    }
    func triggerSpawn() {
        showSpawnEffect = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { showSpawnEffect = false }
    }
    func triggerDeath(damage: Int) {
        floatingDamage = damage
        showDeathEffect = true
        Haptics.medium()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { showDeathEffect = false; floatingDamage = nil }
    }
    func showHit(damage: Int) {
        floatingDamage = damage
        showHitEffect = true
        withAnimation(.easeInOut(duration: 0.07).repeatCount(5, autoreverses: true)) { shake = true }
        Haptics.medium()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { shake = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { showHitEffect = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { floatingDamage = nil }
    }
    func manualAttack() {
        let result = BossDamageService.manualAttack()
        if result.damage > 0 { showHit(damage: result.damage) }
    }
}
