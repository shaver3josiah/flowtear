import Foundation

// Pure cycle prediction math — no SwiftUI, no persistence, fully unit-testable.
// Everything takes an injected Calendar + `today` so tests are deterministic.

struct CyclePrediction: Equatable {
    var averageCycleLength: Int
    var averagePeriodLength: Int
    var lastPeriodStart: Date?
    var nextPeriodStart: Date?
    var ovulationDate: Date?
    var fertileStart: Date?
    var fertileEnd: Date?
    var cycleDay: Int?          // 1-based day of current cycle, at `today`
    var phase: CyclePhase?
    var daysUntilNextPeriod: Int?

    var hasHistory: Bool { lastPeriodStart != nil }
}

enum CycleEngine {

    /// Collapse a set of logged bleeding-days into period *start* dates. Consecutive
    /// (or near-consecutive) days are one period; a gap larger than `maxGap` days
    /// starts a new one. Returns starts ascending, deduped to day granularity.
    static func periodStarts(from periodDays: [Date], maxGap: Int = 1, cal: Calendar) -> [Date] {
        let days = Set(periodDays.map { cal.startOfDay(for: $0) }).sorted()
        guard let first = days.first else { return [] }
        var starts = [first]
        var prev = first
        for day in days.dropFirst() {
            let gap = cal.dateComponents([.day], from: prev, to: day).day ?? 0
            if gap > maxGap + 1 { starts.append(day) }   // gap of >maxGap empty days => new period
            prev = day
        }
        return starts
    }

    /// Average of the most recent `recent` cycle lengths (gaps between starts).
    /// Falls back to `fallback` when there aren't at least two starts.
    static func averageCycleLength(starts: [Date], recent: Int = 6, fallback: Int, cal: Calendar) -> Int {
        guard starts.count >= 2 else { return fallback }
        let sorted = starts.sorted()
        var gaps: [Int] = []
        for i in 1..<sorted.count {
            if let d = cal.dateComponents([.day], from: sorted[i - 1], to: sorted[i]).day, d > 0 {
                gaps.append(d)
            }
        }
        guard !gaps.isEmpty else { return fallback }
        let window = Array(gaps.suffix(recent))
        return Int((Double(window.reduce(0, +)) / Double(window.count)).rounded())
    }

    /// Average logged period length (contiguous bleeding-day runs). Falls back to default.
    static func averagePeriodLength(from periodDays: [Date], fallback: Int, cal: Calendar) -> Int {
        let days = Set(periodDays.map { cal.startOfDay(for: $0) }).sorted()
        guard !days.isEmpty else { return fallback }
        var runs: [Int] = []
        var run = 1
        for i in 1..<max(days.count, 1) {
            let gap = cal.dateComponents([.day], from: days[i - 1], to: days[i]).day ?? 0
            if gap == 1 { run += 1 } else { runs.append(run); run = 1 }
        }
        runs.append(run)
        guard !runs.isEmpty else { return fallback }
        return Int((Double(runs.reduce(0, +)) / Double(runs.count)).rounded())
    }

    static func predict(
        periodDays: [Date],
        today: Date,
        settings: CycleSettings,
        cal: Calendar = .current
    ) -> CyclePrediction {
        let today = cal.startOfDay(for: today)
        let starts = periodStarts(from: periodDays, cal: cal)
        let avgCycle = averageCycleLength(starts: starts, fallback: settings.defaultCycleLength, cal: cal)
        let avgPeriod = averagePeriodLength(from: periodDays, fallback: settings.defaultPeriodLength, cal: cal)

        guard let last = starts.last else {
            // No history yet — nothing to predict.
            return CyclePrediction(
                averageCycleLength: avgCycle, averagePeriodLength: avgPeriod,
                lastPeriodStart: nil, nextPeriodStart: nil, ovulationDate: nil,
                fertileStart: nil, fertileEnd: nil, cycleDay: nil, phase: nil,
                daysUntilNextPeriod: nil
            )
        }

        let next = cal.date(byAdding: .day, value: avgCycle, to: last)!
        let ovulation = cal.date(byAdding: .day, value: -settings.lutealPhaseLength, to: next)!
        // Fertile window: sperm survives ~5d before ovulation, egg ~1d after.
        let fertileStart = cal.date(byAdding: .day, value: -5, to: ovulation)!
        let fertileEnd = cal.date(byAdding: .day, value: 1, to: ovulation)!

        let cycleDay = (cal.dateComponents([.day], from: last, to: today).day ?? 0) + 1
        let daysUntil = cal.dateComponents([.day], from: today, to: next).day

        let phase = phase(
            today: today, periodLength: avgPeriod,
            fertileStart: fertileStart, fertileEnd: fertileEnd,
            ovulation: ovulation, cycleStart: last, cal: cal
        )

        return CyclePrediction(
            averageCycleLength: avgCycle, averagePeriodLength: avgPeriod,
            lastPeriodStart: last, nextPeriodStart: next, ovulationDate: ovulation,
            fertileStart: fertileStart, fertileEnd: fertileEnd,
            cycleDay: max(cycleDay, 1), phase: phase, daysUntilNextPeriod: daysUntil
        )
    }

    private static func phase(
        today: Date, periodLength: Int,
        fertileStart: Date, fertileEnd: Date, ovulation: Date,
        cycleStart: Date, cal: Calendar
    ) -> CyclePhase {
        let periodEnd = cal.date(byAdding: .day, value: periodLength - 1, to: cycleStart)!
        if today <= periodEnd { return .menstrual }
        if cal.isDate(today, inSameDayAs: ovulation) { return .ovulation }
        if today >= fertileStart && today <= fertileEnd { return .fertile }
        if today > fertileEnd { return .luteal }
        return .follicular
    }
}
