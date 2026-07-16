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
        let radius = Self.trackRadius(for: size)
        let stroke = 15 * k
        let center = size / 2
        let reveal: Double = reduceMotion ? 1 : progress

        let (fx, fy) = point(forDay: focused, radius: radius, center: center, cl: cl)
        let (tx, ty) = point(forDay: todayDay, radius: radius, center: center, cl: cl)

        ZStack {
            // The track — brushed-metal base band: a diagonal light so the whole
            // bangle reads as one polished piece under a single lamp.
            Circle().inset(by: stroke / 2)
                .stroke(theme.color(.surfaceSoft), lineWidth: stroke)
                .padding(stroke / 2)
            Circle().inset(by: stroke / 2)
                .stroke(metalSheen, lineWidth: stroke)
                .padding(stroke / 2)

            // Phase arcs — each stroked twice: its meaning color, then the same
            // shared top-light wash, so the arcs read as enamel inlays on the
            // same metal band (never flat printed color).
            Group {
                arc(0, Double(periodLength) / cl, reveal, color: theme.color(.phaseMenstrual), width: stroke)
                arc(Double(c.fertileStart - 1) / cl, Double(c.ovDay + 1) / cl, reveal,
                    color: theme.color(.phaseFertile), width: stroke)
                arc((Double(c.ovDay) - 0.6) / cl, (Double(c.ovDay) + 0.6) / cl, reveal,
                    color: theme.color(.phaseOvulation), width: stroke)
                arcSheen(0, Double(periodLength) / cl, reveal, width: stroke)
                arcSheen(Double(c.fertileStart - 1) / cl, Double(c.ovDay + 1) / cl, reveal, width: stroke)
                arcSheen((Double(c.ovDay) - 0.6) / cl, (Double(c.ovDay) + 0.6) / cl, reveal, width: stroke)
            }

            // A slow glint that circles the band — the light catching polished
            // metal as it turns. One narrow highlight, long rests implied by the
            // slow lap; masked to the ring so it never touches the readout.
            if !reduceMotion {
                RingGlint(inset: stroke)
            }

            // Today pip — only shown (muted) when the focus has moved off today,
            // so she can always find her way home to the current day.
            Circle().fill(theme.color(.surface))
                .overlay(Circle().strokeBorder(theme.color(.muted), lineWidth: 2 * k))
                .frame(width: stroke * 0.7, height: stroke * 0.7)
                .position(x: tx, y: ty)
                .opacity(focused == todayDay ? 0 : 0.9)

            // Draggable focus marker (phase-colored, grows while dragging).
            // On today it wears its jewel setting: a gold halo that breathes
            // and two tiny twinkles — the day she's on is the ring's gem.
            ZStack {
                if focused == todayDay {
                    TodayGlimmer(diameter: stroke + 22 * k)
                }
                Circle().fill(theme.color(.surface))
                    .overlay(Circle().strokeBorder(theme.color(Self.tint(focusedPhase)), lineWidth: 4 * k))
                    .overlay(
                        // Specular top-left kiss, so the marker is metal too.
                        Circle().strokeBorder(
                            LinearGradient(colors: [.white.opacity(0.55), .clear, .clear],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1.5 * k
                        )
                    )
                    .frame(width: stroke + 10 * k, height: stroke + 10 * k)
                Circle()
                    .fill(focused == todayDay
                          ? AnyShapeStyle(LinearGradient(
                                colors: [theme.color(.flowerCenter), theme.color(Self.tint(focusedPhase))],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                          : AnyShapeStyle(theme.color(Self.tint(focusedPhase))))
                    .frame(width: 7 * k, height: 7 * k)
            }
            .scaleEffect((dragging ? 1.15 : 1) * reveal)
            .shadow(color: theme.shadow, radius: dragging ? 6 : 0)
            .position(x: fx, y: fy)

            centerReadout
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        // High priority so scrubbing on the ring wins over the Today ScrollView;
        // dragging anywhere else on the page still scrolls normally. The center
        // is a DEAD ZONE for scrubbing: a tap on the big number (which invites
        // "tap for insight") must open the sheet for the day shown — never
        // scrub to whatever angle the finger happened to land on.
        .highPriorityGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { v in
                    let r = hypot(v.location.x - center, v.location.y - center)
                    guard r > Self.trackRadius(for: size) * 0.55 else { return }
                    dragging = true
                    focusedDay = day(at: v.location, center: center)
                }
                .onEnded { v in
                    dragging = false
                    if hypot(v.translation.width, v.translation.height) < 8 { showDetail = true }  // a tap
                }
        )
        .accessibilityElement(children: .ignore)
        // Label stays constant; the DAY lives in the value so VoiceOver
        // announces each swipe-up/-down adjustment as it happens.
        .accessibilityLabel("Cycle ring")
        .accessibilityValue(a11yLabel)
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
            Text(focused == todayDay ? "tap for today's insight" : "tap for insight")
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

    /// The shared "single lamp" wash: light from the top-left, a shadow toward
    /// the bottom-right. Laid over the track and every arc so the whole ring
    /// reads as one polished piece of metal.
    private var metalSheen: LinearGradient {
        LinearGradient(stops: [
            .init(color: .white.opacity(0.38), location: 0),
            .init(color: .white.opacity(0.08), location: 0.35),
            .init(color: .clear, location: 0.55),
            .init(color: .black.opacity(theme.isDarkMode ? 0.30 : 0.16), location: 1),
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private func arcSheen(_ from: Double, _ to: Double, _ reveal: Double, width: CGFloat) -> some View {
        PhaseArc(fromFrac: from, toFrac: to, reveal: reveal)
            .stroke(metalSheen, style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    private var a11yLabel: String {
        "Cycle day \(focused) of \(cycleLength), \(focusedPhase.label.lowercased()) phase"
            + (focused == todayDay ? ", today" : "")
    }

    // MARK: - Standard cycle model (shared helpers)

    /// Radius of the drawn track for a given ring size (arcs live at 84/200 of
    /// the design space). RingSticker orbits at exactly this radius so the
    /// flower beads onto the visible ring, concentric with it.
    static func trackRadius(for size: CGFloat) -> CGFloat { 84 * size / 200 }

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

// A slow glint that laps the band once every ~9 seconds — a narrow white
// highlight rotating continuously around the ring, masked to the band itself.
// It's the light catching polished metal as the bangle slowly turns: always
// somewhere on the band, never bright (peak 0.5 over a narrow window), and
// mounted only when motion is allowed.
private struct RingGlint: View {
    let inset: CGFloat
    @State private var angle: Double = 0

    var body: some View {
        AngularGradient(stops: [
            .init(color: .clear, location: 0),
            .init(color: .clear, location: 0.42),
            .init(color: .white.opacity(0.22), location: 0.48),
            .init(color: .white.opacity(0.5), location: 0.5),
            .init(color: .white.opacity(0.22), location: 0.52),
            .init(color: .clear, location: 0.58),
            .init(color: .clear, location: 1),
        ], center: .center)
        .rotationEffect(.degrees(angle))
        .mask(Circle().inset(by: inset / 2).stroke(lineWidth: inset).padding(inset / 2))
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.linear(duration: 9).repeatForever(autoreverses: false)) { angle = 360 }
        }
    }
}

// The gem setting for today: a soft gold halo that breathes, and two tiny
// four-point twinkles that alternate — the current day glimmers so it's
// unmissable and clearly the thing to touch. Mounted only on the today marker.
// Gates itself on Reduce Motion: the loops never start, and the halo plus one
// lit twinkle render static (information kept, motion dropped).
private struct TodayGlimmer: View {
    @Environment(Theme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let diameter: CGFloat

    @State private var breathe = false
    @State private var twinkle = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    AngularGradient(colors: [
                        theme.color(.flowerCenter).opacity(0.0),
                        theme.color(.flowerCenter).opacity(0.9),
                        theme.color(.flowerCenter).opacity(0.0),
                        theme.color(.flowerCenter).opacity(0.7),
                        theme.color(.flowerCenter).opacity(0.0),
                    ], center: .center),
                    lineWidth: 2.5
                )
                .frame(width: diameter, height: diameter)
                .scaleEffect(breathe ? 1.12 : 0.98)
                .opacity(breathe ? 0.55 : 0.95)
            FFTwinkle(size: 7, color: theme.color(.flowerCenter))
                .offset(x: -diameter * 0.42, y: -diameter * 0.34)
                .opacity(twinkle ? 1 : 0.15)
            FFTwinkle(size: 5, color: theme.color(.flowerCenter))
                .offset(x: diameter * 0.44, y: diameter * 0.28)
                .opacity(twinkle ? 0.2 : 1)
        }
        .allowsHitTesting(false)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) { breathe = true }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { twinkle = true }
        }
    }
}

/// A thin four-point sparkle (concave star) — shared by the today glimmer.
struct FFTwinkle: View {
    var size: CGFloat
    var color: Color

    var body: some View {
        TwinkleShape()
            .fill(color)
            .frame(width: size, height: size)
    }
}

private struct TwinkleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        let w = r * 0.3
        var p = Path()
        p.move(to: CGPoint(x: c.x, y: c.y - r))
        p.addQuadCurve(to: CGPoint(x: c.x + r, y: c.y), control: CGPoint(x: c.x + w, y: c.y - w))
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y + r), control: CGPoint(x: c.x + w, y: c.y + w))
        p.addQuadCurve(to: CGPoint(x: c.x - r, y: c.y), control: CGPoint(x: c.x - w, y: c.y + w))
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y - r), control: CGPoint(x: c.x - w, y: c.y - w))
        p.closeSubpath()
        return p
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
