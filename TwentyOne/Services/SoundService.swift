import AudioToolbox

enum SoundService {
    static var enabled: Bool { UserDefaults.standard.object(forKey: "soundsEnabled") as? Bool ?? true }
    static func click() { play(1104) }
    static func coin() { play(1335) }
    static func success() { play(1057) }
    static func pop() { play(1105) }
    private static func play(_ id: SystemSoundID) { guard enabled else { return }; AudioServicesPlaySystemSound(id) }
}
