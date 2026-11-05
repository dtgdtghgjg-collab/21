import SwiftUI

struct SplashView: View {
    @Binding var isShowing: Bool
    @State private var opacity = 0.0
    @State private var scale = 0.92
    var body: some View {
        ZStack {
            TwentyOneTab.profile.theme.gradient.ignoresSafeArea()
            VStack(spacing: 18) {
                ZStack {
                    Circle().fill(LinearGradient(colors: [AppPalette.gold, AppPalette.goldDeep], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 104, height: 104)
                    Circle().strokeBorder(AppPalette.ink.opacity(0.55), lineWidth: 3).frame(width: 104, height: 104)
                    Text("21").font(.system(size: 46, weight: .black, design: .rounded)).foregroundStyle(AppPalette.ink)
                }
                .shadow(color: Color.black.opacity(0.4), radius: 18, x: 0, y: 10)
                .scaleEffect(scale)
                VStack(spacing: 6) {
                    Text("TWENTY ONE").font(.system(size: 15, weight: .bold)).tracking(4).foregroundStyle(AppPalette.parchment)
                    Text("DEVELOP BY NKTAKOT").font(.system(size: 11, weight: .semibold)).tracking(2).foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.7)) { opacity = 1; scale = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
                withAnimation(.easeOut(duration: 0.7)) { opacity = 0 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) { isShowing = false }
        }
    }
}
