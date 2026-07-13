import SwiftUI

// FlowerMark — the Flowtear bloom, the brand's signature motif. A procedural
// rose (NOT an SF Symbol): three concentric elliptical-petal rings in the theme
// pinks around a gold center, recreated faithfully from the DS FlowerMark.jsx
// geometry (100×100 design space). Colored entirely from theme tokens so it
// re-tints with the active preset.
struct FlowerMark: View {
    @Environment(Theme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var size: CGFloat
    /// Slow decorative rotation (ambient). Gated on reduce-motion.
    var spin: Bool
    /// Gentle scale "breathing" loop — loading / ambient. Gated on reduce-motion.
    var breathe: Bool
    var title: String

    init(size: CGFloat, spin: Bool = false, breathe: Bool = false, title: String = "Flowtear") {
        self.size = size
        self.spin = spin
        self.breathe = breathe
        self.title = title
    }

    @State private var spinAngle: Double = 0
    @State private var breatheScale: CGFloat = 1

    // Three petal rings + center, verbatim from FlowerMark.jsx RINGS.
    private struct Ring {
        let count: Int
        let lengthScale, widthScale, offsetFraction: CGFloat
        let color: Tok
        let opacity: Double
        let rot: Double
    }
    private static let rings: [Ring] = [
        .init(count: 8, lengthScale: 0.44, widthScale: 0.30, offsetFraction: 0.52, color: .primary,       opacity: 0.55, rot:  6),
        .init(count: 7, lengthScale: 0.34, widthScale: 0.24, offsetFraction: 0.50, color: .primary,       opacity: 1.00, rot: -9),
        .init(count: 6, lengthScale: 0.24, widthScale: 0.18, offsetFraction: 0.46, color: .primaryStrong, opacity: 1.00, rot: 15),
    ]

    /// Each petal = an ellipse pushed out along (angle − 90°) and rotated by angle.
    private static func petals(for r: Ring) -> [Path] {
        let c: CGFloat = 50
        let petalLength = 100 * r.lengthScale
        let petalWidth  = 100 * r.widthScale
        return (0..<r.count).map { i in
            let angleDeg = Double(i) * (360.0 / Double(r.count))
            let a = (angleDeg - 90) * .pi / 180
            let cx = c + petalLength * r.offsetFraction * CGFloat(cos(a))
            let cy = c + petalLength * r.offsetFraction * CGFloat(sin(a))
            let ellipse = Path(ellipseIn: CGRect(x: -petalWidth / 2, y: -petalLength / 2,
                                                 width: petalWidth, height: petalLength))
            return ellipse
                .applying(CGAffineTransform(rotationAngle: angleDeg * .pi / 180))
                .applying(CGAffineTransform(translationX: cx, y: cy))
        }
    }

    var body: some View {
        Canvas { context, sz in
            let scale = min(sz.width, sz.height) / 100
            context.scaleBy(x: scale, y: scale)
            for ring in Self.rings {
                var rctx = context                 // save/restore via value copy
                rctx.translateBy(x: 50, y: 50)
                rctx.rotate(by: .degrees(ring.rot))
                rctx.translateBy(x: -50, y: -50)
                let shading = GraphicsContext.Shading.color(theme.color(ring.color).opacity(ring.opacity))
                for petal in Self.petals(for: ring) {
                    rctx.fill(petal, with: shading)
                }
            }
            let center = Path(ellipseIn: CGRect(x: 39, y: 39, width: 22, height: 22)) // r=11 at (50,50)
            context.fill(center, with: .color(theme.color(.flowerCenter)))
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(spinAngle))
        .scaleEffect(breatheScale)
        .accessibilityLabel(title)
        .onAppear(perform: startLoops)
    }

    private func startLoops() {
        guard !reduceMotion else { return }
        if spin {
            withAnimation(.linear(duration: 14).repeatForever(autoreverses: false)) { spinAngle = 360 }
        }
        if breathe {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) { breatheScale = 1.06 }
        }
    }
}
