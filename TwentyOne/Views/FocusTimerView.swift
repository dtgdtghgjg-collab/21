import SwiftUI
import RealmSwift

enum FocusLock {
    static var endsAt: Date? { let t = UserDefaults.standard.double(forKey: "focusEndsAt"); return t > 0 ? Date(timeIntervalSince1970: t) : nil }
    static var isActive: Bool { guard let endsAt = endsAt else { return false }; return endsAt > Date() }
    static func start(seconds: Int) { UserDefaults.standard.set(Date().addingTimeInterval(Double(seconds)).timeIntervalSince1970, forKey: "focusEndsAt") }
    static func cancel() { UserDefaults.standard.removeObject(forKey: "focusEndsAt") }
}

struct FocusTimerView: View {
    @State private var remaining = 1500
    @State private var running = false
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(timeText).font(.system(size: 28, weight: .bold, design: .monospaced))
            Text(running ? "Фокус идёт: свайпы и другие вкладки заблокированы" : "25 минут фокуса: по завершении +50 XP").font(.caption).foregroundStyle(.secondary)
            if running { Button("Отменить фокус") { cancel() }.buttonStyle(TwentySecondaryButtonStyle(color: TwentyOneTab.dailies.theme.accent)) } else { Button("Начать фокус 25 мин") { start() }.buttonStyle(TwentyPrimaryButtonStyle(color: TwentyOneTab.dailies.theme.accent)) }
        }
        .onAppear { sync() }
        .onReceive(timer) { _ in tick() }
    }
    var timeText: String { String(format: "%02d:%02d", remaining / 60, remaining % 60) }
    func sync() { running = FocusLock.isActive; if let endsAt = FocusLock.endsAt { remaining = max(0, Int(endsAt.timeIntervalSince(Date()))) } }
    func start() { FocusLock.start(seconds: 1500); remaining = 1500; running = true; Haptics.medium(); SoundService.pop() }
    func cancel() { FocusLock.cancel(); running = false; remaining = 1500; Haptics.tap() }
    func tick() { guard running else { return }; sync(); if remaining <= 0 { finish() } }
    func finish() { running = false; FocusLock.cancel(); remaining = 1500; RealmStore.write { realm in guard let liveUser = RealmStore.user(in: realm) else { return }; liveUser.xp += 50; while liveUser.xp >= User.xpForNextLevel(liveUser.level) { liveUser.xp -= User.xpForNextLevel(liveUser.level); liveUser.level += 1 } }; HistoryService.log("focus_complete", "Фокус Pomodoro завершён", xp: 50); Haptics.success(); SoundService.success() }
}
