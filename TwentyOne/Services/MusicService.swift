import Foundation
import AVFoundation
import RealmSwift

final class MusicService {
    static let shared = MusicService()
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var currentTab = -1
    static let quietFactor: Float = 0.35
    private init() {}
    func path(for tab: Int) -> String? {
        guard let realm = try? Realm(), let s = realm.objects(AppSettings.self).first, s.musicEnabled else { return nil }
        let p: String
        switch tab {
        case 0: p = s.musicProfilePath
        case 1: p = s.musicDailiesPath
        case 2: p = s.musicCalendarPath
        case 3: p = s.musicItemsPath
        default: p = s.musicBossesPath
        }
        return p.isEmpty ? nil : p
    }
    func play(for tab: Int) {
        if tab == currentTab { return }
        stop()
        guard let path = path(for: tab), let realm = try? Realm(), let s = realm.objects(AppSettings.self).first, FileManager.default.fileExists(atPath: path) else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        let item = AVPlayerItem(url: URL(fileURLWithPath: path))
        let player = AVPlayer(playerItem: item)
        player.volume = Float(AVAudioSession.sharedInstance().outputVolume) * Self.quietFactor
        self.player = player
        currentTab = tab
        let start = max(s.musicStartSeconds, 0)
        let end = s.musicEndSeconds
        let loop = s.musicLoop
        player.seek(to: CMTime(seconds: start, preferredTimescale: 600), completionHandler: { _ in player.play() })
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { [weak self] time in
            player.volume = Float(AVAudioSession.sharedInstance().outputVolume) * MusicService.quietFactor
            let duration = item.duration.seconds
            let limit = end > start ? end : duration
            guard limit.isFinite, time.seconds >= limit else { return }
            if loop {
                player.seek(to: CMTime(seconds: start, preferredTimescale: 600))
                player.play()
            } else {
                self?.stop()
            }
        }
    }
    func stop() {
        if let observer = timeObserver, let player = player { player.removeTimeObserver(observer) }
        timeObserver = nil
        player?.pause()
        player = nil
        currentTab = -1
    }
}