import WidgetKit
import SwiftUI
import AppIntents

struct Entry: TimelineEntry { let date: Date }

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry { Entry(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) { completion(Entry(date: .now)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        // Nach Mitternacht neu laden, damit das neue Tageslimit erscheint
        let next = Calendar.current.nextDate(after: .now, matching: DateComponents(hour: 0, minute: 1), matchingPolicy: .nextTime) ?? .now.addingTimeInterval(3600)
        completion(Timeline(entries: [Entry(date: .now)], policy: .after(next)))
    }
}

struct ZugzaehlerWidgetView: View {
    var entry: Entry
    var body: some View {
        let count = Store.count(), limit = Store.todayLimit, left = limit - count
        VStack(spacing: 4) {
            Text(left >= 0 ? "\(left)" : "+\(-left)")
                .font(.system(size: 42, weight: .heavy, design: .rounded))
                .foregroundStyle(left < 0 ? Color.red : (left == 0 ? Color.orange : Color.primary))
            Text(left < 0 ? "über Limit" : "übrig · \(count)/\(limit)")
                .font(.caption).foregroundStyle(.secondary)
            Button(intent: AddPuffIntent()) {
                Text("+1").font(.title2.bold()).frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent).tint(.teal)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

@main
struct ZugzaehlerWidgetBundle: WidgetBundle {
    var body: some Widget { ZugzaehlerWidget() }
}

struct ZugzaehlerWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ZugzaehlerWidget", provider: Provider()) { entry in
            ZugzaehlerWidgetView(entry: entry)
        }
        .configurationDisplayName("Zugzähler")
        .description("Trage einen Zug mit einem Tipp ein.")
        .supportedFamilies([.systemSmall])
    }
}
