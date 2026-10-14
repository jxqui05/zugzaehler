import Foundation
import WidgetKit
import AppIntents
import UserNotifications

// App-Group-Name, muss zu project.yml passen
let appGroupID = "group.com.zugzaehler.app"
let totalDays = 30

enum Store {
    static let d = UserDefaults(suiteName: appGroupID) ?? .standard

    static var start: Int {
        get { d.integer(forKey: "start") }
        set { d.set(newValue, forKey: "start") }
    }
    static var startDate: Date? {
        get { d.object(forKey: "startDate") as? Date }
        set { d.set(newValue, forKey: "startDate") }
    }
    static var isSetUp: Bool { start > 0 && startDate != nil }

    static func key(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "c-\(c.year!)-\(c.month!)-\(c.day!)"
    }
    static func count(on date: Date = .now) -> Int { d.integer(forKey: key(date)) }

    static func add(_ n: Int) {
        d.set(max(0, count() + n), forKey: key(.now))
        WidgetCenter.shared.reloadAllTimelines()
    }

    // Tag 1 = Startdatum, Tag 30 = Limit 0
    static var dayNumber: Int {
        guard let s = startDate else { return 1 }
        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: s), to: cal.startOfDay(for: .now)).day ?? 0
        return days + 1
    }
    static func limit(forDay n: Int) -> Int {
        if n >= totalDays { return 0 }
        return max(0, Int((Double(start) * Double(totalDays - max(n, 1)) / Double(totalDays)).rounded()))
    }
    static var todayLimit: Int { limit(forDay: dayNumber) }

    static func reset(start s: Int) {
        for k in d.dictionaryRepresentation().keys where k.hasPrefix("c-") { d.removeObject(forKey: k) }
        start = s
        startDate = .now
        WidgetCenter.shared.reloadAllTimelines()
    }

    // Benachrichtigung, wenn das Tageslimit erreicht oder überschritten ist
    static func notifyIfNeeded() {
        let c = count(), l = todayLimit
        guard c >= l else { return }
        let content = UNMutableNotificationContent()
        content.title = c == l ? "Limit für heute erreicht" : "Über dem Limit"
        content.body = c == l
            ? "Das war dein letzter Zug für heute. Trink ein Glas Wasser, das Verlangen geht vorbei."
            : "Kein Drama. Morgen ist ein neuer Tag mit neuem Limit."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger))
    }
}

// Wird vom +1-Knopf im Widget ausgelöst
struct AddPuffIntent: AppIntent {
    static let title: LocalizedStringResource = "Zug eintragen"
    func perform() async throws -> some IntentResult {
        Store.add(1)
        Store.notifyIfNeeded()
        return .result()
    }
}
