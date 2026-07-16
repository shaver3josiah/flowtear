import SwiftUI

// Insights — the "what your cycle is telling you" screen. A StatTile summary
// grid, IntensityBar breakdown charts (rhythm + symptom frequency), and the
// upcoming-milestone rows, all in warm second person. Everything derives from
// `store.prediction()` + the raw logs; no state of its own.
struct InsightsView: View {
    @Environment(Theme.self) private var theme
    @Environment(CycleStore.self) private var store

    private var p: CyclePrediction { store.prediction() }
    private let cal = Calendar.current

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FFSpace.section) {
                header

                SampleBanner()

                if p.hasHistory {
                    summaryGrid
                    rhythmCard
                    symptomsCard
                } else {
                    emptyCard
                }

                if store.hasAnyLogs {
                    reportCard
                    exportCard
                }
            }
            .padding(.horizontal, FFSpace.s4)
            .padding(.top, FFSpace.s2)
            .padding(.bottom, FFSpace.s5)
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
                        .foregroundStyle(.white)
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

    // MARK: upcoming milestones

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
                Text("Log a few cycles and Uncorked will show your average rhythm, the symptoms you feel most, and when your next period is due.")
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
    }
}
