import SwiftUI

final class AppTheme: ObservableObject {
    @AppStorage("accentName") var accentName: String = "blue"
    @AppStorage("isDark") var isDark: Bool = true
    @AppStorage("wallpaperPath") var wallpaperPath: String = ""
    @AppStorage("wallpaperAllScreens") var wallpaperAllScreens: Bool = false
    @AppStorage("wallpaperProfile") var wallpaperProfilePath: String = ""
    @AppStorage("wallpaperDailies") var wallpaperDailiesPath: String = ""
    @AppStorage("wallpaperCalendar") var wallpaperCalendarPath: String = ""
    @AppStorage("wallpaperItems") var wallpaperItemsPath: String = ""
    @AppStorage("wallpaperBosses") var wallpaperBossesPath: String = ""
    var colorScheme: ColorScheme { isDark ? .dark : .light }
    var accentColor: Color {
        switch accentName { case "red": return .red; case "green": return .green; case "purple": return .purple; case "orange": return .orange; default: return .blue }
    }
    func wallpaperPath(for tab: Int) -> String {
        let perTab: String
        switch tab { case 0: perTab = wallpaperProfilePath; case 1: perTab = wallpaperDailiesPath; case 2: perTab = wallpaperCalendarPath; case 3: perTab = wallpaperItemsPath; case 4: perTab = wallpaperBossesPath; default: perTab = "" }
        if !perTab.isEmpty { return perTab }
        return wallpaperAllScreens ? wallpaperPath : ""
    }
    func setWallpaper(_ path: String, for tab: Int) {
        switch tab { case 0: wallpaperProfilePath = path; case 1: wallpaperDailiesPath = path; case 2: wallpaperCalendarPath = path; case 3: wallpaperItemsPath = path; case 4: wallpaperBossesPath = path; default: wallpaperPath = path }
    }
    func clearWallpaper(for tab: Int) { setWallpaper("", for: tab) }
    func background(for tab: Int) -> some View {
        ZStack {
            let path = wallpaperPath(for: tab)
            if !path.isEmpty, let ui = UIImage(contentsOfFile: path) {
                Image(uiImage: ui).resizable().scaledToFill().ignoresSafeArea()
            } else { Color(UIColor.systemBackground).ignoresSafeArea() }
        }
    }
    var background: some View { background(for: -1) }
    var mainBackground: some View { background(for: 0) }
}
