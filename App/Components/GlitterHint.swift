import SwiftUI

// GlitterHint — a tiny twinkle of gold over a control she hasn't tried yet
// (the theme pencil, the shop bag…). The first tap retires the hint for good,
// per key. Reduce Motion shows one still sparkle instead of the twinkling.
struct GlitterHint: ViewModifier {
    @Environment(Theme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let key: String
    @State private var pressed: Bool

    init(key: String) {
        self.key = key
        _pressed = State(initialValue: UserDefaults.standard.bool(forKey: "flowtear.glitter." + key))
    }

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                if !pressed { sparkles }
            }
            .simultaneousGesture(TapGesture().onEnded {
                guard !pressed else { return }
                UserDefaults.standard.set(true, forKey: "flowtear.glitter." + key)
                withAnimation(FFMotion.fast) { pressed = true }
            })
    }

    private var sparkles: some View {
        ZStack {
            TwinkleSparkle(size: 9, delay: 0, color: theme.color(.flowerCenter))
                .offset(x: 5, y: -5)
            if !reduceMotion {
                TwinkleSparkle(size: 6, delay: 0.35, color: theme.color(.primary))
                    .offset(x: -7, y: -9)
                TwinkleSparkle(size: 7, delay: 0.7, color: theme.color(.flowerCenter))
                    .offset(x: 9, y: 7)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct TwinkleSparkle: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let size: CGFloat
    let delay: Double
    let color: Color
    @State private var lit = false

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(color)
            .opacity(lit ? 1 : 0.15)
            .scaleEffect(lit ? 1 : 0.6)
            .onAppear {
                if reduceMotion { lit = true } else {
                    withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)
                        .delay(delay)) { lit = true }
                }
            }
    }
}

extension View {
    /// Twinkling gold over a not-yet-pressed control; the first tap retires it.
    func glitterHint(_ key: String) -> some View { modifier(GlitterHint(key: key)) }
}
