import SwiftUI

private struct Placeholder: View { let title: String; let text: String; var body: some View { NavigationStack { ContentUnavailableView(title, systemImage: "hammer", description: Text(text)).navigationTitle(title) } } }
struct ProfileView: View { var body: some View { Placeholder(title: "Профиль", text: "Этап 2") } }
struct DailiesView: View { var body: some View { Placeholder(title: "Дейлики", text: "Этапы 4-5") } }
struct CalendarView: View { var body: some View { Placeholder(title: "Календарь", text: "Этап 6") } }
struct ItemsView: View { var body: some View { Placeholder(title: "Предметы", text: "Этапы 7 и 9") } }
struct BossesView: View { var body: some View { Placeholder(title: "Боссы", text: "Этап 10") } }
struct AIAssistantView: View { var body: some View { Placeholder(title: "ИИ-ассистент", text: "Этап 12: Ollama + fallback") } }
