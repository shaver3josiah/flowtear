import SwiftUI

// Today — the home screen: the CycleRing hero with a drifting-petal accent, the
// current phase, a next-period countdown, a quick flow log, the cycle-day /
// next-period / phase stat tiles, and the fertile-window + basal-temperature
// section. Composed entirely from DS components.
struct TodayView: View {
    @Environment(Theme.self) private var theme
    @Environment(CycleStore.self) private var store
    @Environment(RewardsStore.self) private var rewards
    var onLog: (Date) -> Void
    var onOpenStretch: () -> Void = {}
    var onOpenInsights: () -> Void = {}
    var onOpenCalendar: () -> Void = {}

    private var p: CyclePrediction { store.prediction() }
    private var today: Date { Date() }
    @State private var showThemeEditor = false
    @State private var paneIndex = 0
    @State private var stickerDrag: CGSize = .zero
    private let paneTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: FFSpace.card) {
                header
                SampleBanner()
                if p.hasHistory {
                    hero
                    quickLog
                    rotatingPane
                    FertileWindowCard()
                } else if store.hasAnyLogs {
                    // She's logging (moods, temps…) but hasn't recorded a period
                    // yet — say so honestly instead of "nothing logged yet".
                    startedState
                    quickLog
                    rotatingPane
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
            FlowerMark(size: 38)
                .accessibilityHidden(true)
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

            stickerOverlay
        }
        .padding(.vertical, 2)
    }

    // Her flower sticker, placeable anywhere around the ring: drag it, it stays.
    @ViewBuilder private var stickerOverlay: some View {
        if let id = rewards.activeSticker {
            let radius: CGFloat = 118
            StickerView(id: id, size: 32)
                .offset(x: CGFloat(rewards.stickerX) * radius + stickerDrag.width,
                        y: CGFloat(rewards.stickerY) * radius + stickerDrag.height)
                .highPriorityGesture(
                    DragGesture()
                        .onChanged { v in stickerDrag = v.translation }
                        .onEnded { v in
                            let nx = rewards.stickerX + Double(v.translation.width / radius)
                            let ny = rewards.stickerY + Double(v.translation.height / radius)
                            rewards.stickerX = min(max(nx, -1.15), 1.15)
                            rewards.stickerY = min(max(ny, -1.15), 1.15)
                            stickerDrag = .zero
                        }
                )
                .accessibilityLabel("Your flower sticker")
                .accessibilityHint("Drag to place it around the ring")
        }
    }

    // The bottom pane takes turns: the stretch plan, then a peek at Insights,
    // then the Calendar — a fresh nudge every ten seconds, all tappable.
    private var rotatingPane: some View {
        Group {
            switch paneIndex {
            case 1:
                teaserCard(icon: "chart.bar.fill", tint: .primaryStrong,
                           title: "Insights",
                           line: "Your averages, rhythms and top symptoms — all from what you log.",
                           action: onOpenInsights)
            case 2:
                teaserCard(icon: "calendar", tint: .phaseFertile,
                           title: "Calendar",
                           line: "Your whole month at a glance — periods, fertile days, stretches.",
                           action: onOpenCalendar)
            default:
                StretchPlanCard(action: onOpenStretch)
            }
        }
        .id(paneIndex)
        .transition(.ffViewIn)
        .onReceive(paneTimer) { _ in
            withAnimation(FFMotion.signature) { paneIndex = (paneIndex + 1) % 3 }
        }
    }

    private func teaserCard(icon: String, tint: Tok, title: String,
                            line: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            FFCard {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(theme.color(tint))
                        .frame(width: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(ffBody(FFType.md, weight: .semibold))
                            .foregroundStyle(theme.color(.deep))
                        Text(line)
                            .font(ffBody(FFType.sm))
                            .foregroundStyle(theme.color(.muted))
                            .lineLimit(2).minimumScaleFactor(0.85)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(theme.color(.muted))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens \(title)")
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

    // Logged something, but no period days yet — predictions are waiting.
    private var startedState: some View {
        FFCard {
            VStack(spacing: 12) {
                FlowerMark(size: 72, breathe: true)
                    .frame(width: 72, height: 72)
                    .accessibilityHidden(true)
                Text("Your log is growing")
                    .font(ffDisplay(FFType.lg, weight: .semibold))
                    .foregroundStyle(theme.color(.deep))
                Text("Lovely start. The cycle ring and predictions appear once you log your first period days — light, medium or heavy flow.")
                    .font(ffBody(FFType.sm))
                    .foregroundStyle(theme.color(.muted))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FFSpace.s3)
        }
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
