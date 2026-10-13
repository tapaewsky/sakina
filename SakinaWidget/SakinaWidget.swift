import SwiftUI
import WidgetKit

struct VerseEntry: TimelineEntry {
    let date: Date
    let slot: Int
}

/// Текст меняется 3 раза в день: в полночь, в 12:00 и в 18:00
struct Provider: TimelineProvider {
    static let slotHours = [0, 12, 18]

    func placeholder(in context: Context) -> VerseEntry { VerseEntry(date: .now, slot: 0) }

    func getSnapshot(in context: Context, completion: @escaping (VerseEntry) -> Void) {
        completion(VerseEntry(date: .now, slot: Self.currentSlot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VerseEntry>) -> Void) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        var entries = [VerseEntry(date: .now, slot: Self.currentSlot())]
        for offset in 0..<3 {
            let day = calendar.date(byAdding: .day, value: offset, to: today)!
            for (slot, hour) in Self.slotHours.enumerated() {
                let start = calendar.date(byAdding: .hour, value: hour, to: day)!
                if start > .now { entries.append(VerseEntry(date: start, slot: slot)) }
            }
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    static func currentSlot(_ date: Date = .now) -> Int {
        let hour = Calendar.current.component(.hour, from: date)
        return slotHours.lastIndex { $0 <= hour } ?? 0
    }
}

struct SakinaWidgetView: View {
    let entry: VerseEntry
    @Environment(\.widgetFamily) private var family

    /// Предел длины перевода для каждого размера — в виджет попадают только тексты, которые видны целиком
    private var maxLength: Int {
        switch family {
        case .accessoryRectangular: 60
        case .systemSmall:          80
        case .systemMedium:         110
        default:                    200
        }
    }

    private var verse: Verse { Verse.at(entry.date, slot: entry.slot, maxLength: maxLength) }

    var body: some View {
        content.widgetURL(URL(string: "sakina://verse/\(verse.id)"))
    }

    @ViewBuilder private var content: some View {
        switch family {
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 3) {
                Text(verse.text)
                    .font(.system(size: 14, design: .serif))
                    .minimumScaleFactor(0.7)
                    .widgetAccentable()
                Text(verse.source)
                    .font(.system(size: 10, weight: .medium))
                    .opacity(0.6)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .containerBackground(.clear, for: .widget)

        case .systemSmall:
            VStack(alignment: .leading, spacing: 8) {
                Text("س").font(.custom("Amiri-Regular", size: 16)).foregroundStyle(Color.ink.opacity(0.35))
                Spacer(minLength: 0)
                Text(verse.text)
                    .font(.system(size: 15, design: .serif))
                    .minimumScaleFactor(0.6)
                Text(verse.source)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .foregroundStyle(Color.ink)
            .containerBackground(Color.paper, for: .widget)

        default:
            let large = family == .systemLarge
            VStack(spacing: large ? 20 : 8) {
                if large { Spacer(minLength: 0) }
                // Арабский показываем, только если он помещается без обрезки
                if large || verse.arabic.count <= 60 {
                    Text(verse.arabic)
                        .font(verse.arabicFont(large ? 25 : 18))
                        .lineSpacing(large ? 4 : 0)
                        .minimumScaleFactor(0.6)
                        .environment(\.layoutDirection, .rightToLeft)
                }
                if large {
                    Rectangle().fill(Color.ink.opacity(0.25)).frame(width: 32, height: 1)
                }
                Text(verse.text)
                    .font(.system(size: large ? 19 : 14, design: .serif))
                    .lineSpacing(large ? 5 : 1)
                    .minimumScaleFactor(0.6)
                Text(verse.source)
                    .font(.system(size: large ? 12 : 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if large { Spacer(minLength: 0) }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(Color.ink)
            .containerBackground(Color.paper, for: .widget)
        }
    }
}

@main
struct SakinaWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SakinaDaily", provider: Provider()) { entry in
            SakinaWidgetView(entry: entry)
        }
        .configurationDisplayName("Sakina")
        .description("Аят или хадис — три раза в день.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular])
    }
}

#Preview(as: .systemMedium) { SakinaWidget() } timeline: { VerseEntry(date: .now, slot: 0) }
