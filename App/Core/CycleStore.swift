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

    /// Set (or clear, with nil) a day's basal body temperature in °C.
    func setTemperatureC(_ celsius: Double?, on date: Date) {
        let k = key(for: date)
        var l = logs[k] ?? DayLog(dateKey: k)
        l.temperatureC = celsius
        upsert(l)
    }

    /// Recent basal temperatures as (date, °C), oldest→newest, up to `limit`.
    func recentTemperatures(limit: Int = 14) -> [(date: Date, celsius: Double)] {
        logsSnapshot
            .compactMap { log -> (Date, Double)? in
                guard let c = log.temperatureC, let d = Self.dateFmt.date(from: log.dateKey) else { return nil }
                return (d, c)
            }
            .sorted { $0.0 < $1.0 }
            .suffix(limit)
            .map { (date: $0.0, celsius: $0.1) }
    }

    func stretchDone(on date: Date) -> Bool { log(for: date)?.stretchDone ?? false }

    func setStretchDone(_ done: Bool, on date: Date) {
        let k = key(for: date)
        var l = logs[k] ?? DayLog(dateKey: k)
        l.stretchDone = done ? true : nil
        upsert(l)
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

    /// A store preloaded with realistic sample data — for SwiftUI previews.
    static func preview() -> CycleStore {
        let s = CycleStore()
        s.loadSampleData()
        return s
    }

    /// 3 cycles of flow + symptoms + moods + a basal-temperature curve with a
    /// post-ovulation rise. Positioned so "today" sits in the luteal (PMS) phase.
    /// Sets `logs` directly (no persistence) so previews never touch real data.
    func loadSampleData() {
        let today = cal.startOfDay(for: Date())
        var out: [String: DayLog] = [:]

        func put(_ offset: Int, _ build: (inout DayLog) -> Void) {
            guard let d = cal.date(byAdding: .day, value: offset, to: today), d <= today else { return }
            let k = key(for: d)
            var l = out[k] ?? DayLog(dateKey: k)
            build(&l)
            out[k] = l
        }

        // Three cycles of bleeding (starts at -18, -46, -74), 5-day period.
        let flows: [Flow] = [.medium, .heavy, .medium, .light, .spotting]
        for startOffset in [-18, -46, -74] {
            for (i, f) in flows.enumerated() {
                put(startOffset + i) { l in
                    l.flow = f
                    if i <= 1 { l.symptoms.insert(.cramps); l.symptoms.insert(.fatigue) }
                    if i == 0 { l.moods.insert(.sad) }
                }
            }
        }

        // Follicular upswing, then luteal / PMS this cycle.
        put(-12) { l in l.moods.insert(.energized); l.moods.insert(.happy) }
        put(-10) { l in l.moods.insert(.calm) }
        put(-4)  { l in l.symptoms.insert(.bloating); l.moods.insert(.irritable) }
        put(-3)  { l in l.symptoms.insert(.cravings); l.symptoms.insert(.tenderBreasts); l.moods.insert(.anxious) }
        put(-2)  { l in l.symptoms.insert(.cramps); l.symptoms.insert(.headache); l.moods.insert(.sensitive) }
        put(-1)  { l in l.symptoms.insert(.bloating); l.moods.insert(.tired) }
        put(0)   { l in l.symptoms.insert(.cravings); l.moods.insert(.calm) }

        // Basal temps (°F), last 16 days, with a sustained rise after ovulation.
        let tempsF: [Double] = [97.3, 97.4, 97.3, 97.5, 97.4, 97.5, 97.4, 97.6,
                                97.5, 97.4, 97.9, 98.0, 97.9, 98.1, 98.0, 98.1]
        for (i, f) in tempsF.enumerated() {
            put(-16 + i) { l in l.temperatureC = (f - 32) * 5 / 9 }
        }

        logs = out
    }
    #endif
}
