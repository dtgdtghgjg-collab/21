import SwiftUI
import RealmSwift

@main
struct TwentyOneApp: SwiftUI.App {
    @StateObject private var theme = AppTheme()
    init() {
        var config = Realm.Configuration.defaultConfiguration
        config.schemaVersion = 9
        config.objectTypes = [User.self, Attribute.self, SubAttribute.self, Skill.self, Daily.self, Event.self, Item.self, Boss.self, Perk.self, KeyValue.self, AppSettings.self, HistoryEntry.self]
        Realm.Configuration.defaultConfiguration = config
        _ = try? Realm()
        _ = DebtService.evaluate()
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
