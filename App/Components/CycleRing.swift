import SwiftUI

// CycleRing — the hero cycle visualization (DS tracking/CycleRing). A soft donut
// walked day-by-day: the bleed days, the fertile window and ovulation are marked
// in their phase colors, with a knob on today. Center shows the current cycle day
// + phase. Binds to CyclePrediction; derives the fertile window & ovulation from
// the standard 14-day-luteal model, exactly like the DS. Whole thing is one
// VoiceOver element ("Cycle day 14 of 28, fertile phase").
struct CycleRing: View {
    @Environment(Theme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let prediction: CyclePrediction
    var size: CGFloat = 260

    @State private var progress: Double = 0

    // Derived cycle numbers (clamped so geometry never divides by zero).
    private var cycleLength: Int { max(prediction.averageCycleLength, 1) }
    private var periodLength: Int { max(prediction.averagePeriodLength, 1) }
    private var cycleDay: Int { prediction.cycleDay ?? 1 }
    private var phase: CyclePhase {
        prediction.phase ?? Self.phaseForDay(cycleDay, cycleLength: cycleLength, periodLength: periodLength)
    }

    var body: some View {
        let c = Self.computeCycle(cycleLength: cycleLength, periodLength: periodLength)
        let cl = Double(cycleLength)
        let k = size / 200
        let radius = 84 * k
        let stroke = 15 * k
        let center = size / 2
        let reveal: Double = reduceMotion ? 1 : progress

        // Knob sits on today (mid-cell), in phase color.
        let knobFrac = (Double(cycleDay) - 0.5) / cl
        let knobAngle = (knobFrac * 360 - 90) * .pi / 180
        let kx = center + radius * CGFloat(cos(knobAngle))
        let ky = center + radius * CGFloat(sin(knobAngle))

        ZStack {
            // Soft full track.
            Circle()
                .inset(by: stroke / 2)
                .stroke(theme.color(.surfaceSoft), lineWidth: stroke)
                .padding(stroke / 2)

            // Bleed days.
            arc(0, Double(periodLength) / cl, reveal, color: theme.color(.phaseMenstrual), width: stroke)
            // Fertile window through ovulation.
            arc(Double(c.fertileStart - 1) / cl, Double(c.ovDay + 1) / cl, reveal,
                color: theme.color(.phaseFertile), width: stroke)
            // Ovulation peak.
            arc((Double(c.ovDay) - 0.6) / cl, (Double(c.ovDay) + 0.6) / cl, reveal,
                color: theme.color(.phaseOvulation), width: stroke)

            // Today knob.
            ZStack {
                Circle()
                    .fill(theme.color(.surface))
                    .overlay(Circle().strokeBorder(theme.color(Self.tint(phase)), lineWidth: 4 * k))
                    .frame(width: (stroke + 8 * k), height: (stroke + 8 * k))
                Circle()
                    .fill(theme.color(Self.tint(phase)))
                    .frame(width: 6 * k, height: 6 * k)
            }
            .scaleEffect(reveal)
            .position(x: kx, y: ky)

            // Center readout.
            VStack(spacing: 2) {
                Text(phase.label.uppercased())
                    .font(ffBody(FFType.xs, weight: .semibold))
                    .tracking(1)
                    // Deep plum, not the phase tint — fertile-gold/follicular-pink
                    // fail WCAG as 11pt text on white. The arc + knob carry phase color.
                    .foregroundStyle(theme.color(.deep))
                Text("\(cycleDay)")
                    .font(ffNumber(size * 0.26, weight: .semibold))
                    .foregroundStyle(theme.color(.deep))
                Text("day of your cycle")
                    .font(ffBody(FFType.sm))
                    .foregroundStyle(theme.color(.muted))
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isImage)
        .accessibilityLabel("Cycle day \(cycleDay) of \(cycleLength), \(phase.label.lowercased()) phase")
        .onAppear {
            guard !reduceMotion else { progress = 1; return }
            withAnimation(FFMotion.signature) { progress = 1 }
        }
    }

    // One colored phase arc, revealed clockwise-from-top up to `reveal` (0…1 of
    // the whole ring). Rounded caps, matching the DS SVG arcs.
    private func arc(_ from: Double, _ to: Double, _ reveal: Double, color: Color, width: CGFloat) -> some View {
        PhaseArc(fromFrac: from, toFrac: to, reveal: reveal)
            .stroke(color, style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    // MARK: - Standard cycle model (shared with CycleRing.jsx)

    struct Derived { let ovDay: Int; let fertileStart: Int }

    static func computeCycle(cycleLength: Int, periodLength: Int) -> Derived {
        let ovDay = min(max(cycleLength - 14, periodLength + 1), cycleLength - 1)
        let fertileStart = max(ovDay - 5, periodLength + 1)
        return Derived(ovDay: ovDay, fertileStart: fertileStart)
    }

    /// Phase for any 1-based cycle day, from cycleLength/periodLength (14-day luteal).
    static func phaseForDay(_ day: Int, cycleLength: Int, periodLength: Int) -> CyclePhase {
        let c = computeCycle(cycleLength: cycleLength, periodLength: periodLength)
        if day <= periodLength { return .menstrual }
        if day < c.fertileStart { return .follicular }
        if day < c.ovDay { return .fertile }
        if day <= c.ovDay + 1 { return .ovulation }
        return .luteal
    }

    /// Phase → its full-strength color token (arc/knob/label tint).
    static func tint(_ phase: CyclePhase) -> Tok {
        switch phase {
        case .menstrual:  .phaseMenstrual
        case .follicular: .phaseFollicular
        case .fertile:    .phaseFertile
        case .ovulation:  .phaseOvulation
        case .luteal:     .phaseLuteal
        }
    }

    /// Phase → its soft-wash color token (badges, cells).
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

// A single arc segment [fromFrac, toFrac] of the ring, revealed up to `reveal`.
// `reveal` is the animatable sweep (0…1 of the whole ring) so the fill grows
// clockwise from 12 o'clock. Sampled as a polyline to keep the geometry exact
// and free of addArc's coordinate-flag ambiguity.
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
        let steps = max(2, Int((end - fromFrac) * 360 / 4))  // ~every 4°
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

// ponytail: knob rides on `reveal` scale-in rather than sweeping the leading edge —
// same "fill" read, no path-length bookkeeping. Add a riding knob if design asks.
