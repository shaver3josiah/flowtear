import SwiftUI

// PetalRain — the signature "magical" layer: soft rose petals drifting down.
// Fills its parent, ignores hit-testing, and renders NOTHING under reduce-motion
// (the DS `prefers-reduced-motion` gate). Petals are tinted from --primary /
// --primary-strong / --deep so they follow the theme. Keep counts modest (12–18).
struct PetalRain: View {
    @Environment(Theme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var count: Int

    init(count: Int = 14) {
        self.count = count
        _petals = State(initialValue: (0..<max(0, count)).map { _ in Petal() })
    }

    @State private var petals: [Petal]
    @State private var fall = false

    private struct Petal: Identifiable {
        let id = UUID()
        let left  = CGFloat.random(in: 0...1)      // fraction of width
        let size  = CGFloat.random(in: 8...17)
        let delay = Double.random(in: 0...14)      // stagger (DS uses negative for mid-air start)
        let dur   = Double.random(in: 7...15)
        let drift = CGFloat.random(in: -45...45)
        let spin  = Double.random(in: 160...520)
        let op    = Double.random(in: 0.45...0.9)
        let strong = Bool.random()
    }

    var body: some View {
        GeometryReader { geo in
            if !reduceMotion {
                ZStack {
                    ForEach(petals) { petal(for: $0, in: geo.size) }
                }
                .onAppear { fall = true }
            }
        }
        .clipped()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func petal(for p: Petal, in size: CGSize) -> some View {
        // petal teardrop: border-radius 100% 0 100% 0 (top-leading + bottom-trailing rounded)
        UnevenRoundedRectangle(topLeadingRadius: p.size,
                               bottomLeadingRadius: 0,
                               bottomTrailingRadius: p.size,
                               topTrailingRadius: 0,
                               style: .continuous)
            .fill(LinearGradient(
                colors: [theme.color(p.strong ? .primary : .primaryStrong), theme.color(.deep)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: p.size, height: p.size * 1.15)
            .opacity(p.op)
            .rotationEffect(.degrees(fall ? p.spin : 0))
            .position(x: p.left * size.width + (fall ? p.drift : 0),
                      y: fall ? size.height * 1.1 : -size.height * 0.1)   // off-screen both ends → clipped
            .animation(.linear(duration: p.dur).repeatForever(autoreverses: false).delay(p.delay),
                       value: fall)
    }
}
