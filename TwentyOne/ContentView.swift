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
            .toolbar(.hidden, for: .tabBar)
            .scrollContentBackground(.hidden)
            .tint(theme.accentColor(for: tab))
            .animation(.easeInOut(duration: 0.25), value: tab)
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
