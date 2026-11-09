import SwiftUI

struct AnimatedEffectView: View {
    let namePrefix: String
    var fps: Double = 24
    var loop: Bool = false
    @State private var startDate = Date()
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / fps)) { context in
            let elapsed = context.date.timeIntervalSince(startDate)
            let raw = Int(elapsed * fps)
            let index = loop ? raw % 24 : min(raw, 23)
            Image(String(format: "%@_%02d", namePrefix, index))
                .resizable()
                .interpolation(.none)
                .scaledToFit()
        }
        .onAppear { startDate = Date() }
    }
}
