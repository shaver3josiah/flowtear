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

                if p.hasHistory {
                    summaryGrid
                    rhythmCard
                    symptomsCard
                    aheadCard
                } else {
                    emptyCard
                }

                if store.sampleActive {
                    sampleDataCard
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

    // Shown only while the first-launch demo data is active: a gentle way to
    // wipe it and start tracking for real. Never re-seeds after clearing.
    private var sampleDataCard: some View {
        FFCard(variant: .outline) {
            VStack(alignment: .leading, spacing: FFSpace.s2) {
                Text("You're looking at sample data")
                    .font(ffBody(FFType.md, weight: .semibold))
                    .foregroundStyle(theme.color(.deep))
                Text("Everything here is a 3-month preview so you can explore. When you're ready to track for real, clear it.")
                    .font(ffBody(FFType.sm))
                    .foregroundStyle(theme.color(.muted))
                FFButton("Clear sample data & start fresh", style: .soft, size: .sm, icon: "sparkles") {
                    store.clearSampleData()
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

    private var aheadCard: some View {
        FFCard(variant: .soft) {
            VStack(alignment: .leading, spacing: FFSpace.s3) {
                cardTitle("What's ahead")
                aheadRow("Next period", p.nextPeriodStart, .phaseFollicular)
                aheadRow("Fertile window opens", p.fertileStart, .phaseFertile)
                aheadRow("Ovulation, estimated", p.ovulationDate, .phaseOvulation)
            }
        }
    }

    private func aheadRow(_ label: String, _ date: Date?, _ tint: Tok) -> some View {
        let dateText = date?.formatted(.dateTime.month(.abbreviated).day()) ?? "—"
        return HStack(spacing: FFSpace.inline) {
            Circle().fill(theme.color(tint)).frame(width: 8, height: 8)
            Text(label)
                .font(ffBody(FFType.sm))
                .foregroundStyle(theme.color(.text))
            Spacer(minLength: FFSpace.s2)
            Text(dateText)
                .font(ffBody(FFType.sm, weight: .semibold))
                .foregroundStyle(theme.color(.deep))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(dateText)")
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
