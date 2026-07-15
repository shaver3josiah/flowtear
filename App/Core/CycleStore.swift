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

    func stretchMovesDone(on date: Date) -> Set<Int> { log(for: date)?.stretchMovesDone ?? [] }

    /// Toggle one move's checkbox; when every move of the session is checked the
    /// whole day auto-completes. Returns true when this toggle finished the day.
    @discardableResult
    func toggleStretchMove(_ index: Int, on date: Date, totalMoves: Int) -> Bool {
        let k = key(for: date)
        var l = logs[k] ?? DayLog(dateKey: k)
        var done = l.stretchMovesDone ?? []
        if done.contains(index) { done.remove(index) } else { done.insert(index) }
        l.stretchMovesDone = done.isEmpty ? nil : done
        let dayComplete = done.count >= totalMoves && totalMoves > 0
        l.stretchDone = dayComplete ? true : (l.stretchDone == true && done.isEmpty ? nil : l.stretchDone)
        upsert(l)
        return dayComplete
    }

    /// Which stretch plan she's on. Starter (3-day) is the default; switching is
    /// always manual and NEVER touches logged data — completions are stored per
    /// calendar date, so both plans read the same history.
    var fullStretchPlan: Bool = UserDefaults.standard.bool(forKey: "flowtear.stretch.fullplan") {
        didSet { UserDefaults.standard.set(fullStretchPlan, forKey: "flowtear.stretch.fullplan") }
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
        guard let data = try? JSONEncoder().encode(snap) else { return }
        // Keep the previous good blob as a backup before overwriting, so a bad
        // write or a future model change can never silently destroy her history.
        if let previous = UserDefaults.standard.data(forKey: defaultsKey) {
            UserDefaults.standard.set(previous, forKey: defaultsKey + ".backup")
        }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    private func load() {
        // New fields are all optional, so blobs written by older builds decode
        // cleanly. If the main blob is ever unreadable, fall back to the backup
        // rather than starting empty (which the next save would make permanent).
        for key in [defaultsKey, defaultsKey + ".backup"] {
            if let data = UserDefaults.standard.data(forKey: key),
               let snap = try? JSONDecoder().decode(Snapshot.self, from: data) {
                logs = Dictionary(uniqueKeysWithValues: snap.logs.map { ($0.dateKey, $0) })
                settings = snap.settings
                return
            }
        }
    }

    // MARK: sample data (first-launch demo)

    private static let sampleSeededKey = "flowtear.sample.seeded"

    /// True while the store is showing the first-launch demo data.
    var sampleActive: Bool {
        UserDefaults.standard.bool(forKey: Self.sampleSeededKey) && !logs.isEmpty
    }

    /// First open: seed a full, lived-in 3 months of tracking so every screen
    /// previews with real-feeling data. Runs once (flag), only into an empty
    /// store, and is fully clearable from Insights.
    func seedSampleIfFirstLaunch() {
        guard logs.isEmpty, !UserDefaults.standard.bool(forKey: Self.sampleSeededKey) else { return }
        loadSampleData()
        save()
        UserDefaults.standard.set(true, forKey: Self.sampleSeededKey)
    }

    /// Wipe the demo data so real tracking starts clean. Never re-seeds.
    func clearSampleData() {
        logs = [:]
        save()
        UserDefaults.standard.set(false, forKey: Self.sampleSeededKey)
    }

    /// A store preloaded with the sample — for SwiftUI previews.
    static func preview() -> CycleStore {
        let s = CycleStore()
        s.loadSampleData()
        return s
    }

    /// 3 months of realistic tracking: three ~28-day cycles (starts at −74, −46,
    /// −18 days), 5-day periods, phase-patterned moods/symptoms/discharge, a
    /// biphasic basal-temperature curve, notes, and luteal stretch sessions.
    /// Today lands on cycle day 19 (luteal) so the stretch plan + PMS window and
    /// a completed fertile window all show. Sets `logs` in memory; callers persist.
    func loadSampleData() {
        let today = cal.startOfDay(for: Date())
        var out: [String: DayLog] = [:]
        let starts = [-74, -46, -18]
        let flows: [Flow] = [.medium, .heavy, .medium, .light, .spotting]

        // Deterministic jitter (no randomness — stable across launches/previews).
        func j(_ offset: Int, _ mod: Int) -> Int {
            abs((offset &* 2654435761) % max(mod, 1))
        }

        for offset in stride(from: -90, through: 0, by: 1) {
            guard let d = cal.date(byAdding: .day, value: offset, to: today), d <= today else { continue }
            guard let start = starts.last(where: { $0 <= offset }) else { continue }
            let cd = offset - start + 1   // 1-based cycle day
            let k = key(for: d)
            var l = DayLog(dateKey: k)

            // Flow — period days 1…5.
            if cd >= 1 && cd <= 5 { l.flow = flows[cd - 1] }

            // Symptoms by phase.
            switch cd {
            case 1...2:
                l.symptoms.insert(.cramps); l.symptoms.insert(.fatigue)
                if j(offset, 3) == 0 { l.symptoms.insert(.backache) }
            case 3...5:
                if j(offset, 2) == 0 { l.symptoms.insert(.fatigue) }
            case 17...23:
                if j(offset, 3) != 2 { l.symptoms.insert(.bloating) }
                if j(offset, 2) == 0 { l.symptoms.insert(.cravings) }
                if j(offset, 4) == 1 { l.symptoms.insert(.tenderBreasts) }
                if j(offset, 5) == 2 { l.symptoms.insert(.headache) }
            case 24...28:
                l.symptoms.insert(.cramps)
                if j(offset, 2) == 0 { l.symptoms.insert(.bloating) }
                if j(offset, 3) == 1 { l.symptoms.insert(.insomnia) }
            default:
                if j(offset, 7) == 3 { l.symptoms.insert(.acne) }
            }

            // Moods by phase.
            switch cd {
            case 1...2:   l.moods.insert(j(offset, 2) == 0 ? .sad : .tired)
            case 3...5:   l.moods.insert(.calm)
            case 6...11:  l.moods.insert(j(offset, 2) == 0 ? .energized : .happy)
            case 12...15: l.moods.insert(.happy); if j(offset, 2) == 0 { l.moods.insert(.energized) }
            case 16...21: l.moods.insert(j(offset, 3) == 0 ? .anxious : .calm)
            default:      l.moods.insert(j(offset, 2) == 0 ? .irritable : .sensitive)
                          if j(offset, 3) == 1 { l.moods.insert(.tired) }
            }

            // Discharge — dry after the period, creamy/watery rising, egg-white
            // at the fertile peak (days 12–15), sticky/dry through the luteal.
            switch cd {
            case 1...5:   l.discharge = nil
            case 6...8:   l.discharge = .dry
            case 9...11:  l.discharge = j(offset, 2) == 0 ? .sticky : .creamy
            case 12...13: l.discharge = .watery
            case 14...15: l.discharge = .eggWhite
            case 16...17: l.discharge = .creamy
            default:      l.discharge = j(offset, 2) == 0 ? .sticky : .dry
            }

            // Basal temperature (°F stored as °C): ~97.3 follicular baseline,
            // sustained ~+0.5 rise after ovulation (day 15) — a clean biphasic curve.
            let baseF = cd <= 15 ? 97.3 : 97.9
            let f = baseF + Double(j(offset, 3)) * 0.07
            l.temperatureC = (f - 32) * 5 / 9

            // Stretch sessions through the luteal window (~2/3 of days done).
            if cd >= 15 && j(offset, 3) != 1 { l.stretchDone = true }

            // Occasional notes.
            switch j(offset, 11) {
            case 0 where cd <= 2:  l.note = "Heat pack helped tonight."
            case 1 where cd >= 24: l.note = "Cramps eased after stretching."
            case 2 where cd >= 12 && cd <= 15: l.note = "Feeling great today."
            default: break
            }

            out[k] = l
        }

        logs = out
    }
}
