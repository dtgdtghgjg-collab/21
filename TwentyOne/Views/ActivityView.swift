import SwiftUI
import RealmSwift

struct ActivityView: View {
    @ObservedResults(HistoryEntry.self, sortDescriptor: SortDescriptor(keyPath: "date", ascending: false)) var entries
    var body: some View {
        List {
            Section("Теплокарта (год)") {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(10), spacing: 2), count: 53), spacing: 2) {
                    ForEach(0..<371, id: \.self) { offset in
                        Rectangle().fill(dayColor(offset: offset)).frame(width: 10, height: 10)
                    }
                }
            }
            Section("Журнал") {
                if entries.isEmpty { Text("Пока пусто").font(.caption).foregroundStyle(.secondary) }
                ForEach(entries, id: \.id) { entry in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.text)
                        Text(entry.date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("История и активность")
    }
    func dayColor(offset: Int) -> Color {
        let day = Calendar.current.date(byAdding: .day, value: offset - 370, to: Calendar.current.startOfDay(for: Date())) ?? Date()
        let count = entries.filter { $0.kind == "daily_complete" && Calendar.current.isDate($0.date, inSameDayAs: day) }.count
        if count == 0 { return Color.gray.opacity(0.15) }
        return Color.green.opacity(min(0.3 + 0.2 * Double(count), 1.0))
    }
}
