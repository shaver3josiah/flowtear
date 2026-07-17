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
                if last < 21 { out.append("Your last cycle ran \(last) days. Most run 21 to 35, so that one was short.") }
                if last > 35 { out.append("Your last cycle ran \(last) days, a little past the usual 21 to 35. One long cycle is common. A pattern of them is worth raising at a visit.") }
                if gaps.count >= 3 {
                    let prior = gaps.dropLast()
                    let avgPrior = Double(prior.reduce(0, +)) / Double(prior.count)
                    if abs(Double(last) - avgPrior) >= 7 {
                        out.append("Your last cycle was about \(Int(abs(Double(last) - avgPrior).rounded())) days off your usual rhythm.")
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
        if maxRecentRun > 7 { out.append("One recent period lasted \(maxRecentRun) days. Bleeding past 7 days is something a clinician would want to hear about.") }

        // Super heavy flow in the last ~month — no single day is alarming,
        // but it's exactly the kind of thing a clinician asks about.
        if let monthAgo = cal.date(byAdding: .day, value: -35, to: Date()) {
            let heavy = store.logsSnapshot.filter { log in
                guard log.flow == .superHeavy,
                      let d = CycleStore.dateFmt.date(from: log.dateKey) else { return false }
                return d >= monthAgo
            }.count
            if heavy > 0 {
                out.append("Super heavy flow on \(heavy) day\(heavy == 1 ? "" : "s") this month. If that's new for you, mention it at a visit.")
            }
        }

        // Overdue right now.
        let p = store.prediction()
        if let d = p.daysUntilNextPeriod, d < -3 {
            out.append("Your period is running \(abs(d)) days later than expected.")
        }
        return out
    }

    /// The full shareable text report, written the way a good nurse would talk
    /// you through it: plain sentences, the numbers first, then anything worth
    /// bringing up, and honest about what an estimate is.
    static func text(store: CycleStore) -> String {
        let cal = Calendar.current
        let p = store.prediction()
        let df = DateFormatter(); df.dateStyle = .medium
        var lines: [String] = []
        lines.append("CYCLE SUMMARY, prepared \(df.string(from: Date()))")
        lines.append(String(repeating: "-", count: 30))

        lines.append("")
        lines.append("THE NUMBERS")
        if p.hasHistory {
            lines.append("Average cycle: \(p.averageCycleLength) days. Average period: \(p.averagePeriodLength) days.")
            if let last = p.lastPeriodStart { lines.append("The last period started \(df.string(from: last)).") }
            if let next = p.nextPeriodStart { lines.append("The next one is expected around \(df.string(from: next)). That date is an estimate.") }
            let starts = CycleEngine.periodStarts(from: store.periodDays, cal: cal).sorted().suffix(6)
            if starts.count >= 2 {
                var gaps: [String] = []
                let arr = Array(starts)
                for i in 1..<arr.count {
                    if let d = cal.dateComponents([.day], from: arr[i-1], to: arr[i]).day { gaps.append("\(d)") }
                }
                lines.append("Recent cycle lengths: \(gaps.joined(separator: ", ")) days.")
            }
        } else {
            lines.append("There isn't enough logged yet for cycle statistics. A month or two of notes will fill this in.")
        }

        let notes = flags(store: store)
        lines.append("")
        lines.append("FOR YOUR VISIT")
        if notes.isEmpty {
            lines.append("Nothing out of the ordinary in the recent notes. Things look steady.")
        } else {
            for n in notes { lines.append("• \(n)") }
        }
        lines.append("")
        lines.append("Prepared from the daily logs in this cycle tracker. These are estimates to talk over with a clinician, not a diagnosis.")
        return lines.joined(separator: "\n")
    }

    /// The whole calendar's data as a spreadsheet (CSV), ready to share.
    /// Each row carries its cycle day and phase so the sheet sorts, filters,
    /// and pivots cleanly without her doing cycle math in Excel.
    static func csv(store: CycleStore) -> String {
        var rows = ["date,cycle_day,phase,flow,discharge,temp_f,temp_skipped,moods,symptoms,stretch_done,note"]
        for log in store.logsSnapshot.sorted(by: { $0.dateKey < $1.dateKey }) {
            // ponytail: phaseSnapshot re-predicts per row (O(n²) over the log
            // count); fine for years of daily logs, precompute if it ever isn't.
            let snap = CycleStore.dateFmt.date(from: log.dateKey)
                .map { store.phaseSnapshot(at: $0) } ?? (phase: nil, day: nil)
            let tempF = log.temperatureC.map { String(format: "%.2f", $0 * 9 / 5 + 32) } ?? ""
            let moods = log.moods.map(\.rawValue).sorted().joined(separator: "; ")
            let symptoms = log.symptoms.map(\.rawValue).sorted().joined(separator: "; ")
            let note = log.note.replacingOccurrences(of: "\"", with: "\"\"")
            rows.append("\(log.dateKey),\(snap.day.map(String.init) ?? ""),\(snap.phase?.rawValue ?? ""),\(log.flow?.rawValue ?? ""),\(log.discharge?.rawValue ?? ""),\(tempF),\(log.tempSkipped == true ? "yes" : ""),\"\(moods)\",\"\(symptoms)\",\(log.stretchDone == true ? "yes" : ""),\"\(note)\"")
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
