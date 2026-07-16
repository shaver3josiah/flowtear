import Foundation

// CycleReport — a pre-prepared, shareable plain-text summary of her recent
// cycles, with gentle flags when something changed or looks worth mentioning
// (cycle length shifting, very short/long cycles, long bleeds, skipped stretch
// of days). Worded to hand to a partner or clinician; never diagnostic.

enum CycleReport {

    /// Things worth noting right now (empty = all quiet).
    static func flags(store: CycleStore) -> [String] {
        var out: [String] = []
        let cal = Calendar.current
        let starts = CycleEngine.periodStarts(from: store.periodDays, cal: cal).sorted()

        // Cycle-length signals need at least two completed cycles.
        if starts.count >= 2 {
            var gaps: [Int] = []
            for i in 1..<starts.count {
                if let d = cal.dateComponents([.day], from: starts[i-1], to: starts[i]).day { gaps.append(d) }
            }
            if let last = gaps.last {
                if last < 21 { out.append("Your last cycle was \(last) days — shorter than the typical 21–35 range.") }
                if last > 35 { out.append("Your last cycle was \(last) days — longer than the typical 21–35 range.") }
                if gaps.count >= 3 {
                    let prior = gaps.dropLast()
                    let avgPrior = Double(prior.reduce(0, +)) / Double(prior.count)
                    if abs(Double(last) - avgPrior) >= 7 {
                        out.append("Your last cycle differed from your usual by about \(Int(abs(Double(last) - avgPrior).rounded())) days.")
                    }
                }
            }
        }

        // Long bleed: most recent run of consecutive bleeding days > 7.
        let bleedDays = Set(store.periodDays.map { cal.startOfDay(for: $0) }).sorted()
        var run = 1, maxRecentRun = 0
        for i in 1..<max(bleedDays.count, 1) {
            let gap = cal.dateComponents([.day], from: bleedDays[i-1], to: bleedDays[i]).day ?? 0
            run = (gap == 1) ? run + 1 : 1
            maxRecentRun = max(maxRecentRun, run)
        }
        if maxRecentRun > 7 { out.append("A recent period ran \(maxRecentRun) days — longer than 7 is worth mentioning to a clinician.") }

        // Overdue right now.
        let p = store.prediction()
        if let d = p.daysUntilNextPeriod, d < -3 {
            out.append("Your period is currently \(abs(d)) days later than predicted.")
        }
        return out
    }

    /// The full shareable text report.
    static func text(store: CycleStore) -> String {
        let cal = Calendar.current
        let p = store.prediction()
        let df = DateFormatter(); df.dateStyle = .medium
        var lines: [String] = []
        lines.append("MY CYCLE REPORT — \(df.string(from: Date()))")
        lines.append(String(repeating: "—", count: 28))

        if p.hasHistory {
            lines.append("Average cycle: \(p.averageCycleLength) days · average period: \(p.averagePeriodLength) days")
            if let last = p.lastPeriodStart { lines.append("Last period started: \(df.string(from: last))") }
            if let next = p.nextPeriodStart { lines.append("Next period expected: \(df.string(from: next)) (estimate)") }
            let starts = CycleEngine.periodStarts(from: store.periodDays, cal: cal).sorted().suffix(6)
            if starts.count >= 2 {
                var gaps: [String] = []
                let arr = Array(starts)
                for i in 1..<arr.count {
                    if let d = cal.dateComponents([.day], from: arr[i-1], to: arr[i]).day { gaps.append("\(d)") }
                }
                lines.append("Recent cycle lengths: \(gaps.joined(separator: ", ")) days")
            }
        } else {
            lines.append("Not enough period days logged yet for cycle statistics.")
        }

        let notes = flags(store: store)
        lines.append("")
        if notes.isEmpty {
            lines.append("NOTES: nothing unusual in the recent data.")
        } else {
            lines.append("WORTH MENTIONING:")
            for n in notes { lines.append("• \(n)") }
        }
        lines.append("")
        lines.append("From my Uncorked tracker. Estimates, not medical advice.")
        return lines.joined(separator: "\n")
    }

    /// The whole calendar's data as a spreadsheet (CSV), ready to share.
    static func csv(store: CycleStore) -> String {
        var rows = ["date,flow,discharge,temp_f,temp_skipped,moods,symptoms,stretch_done,note"]
        for log in store.logsSnapshot.sorted(by: { $0.dateKey < $1.dateKey }) {
            let tempF = log.temperatureC.map { String(format: "%.2f", $0 * 9 / 5 + 32) } ?? ""
            let moods = log.moods.map(\.rawValue).sorted().joined(separator: "; ")
            let symptoms = log.symptoms.map(\.rawValue).sorted().joined(separator: "; ")
            let note = log.note.replacingOccurrences(of: "\"", with: "\"\"")
            rows.append("\(log.dateKey),\(log.flow?.rawValue ?? ""),\(log.discharge?.rawValue ?? ""),\(tempF),\(log.tempSkipped == true ? "yes" : ""),\"\(moods)\",\"\(symptoms)\",\(log.stretchDone == true ? "yes" : ""),\"\(note)\"")
        }
        return rows.joined(separator: "\n")
    }

    /// Writes the CSV to a temp file for the share sheet. Returns its URL.
    static func csvFile(store: CycleStore) -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("uncorked-cycle-data.csv")
        do {
            try csv(store: store).write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch { return nil }
    }
}
