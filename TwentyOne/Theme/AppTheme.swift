import SwiftUI

final class AppTheme: ObservableObject {
    @Published var accentName: String { didSet { UserDefaults.standard.set(accentName, forKey: "accentName") } }
    @Published var isDark: Bool { didSet { UserDefaults.standard.set(isDark, forKey: "isDark") } }
    @Published var wallpaperPath: String { didSet { UserDefaults.standard.set(wallpaperPath, forKey: "wallpaperPath") } }
    @Published var wallpaperAllScreens: Bool { didSet { UserDefaults.standard.set(wallpaperAllScreens, forKey: "wallpaperAllScreens") } }
    @Published var wallpaperProfilePath: String { didSet { UserDefaults.standard.set(wallpaperProfilePath, forKey: "wallpaperProfile") } }
    @Published var wallpaperDailiesPath: String { didSet { UserDefaults.standard.set(wallpaperDailiesPath, forKey: "wallpaperDailies") } }
    @Published var wallpaperCalendarPath: String { didSet { UserDefaults.standard.set(wallpaperCalendarPath, forKey: "wallpaperCalendar") } }
    @Published var wallpaperItemsPath: String { didSet { UserDefaults.standard.set(wallpaperItemsPath, forKey: "wallpaperItems") } }
    @Published var wallpaperBossesPath: String { didSet { UserDefaults.standard.set(wallpaperBossesPath, forKey: "wallpaperBosses") } }
    static let bundledWallpapers: [String] = ["wallpaper_nebula", "wallpaper_ocean", "wallpaper_forest", "wallpaper_sunset", "wallpaper_midnight"]
    init() { let d = UserDefaults.standard; accentName = d.string(forKey: "accentName") ?? "blue"; isDark = d.object(forKey: "isDark") as? Bool ?? true; wallpaperPath = d.string(forKey: "wallpaperPath") ?? ""; wallpaperAllScreens = d.bool(forKey: "wallpaperAllScreens"); wallpaperProfilePath = d.string(forKey: "wallpaperProfile") ?? ""; wallpaperDailiesPath = d.string(forKey: "wallpaperDailies") ?? ""; wallpaperCalendarPath = d.string(forKey: "wallpaperCalendar") ?? ""; wallpaperItemsPath = d.string(forKey: "wallpaperItems") ?? ""; wallpaperBossesPath = d.string(forKey: "wallpaperBosses") ?? "" }
    var colorScheme: ColorScheme { isDark ? .dark : .light }
    var accentColor: Color { switch accentName { case "red": return .red; case "green": return .green; case "purple": return .purple; case "orange": return .orange; default: return .blue } }
    func wallpaperPath(for tab: Int) -> String { let perTab: String; switch tab { case 0: perTab = wallpaperProfilePath; case 1: perTab = wallpaperDailiesPath; case 2: perTab = wallpaperCalendarPath; case 3: perTab = wallpaperItemsPath; case 4: perTab = wallpaperBossesPath; default: perTab = "" }; if !perTab.isEmpty { return perTab }; if wallpaperAllScreens && !wallpaperPath.isEmpty { return wallpaperPath }; if tab >= 0 && tab < AppTheme.bundledWallpapers.count { return "bundled:" + AppTheme.bundledWallpapers[tab] }; return wallpaperPath }
    func setWallpaper(_ path: String, for tab: Int) { switch tab { case 0: wallpaperProfilePath = path; case 1: wallpaperDailiesPath = path; case 2: wallpaperCalendarPath = path; case 3: wallpaperItemsPath = path; case 4: wallpaperBossesPath = path; default: wallpaperPath = path } }
    func clearWallpaper(for tab: Int) { setWallpaper("", for: tab) }
    func wallpaperImage(for tab: Int) -> UIImage? { let path = wallpaperPath(for: tab); if path.hasPrefix("bundled:") { return UIImage(named: String(path.dropFirst(8))) }; if !path.isEmpty { return UIImage(contentsOfFile: path) }; return nil }
    func visualTheme(for tab: Int) -> TabVisualTheme { switch tab { case 0: return TwentyOneTab.profile.theme; case 1: return TwentyOneTab.dailies.theme; case 2: return TwentyOneTab.history.theme; case 3: return TwentyOneTab.market.theme; case 4: return TwentyOneTab.bosses.theme; default: return TwentyOneTab.profile.theme } }
    func accentColor(for tab: Int) -> Color { visualTheme(for: tab).accent }
    func background(for tab: Int) -> some View { ZStack { if let ui = wallpaperImage(for: tab) { Image(uiImage: ui).resizable().scaledToFill().ignoresSafeArea() } else { visualTheme(for: tab).gradient.ignoresSafeArea() } } }
    var background: some View { background(for: -1) }
    var mainBackground: some View { background(for: 0) }
}
