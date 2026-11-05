import SwiftUI

struct ContentView: View {
    @EnvironmentObject var theme: AppTheme
    @State private var tab = 0
    @State private var showAI = false
    @State private var showSplash = true
    var body: some View {
        ZStack(alignment: .bottom) {
            theme.background(for: tab)
            TabView(selection: $tab) {
                ProfileView().tag(0)
                DailiesView().tag(1)
                CalendarView().tag(2)
                ItemsView().tag(3)
                BossesView().tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .toolbar(.hidden, for: .tabBar)
            .scrollContentBackground(.hidden)
            .tint(theme.accentColor(for: tab))
            .animation(.easeInOut(duration: 0.25), value: tab)
            .simultaneousGesture(DragGesture(minimumDistance: 70).onEnded { value in
                guard theme.swipeEnabled, !FocusLock.isActive else { return }
                guard abs(value.translation.width) > abs(value.translation.height) * 2 else { return }
                if value.translation.width < -70 { tab = theme.swipeCyclic && tab == 4 ? 0 : min(tab + 1, 4) }
                else if value.translation.width > 70 { tab = theme.swipeCyclic && tab == 0 ? 4 : max(tab - 1, 0) }
            })
            VStack(spacing: 12) {
                HStack {
                    Spacer()
                    Button { showAI = true } label: {
                        Image(systemName: "sparkles")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 52, height: 52)
                            .background(Circle().fill(theme.visualTheme(for: tab).accentGradient))
                            .overlay(Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
                            .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 5)
                    }
                }
                tabBar
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
        .sheet(isPresented: $showAI) { AIAssistantView() }
        .onOpenURL { url in _ = Json21Service.importFile(url) }
        .onAppear { MusicService.shared.play(for: tab) }
        .onChange(of: tab) { _, newTab in MusicService.shared.play(for: newTab) }
        .overlay { if showSplash { SplashView(isShowing: $showSplash) } }
    }
    private var tabBar: some View {
        HStack(spacing: 4) {
            tabButton("Профиль", "person.crop.circle.fill", 0)
            tabButton("Дейлики", "checklist", 1)
            tabButton("Календарь", "calendar", 2)
            tabButton("Предметы", "backpack.fill", 3)
            tabButton("Боссы", "shield.fill", 4)
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(theme.visualTheme(for: tab).card.opacity(0.94)))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.35), radius: 16, x: 0, y: 8)
    }
    private func tabButton(_ title: String, _ icon: String, _ tag: Int) -> some View {
        let selected = tab == tag
        return Button {
            if FocusLock.isActive && tag != tab { Haptics.error(); return }
            Haptics.tap(); SoundService.click()
            withAnimation(.easeInOut(duration: 0.25)) { tab = tag }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 19, weight: .semibold))
                Text(title).font(.system(size: 10, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.8)
            }
            .foregroundStyle(selected ? Color.white : Color.white.opacity(0.55))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background {
                if selected { Capsule().fill(theme.visualTheme(for: tab).accentGradient) }
            }
        }
        .buttonStyle(.plain)
    }
}
