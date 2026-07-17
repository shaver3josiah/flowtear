import SwiftUI
import UIKit

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
    /// Chained blooms minus the one riding as the draggable bead, so a worn
    /// bloom never renders twice on the ring.
    private var chainMinusBead: [String] {
        rewards.ringChain.filter { $0 != rewards.activeSticker }
    }
    private var today: Date { Date() }
    @State private var showThemeEditor = false
    @State private var showAbout = false
    @State private var showTips = false
    @State private var showShop = false
    @State private var paneIndex = 0
    @State private var undoToast: UndoAction? = nil
    @AppStorage("flowtear.petalsOnRing") private var petalsOnRing = true
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
                    // She's logging but no period is confirmed yet — show the
                    // ring anyway as a best-guess preview that sharpens with data.
                    previewHero
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
            ThemeEditorSheet(onGoEarn: {
                showThemeEditor = false
                onOpenStretch()
            })
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showAbout) { AboutView() }
        .sheet(isPresented: $showTips) { TipsSheet() }
        .sheet(isPresented: $showShop) {
            GardenShopView(onGoEarn: {
                showShop = false
                onOpenStretch()
            })
        }
        .overlay(alignment: .top) { undoToastView }
    }

    // MARK: Undo toast (one gentle chance to take a quick action back)

    @ViewBuilder private var undoToastView: some View {
        if let t = undoToast {
            HStack(spacing: 8) {
                Text(t.message)
                    .font(ffBody(FFType.sm, weight: .medium))
                    .foregroundStyle(theme.color(.text))
                Button {
                    t.undo()
                    withAnimation(FFMotion.fast) { undoToast = nil }
                } label: {
                    Text("Undo")
                        .font(ffBody(FFType.sm, weight: .bold))
                        .foregroundStyle(theme.color(.primaryStrong))
                        .frame(minWidth: FFSpace.tapMin, minHeight: FFSpace.tapMin)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, 16).padding(.trailing, 6).padding(.vertical, 4)
            .background(theme.color(.surface), in: Capsule())
            .overlay(Capsule().strokeBorder(theme.color(.line), lineWidth: 1))
            .shadow(color: theme.shadow, radius: 10, y: 6)
            .transition(.move(edge: .top).combined(with: .opacity))
            .task(id: t.id) {
                // Spoken confirmation, and much more time when VoiceOver is on —
                // an unheard toast that vanishes in 5s is no undo at all.
                UIAccessibility.post(notification: .announcement,
                                     argument: "\(t.message). Undo is available near the top of the screen.")
                let grace: Double = UIAccessibility.isVoiceOverRunning ? 20 : 5
                try? await Task.sleep(for: .seconds(grace))
                withAnimation(FFMotion.fast) {
                    if undoToast?.id == t.id { undoToast = nil }
                }
            }
        }
    }

    // MARK: Header (weekday + date + the pencil, like Bloom)

    private var header: some View {
        HStack(spacing: 11) {
            FlowerMark(size: 38)
                .onTapGesture(count: 2) { showAbout = true }
                .accessibilityLabel("About Uncorked")
                .accessibilityHint("Opens the about page and questions")
                .accessibilityAddTraits(.isButton)
            VStack(alignment: .leading, spacing: 2) {
                Text(today.formatted(.dateTime.weekday(.wide)))
                    .font(ffDisplay(FFType.xl, weight: .semibold))
                    .foregroundStyle(theme.color(.deep))
                Text(today.formatted(.dateTime.month().day()))
                    .font(ffBody(FFType.xs))
                    .foregroundStyle(theme.color(.muted))
            }
            Spacer(minLength: 0)
            FFIconButton("lightbulb") { showTips = true }
                .glitterHint("tips")
                .accessibilityLabel("Tips and hidden features")
            FFIconButton("pencil") { showThemeEditor = true }
                .glitterHint("themeEditor")
                .accessibilityLabel("Theme settings")
            FFIconButton("bag") { showShop = true }
                .glitterHint("todayShop")
                .accessibilityLabel("Garden shop")
        }
        .padding(.top, 2)
    }

    // MARK: Hero (ring + petal accent + phase + next-period line)

    private var hero: some View {
        ZStack {
            // Subtle drifting-petal accent behind the ring. PetalRain self-gates
            // reduce-motion (renders nothing) and ignores hit-testing; she can
            // switch it off in the pencil settings.
            if petalsOnRing {
                PetalRain(count: 10)
                    .frame(height: 300)
            }

            VStack(spacing: 10) {
                // The sticker shares the ring's ZStack so its orbit center IS the
                // ring's center, and it rides the drawn track's exact radius —
                // concentric, never offset.
                ZStack {
                    CycleRing(prediction: p, size: 244)
                    // Her daisy chain rides the ring beneath the draggable bead.
                    if !chainMinusBead.isEmpty {
                        RingChainView(chain: chainMinusBead,
                                      radius: CycleRing.trackRadius(for: 244))
                    }
                    RingSticker(radius: CycleRing.trackRadius(for: 244),
                                periodFraction: periodFraction(p))
                }
                PhaseBadge(phase: p.phase)
                Text(nextPeriodLine)
                    .font(ffBody(FFType.sm, weight: .medium))
                    .foregroundStyle(theme.color(.muted))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 2)
    }

    // The bottom pane takes turns: the stretch plan, then a peek at Insights,
    // then the Calendar — a fresh nudge every ten seconds, all tappable.
    private var rotatingPane: some View {
        Group {
            switch paneIndex {
            case 1:
                teaserCard(icon: "chart.bar.fill", tint: .primaryStrong,
                           title: "Insights",
                           line: "Your averages, rhythms and top symptoms, all from what you log.",
                           action: onOpenInsights)
            case 2:
                teaserCard(icon: "calendar", tint: .phaseFertile,
                           title: "Calendar",
                           line: "Your whole month at a glance: periods, fertile days, stretches.",
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

    /// Fraction of the ring covered by the bleed arc (day 1 → period length).
    private func periodFraction(_ pred: CyclePrediction) -> Double {
        min(Double(max(pred.averagePeriodLength, 0)) / Double(max(pred.averageCycleLength, 1)), 1)
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

    /// One tap when it matters most: her period is due (or late) and nothing is
    /// logged yet — no slider hunting on a crampy morning.
    private var showPeriodCTA: Bool {
        store.log(for: today)?.flow == nil
            && (p.daysUntilNextPeriod.map { $0 <= 2 } ?? false)
    }

    private var quickLog: some View {
        FFCard {
            VStack(alignment: .leading, spacing: 12) {
                if showPeriodCTA {
                    FFButton((p.daysUntilNextPeriod ?? 0) < 0 ? "My period started" : "My period started today",
                             style: .primary, icon: "drop.fill") {
                        var log = store.log(for: today) ?? DayLog(dateKey: store.key(for: today))
                        log.flow = .medium
                        store.upsert(log)
                        withAnimation(FFMotion.spring) {
                            undoToast = UndoAction(message: "Logged a medium flow for today") {
                                var l = store.log(for: today) ?? DayLog(dateKey: store.key(for: today))
                                l.flow = nil
                                store.upsert(l)
                            }
                        }
                    }
                }
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

    // A best-guess ring before her first confirmed period: anchored on any
    // bleeding (or her first log), clearly labeled as an estimate.
    private var previewHero: some View {
        VStack(spacing: 8) {
            ZStack {
                CycleRing(prediction: store.previewPrediction(), size: 220)
                if !chainMinusBead.isEmpty {
                    RingChainView(chain: chainMinusBead,
                                  radius: CycleRing.trackRadius(for: 220))
                }
                RingSticker(radius: CycleRing.trackRadius(for: 220),
                            periodFraction: periodFraction(store.previewPrediction()))
            }
            Text("A first guess. It sharpens as you log")
                .font(ffBody(FFType.xs, weight: .medium))
                .foregroundStyle(theme.color(.muted))
        }
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
                Text("Lovely start. The cycle ring and predictions appear once you log your first period days: light, medium or heavy flow.")
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

/// A just-taken quick action with one gentle chance to take it back.
struct UndoAction: Identifiable {
    let id = UUID()
    let message: String
    let undo: () -> Void
}
