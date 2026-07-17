import SwiftUI
import UIKit
import Charts
import UniformTypeIdentifiers

// Insights — the "what your cycle is telling you" screen. A StatTile summary
// grid, IntensityBar breakdown charts (rhythm + symptom frequency), the
// cycle-tuning controls, and the data doors (CSV export, full backup &
// restore), all in warm second person.
struct InsightsView: View {
    @Environment(Theme.self) private var theme
    @Environment(CycleStore.self) private var store
    @Environment(RewardsStore.self) private var rewards

    private var p: CyclePrediction { store.prediction() }
    private let cal = Calendar.current

    @State private var showRestorePicker = false
    @State private var pendingRestore: Data? = nil
    @State private var restoreNote: String? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FFSpace.section) {
                header

                SampleBanner()

                // When the cycle report has something worth noting, it IS the
                // headline — it leads the screen. All quiet, it rests near the
                // bottom with the other data doors.
                if store.hasAnyLogs && !CycleReport.flags(store: store).isEmpty {
                    reportCard
                }

                if p.hasHistory {
                    summaryGrid
                    phaseReportCard
                    rhythmCard
                    symptomsCard
                } else {
                    emptyCard
                }

                flowChartCard

                tuningCard

                if store.hasAnyLogs {
                    if CycleReport.flags(store: store).isEmpty {
                        reportCard
                    }
                    exportCard
                }

                backupCard
            }
            .padding(.horizontal, FFSpace.s5)
            .padding(.top, FFSpace.s2)
            .padding(.bottom, FFSpace.s5)
        }
        .fileImporter(isPresented: $showRestorePicker, allowedContentTypes: [.json]) { result in
            guard case .success(let url) = result else { return }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            if let data = try? Data(contentsOf: url) {
                pendingRestore = data
            } else {
                restoreNote = "Couldn't read that file. Try picking it again."
            }
        }
        .confirmationDialog(
            "Replace everything on this phone with this backup?",
            isPresented: Binding(get: { pendingRestore != nil },
                                 set: { if !$0 { pendingRestore = nil } }),
            titleVisibility: .visible
        ) {
            Button("Replace & restore", role: .destructive) {
                guard let data = pendingRestore else { return }
                let ok = FFBackup.restore(data: data, store: store, rewards: rewards)
                restoreNote = ok ? "Restored. Everything's home again."
                                 : "That didn't look like a complete backup from this app, so nothing was changed."
                pendingRestore = nil
                if let note = restoreNote {
                    UIAccessibility.post(notification: .announcement, argument: note)
                }
            }
        } message: {
            Text("Your current history, settings and garden will be replaced by the backup's.")
        }
    }

    // MARK: header

    private var header: some View {
        VStack(alignment: .leading, spacing: FFSpace.s1) {
            Text("Insights")
                .font(ffDisplay(FFType.xl2, weight: .bold))
                .foregroundStyle(theme.color(.deep))
                .accessibilityAddTraits(.isHeader)
            Text(subtitle)
                .font(ffBody(FFType.sm))
                .foregroundStyle(theme.color(.muted))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @State private var csvURL: URL? = nil

    // A pre-written, shareable text report — front and center when something
    // changed (cycle length shifting, long bleeds, running late).
    private var reportCard: some View {
        let flags = CycleReport.flags(store: store)
        return FFCard(variant: flags.isEmpty ? .plain : .accent) {
            VStack(alignment: .leading, spacing: FFSpace.s2) {
                Label(flags.isEmpty ? "Cycle report: all quiet" : "Cycle report: \(flags.count) thing\(flags.count == 1 ? "" : "s") worth noting",
                      systemImage: flags.isEmpty ? "doc.text" : "exclamationmark.bubble")
                    .font(ffBody(FFType.md, weight: .semibold))
                    .foregroundStyle(theme.color(.deep))
                    .accessibilityAddTraits(.isHeader)
                ForEach(flags.prefix(2), id: \.self) { f in
                    HStack(alignment: .top, spacing: 8) {
                        Circle().fill(theme.color(.primaryStrong)).frame(width: 5, height: 5).padding(.top, 6)
                        Text(f).font(ffBody(FFType.sm)).foregroundStyle(theme.color(.text)).lineSpacing(2)
                    }
                }
                ShareLink(item: CycleReport.text(store: store)) {
                    Label("Share the report", systemImage: "square.and.arrow.up")
                        .font(ffBody(FFType.sm, weight: .bold))
                        .foregroundStyle(theme.color(.onPrimary))
                        .padding(.horizontal, 16).padding(.vertical, 9)
                        .background(theme.color(.primaryStrong), in: Capsule())
                }
            }
        }
    }

    // Every day she's logged, as a spreadsheet (CSV) for her own records.
    private var exportCard: some View {
        FFCard {
            VStack(alignment: .leading, spacing: FFSpace.s2) {
                Label("Your data, your spreadsheet", systemImage: "tablecells")
                    .font(ffBody(FFType.md, weight: .semibold))
                    .foregroundStyle(theme.color(.deep))
                    .accessibilityAddTraits(.isHeader)
                Text("Everything from the calendar (flow, discharge, temps, moods, symptoms, stretches, notes) as a CSV file.")
                    .font(ffBody(FFType.xs))
                    .foregroundStyle(theme.color(.muted))
                if let url = csvURL {
                    ShareLink(item: url) {
                        Label("Share the spreadsheet", systemImage: "square.and.arrow.up")
                            .font(ffBody(FFType.sm, weight: .bold))
                            .foregroundStyle(theme.color(.deep))
                            .padding(.horizontal, 16).padding(.vertical, 9)
                            .background(theme.color(.surfaceSoft), in: Capsule())
                    }
                } else {
                    FFButton("Prepare the spreadsheet", style: .soft, size: .sm, icon: "tablecells") {
                        csvURL = CycleReport.csvFile(store: store)
                    }
                }
            }
        }
    }

    // MARK: monthly flow chart

    private struct FlowChartPoint: Identifiable {
        let date: Date
        let weight: Int
        var id: Date { date }
    }

    /// The last 30 days of logged flow (0 on quiet days) plus a dashed
    /// projection of the next expected period, shaped by her own pattern.
    /// With no flow logged at all, a labeled one-month preview shows instead.
    private var flowChartCard: some View {
        let data = flowChartData()
        return FFCard {
            VStack(alignment: .leading, spacing: FFSpace.s2) {
                HStack {
                    cardTitle("Your flow, this month")
                    Spacer()
                    if data.isPreview {
                        Text("PREVIEW")
                            .font(ffBody(FFType.xs2, weight: .bold)).tracking(0.8)
                            .foregroundStyle(theme.color(.onPrimary))
                            .padding(.horizontal, 8).padding(.vertical, 2)
                            .background(theme.color(.primaryStrong), in: Capsule())
                    }
                }
                Chart {
                    ForEach(data.logged) { pt in
                        AreaMark(x: .value("Day", pt.date, unit: .day),
                                 y: .value("Flow", pt.weight),
                                 series: .value("Series", "Logged"))
                            .foregroundStyle(theme.color(.phaseMenstrual).opacity(0.14))
                            .interpolationMethod(.monotone)
                        LineMark(x: .value("Day", pt.date, unit: .day),
                                 y: .value("Flow", pt.weight),
                                 series: .value("Series", "Logged"))
                            .foregroundStyle(theme.color(.phaseMenstrual))
                            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .interpolationMethod(.monotone)
                    }
                    ForEach(data.projected) { pt in
                        LineMark(x: .value("Day", pt.date, unit: .day),
                                 y: .value("Flow", pt.weight),
                                 series: .value("Series", "Expected"))
                            .foregroundStyle(theme.color(.muted))
                            .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 4]))
                            .interpolationMethod(.monotone)
                    }
                }
                .chartYScale(domain: 0...5)
                .chartYAxis {
                    AxisMarks(values: [1, 3, 5]) { value in
                        AxisGridLine().foregroundStyle(theme.color(.line))
                        AxisValueLabel {
                            Text(yLabel(value.as(Int.self) ?? 0))
                                .font(ffBody(FFType.xs2, weight: .medium))
                                .foregroundStyle(theme.color(.muted))
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine().foregroundStyle(theme.color(.line))
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .font(ffBody(FFType.xs2, weight: .medium))
                            .foregroundStyle(theme.color(.muted))
                    }
                }
                .chartLegend(.hidden)
                .frame(height: 150)
                .accessibilityLabel(chartA11y(data))

                HStack(spacing: FFSpace.s4) {
                    legendSwatch(dashed: false, label: data.isPreview ? "A month like yours could look" : "What you logged")
                    if !data.projected.isEmpty {
                        legendSwatch(dashed: true, label: "Next period, as expected")
                    }
                    Spacer(minLength: 0)
                }
                if data.isPreview {
                    Text("This becomes your own curve as you log your flow.")
                        .font(ffBody(FFType.xs))
                        .foregroundStyle(theme.color(.muted))
                }
            }
        }
    }

    private func yLabel(_ w: Int) -> String {
        switch w {
        case 1: "Spotting"
        case 3: "Medium"
        case 5: "Super"
        default: ""
        }
    }

    private func legendSwatch(dashed: Bool, label: String) -> some View {
        HStack(spacing: 5) {
            LegendLine(dashed: dashed)
                .stroke(dashed ? theme.color(.muted) : theme.color(.phaseMenstrual),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round,
                                           dash: dashed ? [4, 3] : []))
                .frame(width: 18, height: 3)
            Text(label)
                .font(ffBody(FFType.xs2, weight: .medium))
                .foregroundStyle(theme.color(.muted))
        }
    }

    private func chartA11y(_ data: (logged: [FlowChartPoint], projected: [FlowChartPoint], isPreview: Bool)) -> String {
        if data.isPreview { return "A preview flow chart. It fills in with your own flow as you log." }
        let peak = data.logged.max { $0.weight < $1.weight }
        var out = "Flow over the last 30 days."
        if let peak, peak.weight > 0 {
            out += " Heaviest on \(peak.date.formatted(.dateTime.month(.wide).day()))."
        }
        if let first = data.projected.first(where: { $0.weight > 0 }) {
            out += " The next period is expected around \(first.date.formatted(.dateTime.month(.wide).day()))."
        }
        return out
    }

    private func flowChartData() -> (logged: [FlowChartPoint], projected: [FlowChartPoint], isPreview: Bool) {
        let today = cal.startOfDay(for: Date())
        let hasFlow = store.logsSnapshot.contains { $0.flow != nil }

        // First-month preview: a gentle example so the card teaches itself.
        guard hasFlow else {
            guard let start = cal.date(byAdding: .day, value: -29, to: today) else {
                return ([], [], true)
            }
            let example = [0, 0, 0, 2, 4, 4, 3, 2, 1] + Array(repeating: 0, count: 21)
            let pts = example.enumerated().compactMap { i, w in
                cal.date(byAdding: .day, value: i, to: start).map { FlowChartPoint(date: $0, weight: w) }
            }
            return (pts, [], true)
        }

        var logged: [FlowChartPoint] = []
        for off in -29...0 {
            if let d = cal.date(byAdding: .day, value: off, to: today) {
                logged.append(FlowChartPoint(date: d, weight: store.log(for: d)?.flow?.weight ?? 0))
            }
        }

        // Projection: dashes from tomorrow through the predicted period's end,
        // shaped by her own per-day intensity averages (a soft bell until then).
        var projected: [FlowChartPoint] = []
        if let next = p.nextPeriodStart {
            let start = cal.startOfDay(for: next)
            let len = max(p.averagePeriodLength, 1)
            let pattern = projectedPattern(len: len)
            if let end = cal.date(byAdding: .day, value: len - 1, to: start),
               var d = cal.date(byAdding: .day, value: 1, to: today) {
                while d <= end, (cal.dateComponents([.day], from: today, to: d).day ?? 99) <= 35 {
                    let k = cal.dateComponents([.day], from: start, to: d).day ?? -1
                    let w = (k >= 0 && k < len) ? pattern[min(k, pattern.count - 1)] : 0
                    projected.append(FlowChartPoint(date: d, weight: w))
                    guard let n = cal.date(byAdding: .day, value: 1, to: d) else { break }
                    d = n
                }
            }
        }
        return (logged, projected, false)
    }

    /// Her average intensity for each period day, from every logged period;
    /// days she's never logged fall back to a gentle bell.
    private func projectedPattern(len: Int) -> [Int] {
        var bell = [3, 4, 4, 3, 2, 1]
        while bell.count < len { bell.append(1) }
        let starts = CycleEngine.periodStarts(from: store.periodDays, cal: cal)
        var sums = Array(repeating: 0, count: len)
        var counts = Array(repeating: 0, count: len)
        for s in starts {
            for k in 0..<len {
                if let d = cal.date(byAdding: .day, value: k, to: s),
                   let w = store.log(for: d)?.flow?.weight {
                    sums[k] += w
                    counts[k] += 1
                }
            }
        }
        return (0..<len).map {
            counts[$0] > 0 ? Int((Double(sums[$0]) / Double(counts[$0])).rounded()) : bell[$0]
        }
    }

    // Tune your cycle — her numbers beat the math whenever she says so.
    private var tuningCard: some View {
        FFCard {
            VStack(alignment: .leading, spacing: FFSpace.s3) {
                cardTitle("Tune your cycle")
                Stepper(value: cycleLengthBinding, in: 18...45) {
                    Text("Cycle length · \(store.settings.defaultCycleLength) days")
                        .font(ffBody(FFType.sm, weight: .medium))
                        .foregroundStyle(theme.color(.text))
                }
                .tint(theme.color(.primaryStrong))
                Stepper(value: periodLengthBinding, in: 2...10) {
                    Text("Period length · \(store.settings.defaultPeriodLength) days")
                        .font(ffBody(FFType.sm, weight: .medium))
                        .foregroundStyle(theme.color(.text))
                }
                .tint(theme.color(.primaryStrong))
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Use my numbers, not the averages")
                            .font(ffBody(FFType.sm, weight: .semibold))
                            .foregroundStyle(theme.color(.text))
                        Text(lockCaption)
                            .font(ffBody(FFType.xs))
                            .foregroundStyle(theme.color(.muted))
                    }
                    Spacer(minLength: 4)
                    FFSwitch(isOn: lockBinding)
                        .accessibilityLabel("Use my cycle and period lengths instead of the logged averages")
                }
            }
        }
    }

    private var lockCaption: String {
        (store.settings.lockCycleLength ?? false)
            ? "Predictions follow both numbers above exactly."
            : "Off, your logged averages take over as history grows."
    }

    private var cycleLengthBinding: Binding<Int> {
        Binding(get: { store.settings.defaultCycleLength },
                set: { store.settings.defaultCycleLength = $0 })
    }
    private var periodLengthBinding: Binding<Int> {
        Binding(get: { store.settings.defaultPeriodLength },
                set: { store.settings.defaultPeriodLength = $0 })
    }
    private var lockBinding: Binding<Bool> {
        Binding(get: { store.settings.lockCycleLength ?? false },
                set: { store.settings.lockCycleLength = $0 })
    }

    // Backup & restore — one file with everything, hers to keep or carry to a
    // new phone. Always visible: restore matters most when this phone is empty.
    private var backupCard: some View {
        FFCard {
            VStack(alignment: .leading, spacing: FFSpace.s2) {
                Label("Backup & restore", systemImage: "externaldrive")
                    .font(ffBody(FFType.md, weight: .semibold))
                    .foregroundStyle(theme.color(.deep))
                    .accessibilityAddTraits(.isHeader)
                Text("One file with everything: history, settings and your whole garden. Save it somewhere safe, or bring it to a new phone.")
                    .font(ffBody(FFType.xs))
                    .foregroundStyle(theme.color(.muted))
                HStack(spacing: FFSpace.s2) {
                    // The file is built the moment she shares — always current.
                    ShareLink(item: FFBackup.ShareItem(store: store, rewards: rewards),
                              preview: SharePreview("Uncorked backup")) {
                        Label("Save a backup", systemImage: "arrow.down.doc")
                            .font(ffBody(FFType.sm, weight: .bold))
                            .foregroundStyle(theme.color(.deep))
                            .padding(.horizontal, 16).padding(.vertical, 9)
                            .background(theme.color(.surfaceSoft), in: Capsule())
                    }
                    FFButton("Restore", style: .ghost, size: .sm, icon: "arrow.counterclockwise") {
                        showRestorePicker = true
                    }
                }
                if let note = restoreNote {
                    Text(note)
                        .font(ffBody(FFType.xs, weight: .medium))
                        .foregroundStyle(theme.color(.muted))
                }
            }
        }
    }

    // The research report for where she is right now — the same short report
    // the ring's phase sheet shows, sitting right under the summary tiles so
    // what this week feels like (and what the evidence says helps) is never
    // more than one scroll away.
    @ViewBuilder private var phaseReportCard: some View {
        if let phase = p.phase {
            let report = PhaseResearch.report(for: phase,
                                              day: p.cycleDay ?? 1,
                                              cycleLength: max(p.averageCycleLength, 1))
            FFCard {
                VStack(alignment: .leading, spacing: FFSpace.s2) {
                    HStack(spacing: 8) {
                        Circle().fill(theme.color(CycleRing.tint(phase))).frame(width: 10, height: 10)
                        Text("Right now · \(report.title)")
                            .font(ffBody(FFType.md, weight: .semibold))
                            .foregroundStyle(theme.color(.deep))
                    }
                    .accessibilityAddTraits(.isHeader)
                    Text(report.body)
                        .font(ffBody(FFType.sm))
                        .foregroundStyle(theme.color(.text))
                        .lineSpacing(3)
                    ForEach(report.tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 8) {
                            Circle().fill(theme.color(CycleRing.tint(phase)))
                                .frame(width: 5, height: 5).padding(.top, 6)
                            Text(tip).font(ffBody(FFType.sm)).foregroundStyle(theme.color(.text))
                        }
                    }
                    Text(report.evidenceNote)
                        .font(ffBody(FFType.xs))
                        .foregroundStyle(theme.color(.muted))
                        .lineSpacing(2)
                        .padding(.top, 2)
                }
            }
        }
    }

    private var subtitle: String {
        guard p.hasHistory else { return "Let's find your rhythm." }
        if let d = p.daysUntilNextPeriod, d >= 0 {
            return "Your next period is about \(d) \(d == 1 ? "day" : "days") away."
        }
        return "The patterns behind your cycle, gathered gently."
    }

    // MARK: summary tiles

    private var summaryGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: FFSpace.s3), GridItem(.flexible())],
            spacing: FFSpace.s3
        ) {
            StatTile(title: "Avg cycle", value: "\(p.averageCycleLength)", unit: "days", tint: .primary)
            StatTile(title: "Avg period", value: "\(p.averagePeriodLength)", unit: "days", tint: .phaseMenstrual)
            StatTile(title: "Cycles tracked", value: "\(cyclesTracked)", tint: .deep)
            StatTile(title: "Days logged", value: "\(store.logsSnapshot.count)", tint: .primaryStrong)
        }
    }

    private var cyclesTracked: Int {
        CycleEngine.periodStarts(from: store.periodDays, cal: cal).count
    }

    // MARK: rhythm chart

    private var rhythmCard: some View {
        FFCard {
            VStack(alignment: .leading, spacing: FFSpace.s3) {
                cardTitle("Your rhythm")
                IntensityBar(label: "Cycle length · \(p.averageCycleLength) days",
                             value: Double(p.averageCycleLength), max: 40, tint: .primary)
                IntensityBar(label: "Period length · \(p.averagePeriodLength) days",
                             value: Double(p.averagePeriodLength), max: 10, tint: .phaseMenstrual)
            }
        }
    }

    // MARK: symptom frequency chart

    @ViewBuilder private var symptomsCard: some View {
        let counts = symptomCounts()
        if !counts.isEmpty {
            let maxCount = Double(counts.first?.count ?? 1)
            FFCard {
                VStack(alignment: .leading, spacing: FFSpace.s3) {
                    cardTitle("What you feel most")
                    ForEach(counts.prefix(5), id: \.name) { item in
                        IntensityBar(label: "\(item.name) · \(item.count)×",
                                     value: Double(item.count), max: maxCount, tint: .primary)
                    }
                }
            }
        }
    }

    private func symptomCounts() -> [(name: String, count: Int)] {
        var tally: [Symptom: Int] = [:]
        for log in store.logsSnapshot { for s in log.symptoms { tally[s, default: 0] += 1 } }
        return tally.map { (name: $0.key.label, count: $0.value) }.sorted { $0.count > $1.count }
    }

    // MARK: empty state

    private var emptyCard: some View {
        FFCard(variant: .soft) {
            VStack(spacing: FFSpace.s2) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(theme.color(.primary))
                Text("Your patterns will appear here")
                    .font(ffBody(FFType.md, weight: .semibold))
                    .foregroundStyle(theme.color(.deep))
                Text("Log a few cycles and you'll see your average rhythm, the symptoms you feel most, and when your next period is due.")
                    .font(ffBody(FFType.sm))
                    .foregroundStyle(theme.color(.muted))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FFSpace.s4)
        }
    }

    // MARK: bits

    private func cardTitle(_ text: String) -> some View {
        Text(text)
            .font(ffBody(FFType.md, weight: .semibold))
            .foregroundStyle(theme.color(.deep))
            .accessibilityAddTraits(.isHeader)
    }
}

/// A short horizontal stroke for the chart legend swatches.
private struct LegendLine: Shape {
    var dashed: Bool
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return p
    }
}
