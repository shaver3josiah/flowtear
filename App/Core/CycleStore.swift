import SwiftUI

// App state + persistence. One Codable blob in UserDefaults — native, no file
// store needed for this data size. Predictions are derived on demand from logs.

@Observable
final class CycleStore {
    private(set) var logs: [String: DayLog] = [:]   // dateKey -> log
    var settings = CycleSettings() { didSet { save() } }

    private let cal = Calendar.current
    private let defaultsKey = "flowtear.state.v1"

    static let dateFmt: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    init() { load() }

    // MARK: keys

    func key(for date: Date) -> String { Self.dateFmt.string(from: cal.startOfDay(for: date)) }
    func log(for date: Date) -> DayLog? { logs[key(for: date)] }

    var logsSnapshot: [DayLog] { Array(logs.values) }

    // MARK: mutations

    func upsert(_ log: DayLog) {
        if log.isEmpty { logs[log.dateKey] = nil } else { logs[log.dateKey] = log }
        save()
    }

    func toggleFlow(_ flow: Flow, on date: Date) {
        let k = key(for: date)
        var l = logs[k] ?? DayLog(dateKey: k)
        l.flow = (l.flow == flow) ? nil : flow
        upsert(l)
    }

    // MARK: derived

    /// Real bleeding days that feed cycle-length math — light/medium/heavy only.
    /// Spotting (weight 1) still logs and shows on the calendar, but must NOT open
    /// a period start, or an isolated mid-cycle spotting day halves the computed
    /// cycle length and poisons every prediction.
    var periodDays: [Date] {
        logs.values
            .filter { ($0.flow?.weight ?? 0) >= 2 }
            .compactMap { Self.dateFmt.date(from: $0.dateKey) }
    }

    func prediction(today: Date = Date()) -> CyclePrediction {
        CycleEngine.predict(periodDays: periodDays, today: today, settings: settings, cal: cal)
    }

    // MARK: persistence

    private struct Snapshot: Codable { var logs: [DayLog]; var settings: CycleSettings }

    private func save() {
        let snap = Snapshot(logs: Array(logs.values), settings: settings)
        if let data = try? JSONEncoder().encode(snap) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        logs = Dictionary(uniqueKeysWithValues: snap.logs.map { ($0.dateKey, $0) })
        settings = snap.settings
    }

    // Seed a couple of past cycles so the UI has something to show on first run in
    // the simulator. ponytail: dev-only, gated to DEBUG + empty state.
    #if DEBUG
    func seedSampleIfEmpty() {
        guard logs.isEmpty else { return }
        let today = cal.startOfDay(for: Date())
        // two prior period starts (~28d apart) + a current one, 4 days each
        for cycleAgo in [56, 28, 0] {
            for day in 0..<4 {
                guard let d = cal.date(byAdding: .day, value: -cycleAgo + day, to: today) else { continue }
                if d > today { continue }
                let k = key(for: d)
                logs[k] = DayLog(dateKey: k, flow: day == 0 ? .medium : .light)
            }
        }
        save()
    }
    #endif
}
