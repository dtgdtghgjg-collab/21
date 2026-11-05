import SwiftUI
import RealmSwift

struct WeekdayStatsView: View {
    let entries: [HistoryEntry]
    private let labels = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
    var counts: [Int] { var result = Array(repeating: 0, count: 7); for entry in entries where entry.kind == "daily_complete" { let weekday = Calendar.current.component(.weekday, from: entry.date); result[(weekday + 5) % 7] += 1 }; return result }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if counts.allSatisfy({ $0 == 0 }) { Text("Пока нет данных: выполни первый дейлик").font(.caption).foregroundStyle(.secondary) } else {
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(0..<7, id: \.self) { i in
                        VStack(spacing: 6) {
                            Text("\(counts[i])").font(.caption2).foregroundStyle(.secondary)
                            RoundedRectangle(cornerRadius: 5, style: .continuous).fill(TwentyOneTab.history.theme.accent.opacity(0.85)).frame(width: 24, height: barHeight(i))
                            Text(labels[i]).font(.caption2)
                        }
                    }
                }
                Text("Самый продуктивный день: \(labels[counts.firstIndex(of: counts.max() ?? 0) ?? 0]) · самый ленивый: \(labels[counts.firstIndex(of: counts.min() ?? 0) ?? 0])").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
    func barHeight(_ i: Int) -> CGFloat { let m = max(counts.max() ?? 1, 1); return CGFloat(10 + 54 * Double(counts[i]) / Double(m)) }
}
