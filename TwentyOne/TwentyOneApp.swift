import SwiftUI
import RealmSwift

@main
struct TwentyOneApp: App {
    @StateObject private var theme = AppTheme()
    init() {
        var config = Realm.Configuration.defaultConfiguration
        config.schemaVersion = 1
        config.objectTypes = [User.self, Stat.self, Skill.self, Daily.self, Event.self, Item.self, Boss.self, Perk.self, KeyValue.self, AppSettings.self]
        Realm.Configuration.defaultConfiguration = config
        _ = try? Realm()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(theme)
                .preferredColorScheme(theme.colorScheme)
                .tint(theme.accentColor)
        }
    }
}
