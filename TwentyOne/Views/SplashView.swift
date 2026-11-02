import SwiftUI

struct SplashView: View {
    @Binding var isShowing: Bool
    @State private var opacity = 0.0
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 12) {
                Text("DEVELOP BY")
                Text("NKTAKOT")
            }
            .font(.system(size: 30, weight: .bold))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.7)) { opacity = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
                withAnimation(.easeOut(duration: 0.7)) { opacity = 0 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) { isShowing = false }
        }
    }
}