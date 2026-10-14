import SwiftUI
import UserNotifications

@main
struct ZugzaehlerApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

struct ContentView: View {
    @State private var tick = 0
    @State private var startText = ""
    @State private var message = ""
    @State private var showAlert = false
    @Environment(\.scenePhase) private var phase

    var body: some View {
        let _ = tick
        VStack(spacing: 20) {
            if Store.isSetUp { mainView } else { setupView }
        }
        .padding(24)
        .onChange(of: phase) { _, _ in tick += 1 }
        .alert(message, isPresented: $showAlert) { Button("Okay", role: .cancel) {} }
    }

    var setupView: some View {
        VStack(spacing: 16) {
            Text("Dein 30-Tage-Plan").font(.largeTitle.bold())
            Text("Wie viele Züge machst du aktuell etwa pro Tag? Dein Limit sinkt dann jeden Tag, bis du nach 30 Tagen bei 0 bist.")
                .foregroundStyle(.secondary)
            TextField("z. B. 120", text: $startText)
                .keyboardType(.numberPad)
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .textFieldStyle(.roundedBorder)
            Button("Plan starten") {
                if let v = Int(startText), v > 0 {
                    Store.reset(start: v)
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
                    tick += 1
                }
            }
            .buttonStyle(.borderedProminent).controlSize(.large)
        }
    }

    var mainView: some View {
        let count = Store.count(), limit = Store.todayLimit, left = limit - count
        let color: Color = left < 0 ? .red : (left == 0 ? .orange : .teal)
        return VStack(spacing: 22) {
            Text(Store.dayNumber > totalDays ? "Plan abgeschlossen" : "Tag \(Store.dayNumber) von \(totalDays)")
                .foregroundStyle(.secondary)
            ZStack {
                Circle().stroke(.quaternary, lineWidth: 16)
                Circle()
                    .trim(from: 0, to: limit > 0 ? max(0, CGFloat(left) / CGFloat(limit)) : 0)
                    .stroke(color, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 4) {
                    Text(left >= 0 ? "\(left)" : "+\(-left)")
                        .font(.system(size: 80, weight: .heavy, design: .rounded))
                    Text(left < 0 ? "über dem Limit" : "Züge übrig").foregroundStyle(.secondary)
                    Text("heute \(count) von \(limit)").font(.footnote).foregroundStyle(.secondary)
                }
            }
            .frame(width: 280, height: 280)

            Button {
                Store.add(1)
                tick += 1
                let c = Store.count(), l = Store.todayLimit
                if c == l {
                    message = "Limit für heute erreicht. Das war dein letzter Zug. Trink ein Glas Wasser, das Verlangen geht vorbei."
                    showAlert = true
                } else if c > l {
                    message = "Über dem Limit. Kein Drama, morgen ist ein neuer Tag mit neuem Limit."
                    showAlert = true
                }
            } label: {
                Text("+1").font(.system(size: 40, weight: .heavy, design: .rounded)).frame(maxWidth: .infinity, minHeight: 70)
            }
            .buttonStyle(.borderedProminent).tint(.teal)

            HStack {
                Button("−1 rückgängig") { Store.add(-1); tick += 1 }
                Spacer()
                Button("Plan neu starten", role: .destructive) { Store.start = 0; tick += 1 }
            }
        }
    }
}
