import SwiftUI

// Today — the home screen: the CycleRing hero with a drifting-petal accent, the
// current phase, a next-period countdown, a quick flow log, the cycle-day /
// next-period / phase stat tiles, and the fertile-window + basal-temperature
// section. Composed entirely from DS components.
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
                    StretchPlanCard()
                    FertileWindowCard()
                } else {
                    emptyState
                }
            }
            .padding(.horizontal, FFSpace.s5)
            .padding(.top, FFSpace.s2)
            .padding(.bottom, FFSpace.s6)
        }
    }

    // MARK: Header (weekday + date — no greeting)

    private var header: some View {
        HStack(spacing: 11) {
            FlowerMark(size: 38).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(today.formatted(.dateTime.weekday(.wide)))
                    .font(ffDisplay(FFType.xl, weight: .semibold))
                    .foregroundStyle(theme.color(.deep))
                Text(today.formatted(.dateTime.month().day()))
                    .font(ffBody(FFType.xs))
                    .foregroundStyle(theme.color(.muted))
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 2)
    }

    // MARK: Hero (ring + petal accent + phase + next-period line)

    private var hero: some View {
        ZStack {
            // Subtle drifting-petal accent behind the ring. PetalRain self-gates
            // reduce-motion (renders nothing) and ignores hit-testing.
            PetalRain(count: 10)
                .frame(height: 300)

            VStack(spacing: 10) {
                CycleRing(prediction: p, size: 244)
                PhaseBadge(phase: p.phase)
                Text(nextPeriodLine)
                    .font(ffBody(FFType.sm, weight: .medium))
                    .foregroundStyle(theme.color(.muted))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 2)
    }

    private var nextPeriodLine: String {
        guard let d = p.daysUntilNextPeriod else { return "" }
        switch d {
        case let n where n > 1: return "Your next period is in \(n) days"
        case 1:                 return "Your next period is tomorrow"
        case 0:                 return "Your next period is expected today"
        default:                return "Your period is \(abs(d)) \(abs(d) == 1 ? "day" : "days") late"
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
            StatTile(title: "Next period",
                     value: nextPeriodValue,
                     unit: nextPeriodUnit,
                     tint: .phaseMenstrual)
            StatTile(title: "Phase",
                     value: p.phase?.label ?? "–",
                     tint: p.phase.map(CycleRing.tint) ?? .primary)
        }
    }

    private var nextPeriodValue: String {
        guard let d = p.daysUntilNextPeriod else { return "–" }
        return String(abs(d))
    }
    private var nextPeriodUnit: String? {
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
                Text("Tap to log your first period.")
                    .font(ffBody(FFType.sm))
                    .foregroundStyle(theme.color(.muted))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FFSpace.s5)
        }
    }
}
