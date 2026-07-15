import SwiftUI

// SparkleBurst — a one-shot glimmering celebration: rose petals and gold
// sparkles burst outward, twirl, and fade. Fire it by bumping `trigger`.
// Purely decorative: hit-testing off, VoiceOver hidden, respects Reduce Motion
// (renders nothing). Deterministic per-particle paths — no randomness APIs.
struct SparkleBurst: View {
    @Environment(Theme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let trigger: Int
    var count: Int = 16

    var body: some View {
        ZStack {
            if !reduceMotion && trigger > 0 {
                ForEach(0..<count, id: \.self) { i in
                    BurstParticle(index: i, token: trigger,
                                  color: color(i), isSparkle: i % 3 == 0)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .id(trigger)   // fresh particle set (and fresh animations) per burst
    }

    private func color(_ i: Int) -> Color {
        switch i % 4 {
        case 0:  theme.color(.flowerCenter)     // gold glimmer
        case 1:  theme.color(.primary)
        case 2:  theme.color(.phaseFollicular)
        default: theme.color(.phaseLuteal)
        }
    }
}

private struct BurstParticle: View {
    let index: Int
    let token: Int
    let color: Color
    let isSparkle: Bool

    @State private var flown = false

    // Deterministic scatter: angle from index, distance/spin jittered by a hash.
    private var jitter: Double { Double(abs(((index + token) &* 2654435761) % 100)) / 100 }
    private var angle: Double { (Double(index) / 16.0) * 2 * .pi + jitter * 0.6 }
    private var distance: Double { 55 + jitter * 65 }

    var body: some View {
        Group {
            if isSparkle {
                Image(systemName: "sparkle")
                    .font(.system(size: 9 + jitter * 6, weight: .bold))
                    .foregroundStyle(color)
            } else {
                // A petal: soft ellipse, slightly elongated.
                Ellipse()
                    .fill(color)
                    .frame(width: 7 + jitter * 4, height: 11 + jitter * 6)
            }
        }
        .rotationEffect(.degrees(flown ? jitter * 540 - 270 : 0))
        .offset(x: flown ? cos(angle) * distance : 0,
                y: flown ? sin(angle) * distance - 14 : 0)   // a little lift
        .scaleEffect(flown ? 0.55 : 1)
        .opacity(flown ? 0 : 1)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8 + jitter * 0.4)) { flown = true }
        }
    }
}
