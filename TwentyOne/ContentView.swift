import SwiftUI

struct ContentView: View {
    @EnvironmentObject var theme: AppTheme
    @State private var tab = 0
    @State private var showAI = false
    @State private var showSplash = true
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            theme.background(for: tab)
            TabView(selection: $tab) {
                ProfileView().tabItem { Label("Профиль", systemImage: "person.crop.circle") }.tag(0)
                DailiesView().tabItem { Label("Дейлики", systemImage: "checklist") }.tag(1)
                CalendarView().tabItem { Label("Календарь", systemImage: "calendar") }.tag(2)
                ItemsView().tabItem { Label("Предметы", systemImage: "backpack") }.tag(3)
                BossesView().tabItem { Label("Боссы", systemImage: "shield") }.tag(4)
            }
            .scrollContentBackground(.hidden)
            Button { showAI = true } label: {
                Image(systemName: "sparkles").font(.title2).padding(16)
                    .background(Circle().fill(theme.accentColor)).foregroundStyle(.white).shadow(radius: 4)
            }
            .padding(.trailing, 16).padding(.bottom, 90)
        }
        .sheet(isPresented: $showAI) { AIAssistantView() }
        .onOpenURL { url in _ = Json21Service.importFile(url) }
        .onAppear { MusicService.shared.play(for: tab) }
        .onChange(of: tab) { _, newTab in MusicService.shared.play(for: newTab) }
        .overlay { if showSplash { SplashView(isShowing: $showSplash) } }
    }
}
