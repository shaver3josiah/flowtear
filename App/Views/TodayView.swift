import SwiftUI

// Today — the warm home screen: a time-of-day greeting, the CycleRing hero with
// a drifting-petal accent, the current phase, a "next bloom" countdown, a quick
// flow log, and the cycle-day / next-bloom / phase stat tiles. Empty state is
// just the bloom + a no-pressure nudge. Composed entirely from DS components.
struct TodayView: View {
    @Environment(Theme.self) private var theme
    @Environment(CycleStore.self) private var store
    var onLog: (Date) -> Void

    private var p: CyclePrediction { store.prediction() }
    private var today: Date { Date() }

    var body: some View {
        ScrollView {
            VStack(spacing: FFSpace.card) {
                header
                if p.hasHistory {
                    hero
                    quickLog
                    statsGrid
                } else {
                    emptyState
                }
            }
            .padding(.horizontal, FFSpace.s5)
            .padding(.top, FFSpace.s2)
            .padding(.bottom, FFSpace.s6)
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 11) {
            FlowerMark(size: 38).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(ffDisplay(FFType.xl, weight: .semibold))
                    .foregroundStyle(theme.color(.deep))
                Text(today.formatted(.dateTime.weekday(.wide).month().day()))
                    .font(ffBody(FFType.xs))
                    .foregroundStyle(theme.color(.muted))
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 2)
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: today) {
        case 5..<12:  "Good morning, love"
        case 12..<17: "Good afternoon, love"
        case 17..<22: "Good evening, love"
        default:      "Hello, love"
        }
    }

    // MARK: Hero (ring + petal accent + phase + next-bloom line)

    private var hero: some View {
        ZStack {
            // Subtle drifting-petal accent behind the ring. PetalRain self-gates
            // reduce-motion (renders nothing) and ignores hit-testing.
            PetalRain(count: 10)
                .frame(height: 300)

            VStack(spacing: 10) {
                CycleRing(prediction: p, size: 244)
                PhaseBadge(phase: p.phase)
                Text(nextBloomLine)
                    .font(ffBody(FFType.sm, weight: .medium))
                    .foregroundStyle(theme.color(.muted))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 2)
    }

    private var nextBloomLine: String {
        guard let d = p.daysUntilNextPeriod else { return "" }
        switch d {
        case let n where n > 1: return "Your next bloom is in \(n) days"
        case 1:                 return "Your next bloom is tomorrow"
        case 0:                 return "Your next bloom is expected today"
        default:                return "Gentle heads-up — your bloom is \(abs(d)) \(abs(d) == 1 ? "day" : "days") late"
        }
    }

    // MARK: Quick flow log

    private var quickLog: some View {
        FFCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("How's your flow today?")
                    .font(ffBody(FFType.md, weight: .semibold))
                    .foregroundStyle(theme.color(.deep))
                FlowScale(selection: flowBinding)
                FFButton("Log mood & symptoms", style: .ghost, size: .sm, icon: "plus") {
                    onLog(today)
                }
            }
        }
    }

    // Today's flow, read from and written straight back to the store.
    private var flowBinding: Binding<Flow?> {
        Binding(
            get: { store.log(for: today)?.flow },
            set: { newValue in
                var log = store.log(for: today) ?? DayLog(dateKey: store.key(for: today))
                log.flow = newValue
                store.upsert(log)
            }
        )
    }

    // MARK: Stat tiles

    private var statsGrid: some View {
        HStack(spacing: 10) {
            StatTile(title: "Cycle day",
                     value: p.cycleDay.map(String.init) ?? "–",
                     tint: .primary)
            StatTile(title: "Next bloom",
                     value: nextBloomValue,
                     unit: nextBloomUnit,
                     tint: .phaseMenstrual)
            StatTile(title: "Phase",
                     value: p.phase?.label ?? "–",
                     tint: p.phase.map(CycleRing.tint) ?? .primary)
        }
    }

    private var nextBloomValue: String {
        guard let d = p.daysUntilNextPeriod else { return "–" }
        return String(abs(d))
    }
    private var nextBloomUnit: String? {
        guard let d = p.daysUntilNextPeriod else { return nil }
        return d < 0 ? "late" : "days"
    }

    // MARK: Empty state

    private var emptyState: some View {
        FFCard {
            VStack(spacing: 16) {
                Button {
                    onLog(today)
                } label: {
                    FlowerMark(size: 120, breathe: true)
                        .frame(width: 120, height: 120)
                }
                .buttonStyle(FFPressButtonStyle())
                .accessibilityLabel("Log today")
                .accessibilityHint("Records your first day to start predictions")

                Text("Nothing logged yet")
                    .font(ffDisplay(FFType.lg, weight: .semibold))
                    .foregroundStyle(theme.color(.deep))
                Text("Tap the bloom to start. No pressure.")
                    .font(ffBody(FFType.sm))
                    .foregroundStyle(theme.color(.muted))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FFSpace.s5)
        }
    }
}
