import SwiftUI
import UIKit
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
                restoreNote = "Couldn't read that file — try picking it again."
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
                restoreNote = ok ? "Restored — everything's home again."
                                 : "That didn't look like a complete backup from this app — nothing was changed."
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
                Label(flags.isEmpty ? "Cycle report — all quiet" : "Cycle report — \(flags.count) thing\(flags.count == 1 ? "" : "s") worth noting",
                      systemImage: flags.isEmpty ? "doc.text" : "exclamationmark.bubble")
                    .font(ffBody(FFType.md, weight: .semibold))
                    .foregroundStyle(theme.color(.deep))
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
                Text("Everything from the calendar — flow, discharge, temps, moods, symptoms, stretches, notes — as a CSV file.")
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
                Text("One file with everything — history, settings and your whole garden. Save it somewhere safe, or bring it to a new phone.")
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
