import SwiftUI

final class AppTheme: ObservableObject {
    @AppStorage("accentName") var accentName: String = "blue"
    @AppStorage("isDark") var isDark: Bool = true
    @AppStorage("wallpaperPath") var wallpaperPath: String = ""
    @AppStorage("wallpaperAllScreens") var wallpaperAllScreens: Bool = false
    var colorScheme: ColorScheme { isDark ? .dark : .light }
    var accentColor: Color {
        switch accentName { case "red": return .red; case "green": return .green; case "purple": return .purple; case "orange": return .orange; default: return .blue }
    }
    var background: some View {
        ZStack {
            if wallpaperAllScreens, !wallpaperPath.isEmpty, let ui = UIImage(contentsOfFile: wallpaperPath) {
                Image(uiImage: ui).resizable().scaledToFill().ignoresSafeArea()
            } else { Color(UIColor.systemBackground).ignoresSafeArea() }
        }
    }
}
