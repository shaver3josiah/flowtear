import Foundation

// Realistic, deterministic sample data used for PREVIEWS only — the Settings
// theme preview and the "here's what it'll look like" empty-state previews.
// Never written to the store; generated fresh from `today` so the preview always
// shows a lively mid-cycle (day ~14, fertile window open, a couple of cycles of
// history feeding the charts). No randomness — offsets are fixed so it's stable.
enum SampleData {

    /// ~2.5 cycles of logs ending mid-current-cycle, with moods & symptoms so the
    /// Insights charts have something to draw.
    static func logs(today: Date = Date(), cal: Calendar = .current) -> [DayLog] {
        let t0 = cal.startOfDay(for: today)
        var out: [DayLog] = []

        // Three period starts: current one began 13 days ago → today is ~cycle day 14.
        let starts = [-13 - 56, -13 - 28, -13]
        let ramp: [Flow] = [.medium, .heavy, .heavy, .medium, .light]   // 5-day period
        for start in starts {
            for (i, flow) in ramp.enumerated() {
                guard let d = cal.date(byAdding: .day, value: start + i, to: t0), d <= t0 else { continue }
                var log = DayLog(dateKey: key(d, cal), flow: flow)
                if i <= 1 { log.symptoms = [.cramps, .backache]; log.moods = [.tired] }
                else if i == 2 { log.symptoms = [.fatigue]; log.moods = [.sensitive] }
                out.append(log)
            }
        }

        // A few luteal-phase symptoms in the previous cycle (bloating/cravings/mood).
        for offset in [-13 - 7, -13 - 5, -13 - 3] {
            guard let d = cal.date(byAdding: .day, value: offset, to: t0), d <= t0 else { continue }
            var log = DayLog(dateKey: key(d, cal))
            log.symptoms = [.bloating, .cravings]
            log.moods = [.irritable]
            out.append(log)
        }

        // Current follicular/fertile mood — upbeat.
        for offset in [-4, -2] {
            guard let d = cal.date(byAdding: .day, value: offset, to: t0), d <= t0 else { continue }
            var log = DayLog(dateKey: key(d, cal))
            log.moods = [.happy, .energized]
            out.append(log)
        }

        return out
    }

    /// A plausible mid-cycle prediction, computed through the real engine so the
    /// ring, stats and fertile window are internally consistent.
    static func prediction(today: Date = Date(), cal: Calendar = .current) -> CyclePrediction {
        let periodDays = logs(today: today, cal: cal)
            .filter { ($0.flow?.weight ?? 0) >= 2 }
            .compactMap { CycleStore.dateFmt.date(from: $0.dateKey) }
        return CycleEngine.predict(periodDays: periodDays, today: today, settings: CycleSettings(), cal: cal)
    }

    private static func key(_ date: Date, _ cal: Calendar) -> String {
        CycleStore.dateFmt.string(from: cal.startOfDay(for: date))
    }
}
