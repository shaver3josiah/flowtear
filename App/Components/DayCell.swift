import SwiftUI

// DayCell — one day in the month calendar (DS tracking/DayCell). Layers a
// phase-soft wash, an optional dashed predicted ring, an amber ovulation ring,
// a gold glimmer on upcoming fertile days, a today ring, and a logged-flow
// dot. 44pt tap target; the state is spelled out in the accessibility label
// so nothing is conveyed by color alone.
struct DayCell: View {
    @Environment(Theme.self) private var theme

    let day: Int
    let isToday: Bool
    let isPeriod: Bool
    let isPredicted: Bool
    let isFertile: Bool
    let isOvulation: Bool
    var flow: Flow? = nil
    var stretchDone: Bool = false
    /// Upcoming fertile days glimmer; `shimmerDelay` staggers the gleam per
    /// weekday column so it travels along the window.
    var shimmers: Bool = false
    var shimmerDelay: Double = 0
    let action: () -> Void

    private let disc: CGFloat = 38   // wash disc; leaves a gap for the today ring
    private let tap: CGFloat = 44

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(fillColor)
                    .frame(width: disc, height: disc)

                if isPredicted {
                    Circle()
                        .strokeBorder(theme.color(.phaseMenstrual),
                                      style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                        .frame(width: disc, height: disc)
                }
                if isOvulation {
                    Circle()
                        .strokeBorder(theme.color(.phaseOvulation), lineWidth: 2)
                        .frame(width: disc, height: disc)
                    Image(systemName: "star.fill")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(theme.color(.phaseOvulation))
                        .offset(x: 13, y: -13)
                }

                if isFertile && !isOvulation {
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 6, weight: .bold))
                        .foregroundStyle(theme.color(.phaseFertile))
                        .offset(x: 13, y: -13)
                }

                if shimmers {
                    FertileGlimmer(delay: shimmerDelay,
                                   amber: theme.color(.phaseOvulation),
                                   highlight: theme.isDarkMode ? .white : theme.color(.phaseOvulation),
                                   size: disc)
                        .frame(width: disc, height: disc)
                        .allowsHitTesting(false)
                }

                Text("\(day)")
                    .font(ffBody(FFType.sm, weight: isToday ? .bold : .medium))
                    .foregroundStyle(numberColor)

                if let flow {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 7))
                        .foregroundStyle(dotColor(flow))
                        .offset(y: 12)
                }

                if stretchDone {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 7))
                        .foregroundStyle(theme.color(.phaseLuteal))
                        .offset(x: -13, y: -13)
                }

                if isToday {
                    Circle()
                        .strokeBorder(theme.color(.primaryStrong), lineWidth: 2)
                        .frame(width: tap, height: tap)
                }
            }
            .frame(width: tap, height: tap)
            .contentShape(Circle())
        }
        .buttonStyle(FFPressButtonStyle(scale: 0.9))
        .accessibilityLabel(a11yLabel)
    }

    private var fillColor: Color {
        if isPeriod { return theme.color(.phaseMenstrualSoft) }
        if isFertile || isOvulation { return theme.color(.phaseFertileSoft) }
        return .clear
    }

    private var numberColor: Color {
        // Always the dark ink — phaseMenstrual on the soft-rose period wash is only
        // ~3.1:1 (fails WCAG for a 13pt number). The soft fill + rings carry the state.
        theme.color(.text)
    }

    private func dotColor(_ flow: Flow) -> Color {
        switch flow {
        case .spotting:   theme.color(.flowSpotting)
        case .light:      theme.color(.flowLight)
        case .medium:     theme.color(.flowMedium)
        case .heavy:      theme.color(.flowHeavy)
        case .superHeavy: theme.color(.flowSuperHeavy)
        }
    }

    // e.g. "Day 14, period day, fertile, today"
    private var a11yLabel: String {
        var parts = ["Day \(day)"]
        if isPeriod    { parts.append("period day") }
        if isPredicted { parts.append("predicted period") }
        if isFertile   { parts.append("fertile") }
        if isOvulation { parts.append("ovulation") }
        if let flow    { parts.append("\(flow.label) flow") }
        if stretchDone { parts.append("stretch done") }
        if isToday     { parts.append("today") }
        return parts.joined(separator: ", ")
    }
}

// The fertile forecast's signature: a slow gold gleam that crosses the disc,
// staggered per weekday so it travels along the window like light moving on
// water. Built from the house shimmer recipe (SlideToLog's offset sweep +
// GlitterHint's staggered delay): one Core-Animation loop, no per-frame body
// work. The band spends most of each lap outside the clip, so it reads as a
// periodic glint rather than constant motion, and the off-screen snap-back
// between laps is invisible. Purely decorative (the fill, glyph, and label
// carry the state), so under Reduce Motion it simply doesn't render.
private struct FertileGlimmer: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let delay: Double
    let amber: Color
    let highlight: Color
    let size: CGFloat

    @State private var sweep = false

    var body: some View {
        if !reduceMotion {
            Color.clear
                .overlay(
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [.clear,
                                     amber.opacity(0.35),
                                     highlight.opacity(0.55),
                                     amber.opacity(0.35),
                                     .clear],
                            startPoint: .leading, endPoint: .trailing))
                        .frame(width: size * 0.85, height: size * 2)
                        .rotationEffect(.degrees(24))
                        .offset(x: (sweep ? 2.5 : -2.5) * size)
                )
                .clipShape(Circle())
                .onAppear {
                    withAnimation(.linear(duration: 4.6)
                        .repeatForever(autoreverses: false)
                        .delay(delay)) { sweep = true }
                }
        }
    }
}
