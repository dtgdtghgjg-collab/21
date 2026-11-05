import UIKit

enum AppIconService {
    static let available: [(id: String, title: String)] = [("default", "Стандартная"), ("AppIcon-Gold", "Золотая"), ("AppIcon-Purple", "Фиолетовая"), ("AppIcon-Black", "Чёрная")]
    static var currentName: String { UserDefaults.standard.string(forKey: "selectedAppIcon") ?? "default" }
    static func setIcon(_ name: String) {
        let alternate: String? = name == "default" ? nil : name
        guard UIApplication.shared.supportsAlternateIcons else { return }
        UIApplication.shared.setAlternateIconName(alternate) { error in
            guard error == nil else { return }
            if alternate == nil { UserDefaults.standard.removeObject(forKey: "selectedAppIcon") } else { UserDefaults.standard.set(name, forKey: "selectedAppIcon") }
            Haptics.success()
            SoundService.success()
        }
    }
}
