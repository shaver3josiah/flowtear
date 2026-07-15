import SwiftUI

// Today — the home screen: the CycleRing hero with a drifting-petal accent, the
// current phase, a next-period countdown, a quick flow log, the cycle-day /
// next-period / phase stat tiles, and the fertile-window + basal-temperature
// section. Composed entirely from DS components.
struct TodayView: View {
    @Environment(Theme.self) private var theme
    @Environment(CycleStore.self) private var store
    var onLog: (Date) -> Void
    var onOpenStretch: () -> Void = {}

    private var p: CyclePrediction { store.prediction() }
    private var today: Date { Date() }
    @State private var showThemeEditor = false

    var body: some View {
        ScrollView {
            VStack(spacing: FFSpace.card) {
                header
                SampleBanner()
                if p.hasHistory {
                    hero
                    quickLog
                    StretchPlanCard(action: onOpenStretch)
                    FertileWindowCard()
                } else {
                    emptyState
                }
            }
            .padding(.horizontal, FFSpace.s5)
            .padding(.top, FFSpace.s2)
            .padding(.bottom, FFSpace.s6)
        }
        .sheet(isPresented: $showThemeEditor) {
            ThemeEditorSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: Header (weekday + date + the pencil, like Bloom)

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
            FFIconButton("pencil") { showThemeEditor = true }
                .accessibilityLabel("Theme settings")
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
                FFPickerSlider(
                    title: "How's your flow today?",
                    options: Flow.allCases,
                    label: { $0.label },
                    selection: flowBinding,
                    tint: .phaseMenstrual
                )
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
