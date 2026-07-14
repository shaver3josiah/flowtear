import SwiftUI

// CycleRing — the interactive hero. Fixed phase arcs (bleed / fertile / ovulation)
// walk the cycle; a "today" pip and a draggable focus marker sit on the track.
// Drag anywhere on the ring to SCRUB through the cycle — the center readout and
// marker follow your finger with a light haptic. Tap to open the phase detail
// (insight right there). VoiceOver users adjust with swipe up/down.
struct CycleRing: View {
    @Environment(Theme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let prediction: CyclePrediction
    var size: CGFloat = 260

    @State private var progress: Double = 0
    @State private var focusedDay: Int? = nil      // nil = follows today
    @State private var dragging = false
    @State private var showDetail = false

    private var cycleLength: Int { max(prediction.averageCycleLength, 1) }
    private var periodLength: Int { max(prediction.averagePeriodLength, 1) }
    private var todayDay: Int { min(max(prediction.cycleDay ?? 1, 1), cycleLength) }
    private var focused: Int { min(max(focusedDay ?? todayDay, 1), cycleLength) }
    private var focusedPhase: CyclePhase {
        Self.phaseForDay(focused, cycleLength: cycleLength, periodLength: periodLength)
    }

    var body: some View {
        let c = Self.computeCycle(cycleLength: cycleLength, periodLength: periodLength)
        let cl = Double(cycleLength)
        let k = size / 200
        let radius = 84 * k
        let stroke = 15 * k
        let center = size / 2
        let reveal: Double = reduceMotion ? 1 : progress

        let (fx, fy) = point(forDay: focused, radius: radius, center: center, cl: cl)
        let (tx, ty) = point(forDay: todayDay, radius: radius, center: center, cl: cl)

        ZStack {
            Circle().inset(by: stroke / 2).stroke(theme.color(.surfaceSoft), lineWidth: stroke).padding(stroke / 2)

            arc(0, Double(periodLength) / cl, reveal, color: theme.color(.phaseMenstrual), width: stroke)
            arc(Double(c.fertileStart - 1) / cl, Double(c.ovDay + 1) / cl, reveal,
                color: theme.color(.phaseFertile), width: stroke)
            arc((Double(c.ovDay) - 0.6) / cl, (Double(c.ovDay) + 0.6) / cl, reveal,
                color: theme.color(.phaseOvulation), width: stroke)

            // Today pip — only shown (muted) when the focus has moved off today.
            Circle().fill(theme.color(.surface))
                .overlay(Circle().strokeBorder(theme.color(.muted), lineWidth: 2 * k))
                .frame(width: stroke * 0.7, height: stroke * 0.7)
                .position(x: tx, y: ty)
                .opacity(focused == todayDay ? 0 : 0.9)

            // Draggable focus marker (phase-colored, grows while dragging).
            ZStack {
                Circle().fill(theme.color(.surface))
                    .overlay(Circle().strokeBorder(theme.color(Self.tint(focusedPhase)), lineWidth: 4 * k))
                    .frame(width: stroke + 10 * k, height: stroke + 10 * k)
                Circle().fill(theme.color(Self.tint(focusedPhase))).frame(width: 7 * k, height: 7 * k)
            }
            .scaleEffect((dragging ? 1.15 : 1) * reveal)
            .shadow(color: theme.shadow, radius: dragging ? 6 : 0)
            .position(x: fx, y: fy)

            centerReadout
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        // High priority so scrubbing on the ring wins over the Today ScrollView;
        // dragging anywhere else on the page still scrolls normally.
        .highPriorityGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { v in
                    dragging = true
                    focusedDay = day(at: v.location, center: center)
                }
                .onEnded { v in
                    dragging = false
                    if hypot(v.translation.width, v.translation.height) < 8 { showDetail = true }  // a tap
                }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(a11yLabel)
        .accessibilityHint("Swipe up or down to explore days, double-tap for phase details")
        .accessibilityAdjustableAction { direction in
            let next = focused + (direction == .increment ? 1 : -1)
            focusedDay = min(max(next, 1), cycleLength)
        }
        .sensoryFeedback(.selection, trigger: focused)
        .onAppear {
            if reduceMotion { progress = 1 } else { withAnimation(FFMotion.signature) { progress = 1 } }
        }
        .sheet(isPresented: $showDetail) {
            PhaseDetailSheet(phase: focusedPhase, day: focused, cycleLength: cycleLength,
                             isToday: focused == todayDay, onJumpToToday: { focusedDay = nil })
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: center

    private var centerReadout: some View {
        VStack(spacing: 2) {
            Text(focusedPhase.label.uppercased())
                .font(ffBody(FFType.xs, weight: .semibold)).tracking(1)
                .foregroundStyle(theme.color(.deep))
            Text("\(focused)")
                .font(ffNumber(size * 0.26, weight: .semibold))
                .foregroundStyle(theme.color(.deep))
            Text(focused == todayDay ? "day of your cycle" : "tap for insight")
                .font(ffBody(FFType.sm))
                .foregroundStyle(theme.color(.muted))
        }
        .allowsHitTesting(false)   // taps fall through to the ring gesture
    }

    // MARK: geometry

    private func point(forDay d: Int, radius: CGFloat, center: CGFloat, cl: Double) -> (CGFloat, CGFloat) {
        let frac = (Double(d) - 0.5) / cl
        let a = (frac * 360 - 90) * .pi / 180
        return (center + radius * CGFloat(cos(a)), center + radius * CGFloat(sin(a)))
    }

    /// The 1-based cycle day under a point, from its angle around the center.
    private func day(at p: CGPoint, center: CGFloat) -> Int {
        var deg = atan2(p.y - center, p.x - center) * 180 / .pi + 90   // 0 at 12 o'clock, clockwise
        if deg < 0 { deg += 360 }
        return min(max(Int(deg / 360 * Double(cycleLength)) + 1, 1), cycleLength)
    }

    private func arc(_ from: Double, _ to: Double, _ reveal: Double, color: Color, width: CGFloat) -> some View {
        PhaseArc(fromFrac: from, toFrac: to, reveal: reveal)
            .stroke(color, style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    private var a11yLabel: String {
        "Cycle day \(focused) of \(cycleLength), \(focusedPhase.label.lowercased()) phase"
            + (focused == todayDay ? ", today" : "")
    }

    // MARK: - Standard cycle model (shared helpers)

    struct Derived { let ovDay: Int; let fertileStart: Int }

    static func computeCycle(cycleLength: Int, periodLength: Int) -> Derived {
        let ovDay = min(max(cycleLength - 14, periodLength + 1), cycleLength - 1)
        let fertileStart = max(ovDay - 5, periodLength + 1)
        return Derived(ovDay: ovDay, fertileStart: fertileStart)
    }

    static func phaseForDay(_ day: Int, cycleLength: Int, periodLength: Int) -> CyclePhase {
        let c = computeCycle(cycleLength: cycleLength, periodLength: periodLength)
        if day <= periodLength { return .menstrual }
        if day < c.fertileStart { return .follicular }
        if day < c.ovDay { return .fertile }
        if day <= c.ovDay + 1 { return .ovulation }
        return .luteal
    }

    static func tint(_ phase: CyclePhase) -> Tok {
        switch phase {
        case .menstrual:  .phaseMenstrual
        case .follicular: .phaseFollicular
        case .fertile:    .phaseFertile
        case .ovulation:  .phaseOvulation
        case .luteal:     .phaseLuteal
        }
    }

    static func softTint(_ phase: CyclePhase) -> Tok {
        switch phase {
        case .menstrual:  .phaseMenstrualSoft
        case .follicular: .phaseFollicularSoft
        case .fertile:    .phaseFertileSoft
        case .ovulation:  .phaseOvulationSoft
        case .luteal:     .phaseLutealSoft
        }
    }
}

// A single arc segment [fromFrac, toFrac] of the ring, revealed up to `reveal`,
// sampled as a polyline so the geometry stays exact.
private struct PhaseArc: Shape {
    var fromFrac: Double
    var toFrac: Double
    var reveal: Double
    var animatableData: Double { get { reveal } set { reveal = newValue } }

    func path(in rect: CGRect) -> Path {
        let end = min(toFrac, reveal)
        guard end > fromFrac else { return Path() }
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = 84 * (min(rect.width, rect.height) / 200)
        let steps = max(2, Int((end - fromFrac) * 360 / 4))
        var p = Path()
        for i in 0...steps {
            let f = fromFrac + (end - fromFrac) * Double(i) / Double(steps)
            let a = (f * 360 - 90) * .pi / 180
            let pt = CGPoint(x: c.x + r * CGFloat(cos(a)), y: c.y + r * CGFloat(sin(a)))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        return p
    }
}
