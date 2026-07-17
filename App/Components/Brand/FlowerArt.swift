import SwiftUI

// FlowerArt — the shop's ten blooms, drawn by hand the same way FlowerMark is:
// flat Canvas fills in a 100×100 design space, cute and cartoonish, never
// photoreal. Every bloom is seen from directly above (plan view), so the
// shelf reads as one garden. Each flower has its own geometry and palette, and the shelf reads
// as a crescendo: rarer blooms are visibly lusher AND render a touch larger
// (see `FlowerItem.artScale`). Rare/Precious blooms carry little gold sparkles.
//
// Colors here are literal on purpose — like the cycle-phase ramp, a sunflower's
// gold and a rose's red carry meaning and never re-tint with the theme.
struct FlowerArt: View {
    let id: String
    var size: CGFloat = 24

    var body: some View {
        Canvas { ctx, sz in
            let s = min(sz.width, sz.height) / 100
            ctx.scaleBy(x: s, y: s)
            FlowerArt.draw(id, in: &ctx)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    // MARK: - dispatch

    static func draw(_ id: String, in ctx: inout GraphicsContext) {
        switch id {
        case "daisy":     daisy(&ctx)
        case "tulip":     tulip(&ctx)
        case "blossom":   blossom(&ctx)
        case "camellia":  camellia(&ctx)
        case "rosette":   rosette(&ctx)
        case "rose":      rose(&ctx)
        case "hibiscus":  hibiscus(&ctx)
        case "sunflower": sunflower(&ctx)
        case "lotus":     lotus(&ctx)
        case "bouquet":   bouquet(&ctx)
        default:          daisy(&ctx)
        }
    }

    // MARK: - shared geometry

    private enum PetalStyle { case round, pointed, notched }

    /// A petal in local space: width `w`, length `l`, tip pointing up (−y).
    private static func petalPath(_ style: PetalStyle, l: CGFloat, w: CGFloat) -> Path {
        switch style {
        case .round:
            return Path(ellipseIn: CGRect(x: -w / 2, y: -l / 2, width: w, height: l))
        case .pointed:
            var p = Path()
            p.move(to: CGPoint(x: 0, y: -l / 2))
            p.addQuadCurve(to: CGPoint(x: w / 2, y: l * 0.05), control: CGPoint(x: w * 0.46, y: -l * 0.32))
            p.addQuadCurve(to: CGPoint(x: 0, y: l / 2), control: CGPoint(x: w * 0.48, y: l * 0.42))
            p.addQuadCurve(to: CGPoint(x: -w / 2, y: l * 0.05), control: CGPoint(x: -w * 0.48, y: l * 0.42))
            p.addQuadCurve(to: CGPoint(x: 0, y: -l / 2), control: CGPoint(x: -w * 0.46, y: -l * 0.32))
            p.closeSubpath()
            return p
        case .notched:   // cherry-blossom petal: rounded, with a dip at the tip
            var p = Path()
            p.move(to: CGPoint(x: 0, y: l / 2))
            p.addQuadCurve(to: CGPoint(x: -w / 2, y: -l * 0.1), control: CGPoint(x: -w * 0.58, y: l * 0.28))
            p.addQuadCurve(to: CGPoint(x: -w * 0.17, y: -l / 2), control: CGPoint(x: -w * 0.46, y: -l * 0.44))
            p.addQuadCurve(to: CGPoint(x: 0, y: -l * 0.32), control: CGPoint(x: -w * 0.02, y: -l * 0.46))
            p.addQuadCurve(to: CGPoint(x: w * 0.17, y: -l / 2), control: CGPoint(x: w * 0.02, y: -l * 0.46))
            p.addQuadCurve(to: CGPoint(x: w / 2, y: -l * 0.1), control: CGPoint(x: w * 0.46, y: -l * 0.44))
            p.addQuadCurve(to: CGPoint(x: 0, y: l / 2), control: CGPoint(x: w * 0.58, y: l * 0.28))
            p.closeSubpath()
            return p
        }
    }

    private static func place(_ p: Path, rot: Double, x: CGFloat, y: CGFloat) -> Path {
        p.applying(CGAffineTransform(rotationAngle: rot * .pi / 180))
            .applying(CGAffineTransform(translationX: x, y: y))
    }

    /// A radial ring of petals (FlowerMark convention: angle 0 at 12 o'clock).
    private static func petalRing(_ ctx: inout GraphicsContext, count: Int, offset: CGFloat,
                                  l: CGFloat, w: CGFloat, color: Color,
                                  style: PetalStyle = .round, startAngle: Double = 0,
                                  center: CGPoint = CGPoint(x: 50, y: 50)) {
        let petal = petalPath(style, l: l, w: w)
        for i in 0..<count {
            let deg = startAngle + Double(i) * 360 / Double(count)
            let a = (deg - 90) * .pi / 180
            let x = center.x + offset * CGFloat(cos(a))
            let y = center.y + offset * CGFloat(sin(a))
            ctx.fill(place(petal, rot: deg, x: x, y: y), with: .color(color))
        }
    }

    private static func dot(_ ctx: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat,
                            _ r: CGFloat, _ color: Color) {
        ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                 with: .color(color))
    }

    private static func arc(_ ctx: inout GraphicsContext, r: CGFloat, from: Double, to: Double,
                            color: Color, width: CGFloat, center: CGPoint = CGPoint(x: 50, y: 50)) {
        var p = Path()
        p.addArc(center: center, radius: r,
                 startAngle: .degrees(from), endAngle: .degrees(to), clockwise: false)
        ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    /// A little four-point gold sparkle — the rarity garnish.
    private static func sparkle(_ ctx: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat,
                                _ s: CGFloat, opacity: Double = 1) {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: -s))
        p.addQuadCurve(to: CGPoint(x: s, y: 0), control: CGPoint(x: s * 0.18, y: -s * 0.18))
        p.addQuadCurve(to: CGPoint(x: 0, y: s), control: CGPoint(x: s * 0.18, y: s * 0.18))
        p.addQuadCurve(to: CGPoint(x: -s, y: 0), control: CGPoint(x: -s * 0.18, y: s * 0.18))
        p.addQuadCurve(to: CGPoint(x: 0, y: -s), control: CGPoint(x: -s * 0.18, y: -s * 0.18))
        p.closeSubpath()
        ctx.fill(p.applying(CGAffineTransform(translationX: x, y: y)),
                 with: .color(c("#FFD76A").opacity(opacity)))
    }

    private static func c(_ hex: String) -> Color { Color(hex: hex) ?? .pink }

    // MARK: - the ten blooms

    // Daisy — the first friend: white petals rimmed in cream so they read on
    // white cards, sunny gold heart.
    private static func daisy(_ ctx: inout GraphicsContext) {
        petalRing(&ctx, count: 9, offset: 30, l: 40, w: 20, color: c("#F3DFA8"), startAngle: 20)
        petalRing(&ctx, count: 9, offset: 29, l: 36, w: 16, color: .white, startAngle: 20)
        dot(&ctx, 50, 50, 12.5, c("#FFC24E"))
        for i in 0..<6 {
            let a = Double(i) * 60 * .pi / 180
            dot(&ctx, 50 + 6.5 * CGFloat(cos(a)), 50 + 6.5 * CGFloat(sin(a)), 1.6, c("#E8992B"))
        }
        dot(&ctx, 50, 50, 2, c("#E8992B"))
    }

    // Tulip — seen from above like the rest of the garden: three rosy outer
    // petals, three lighter inner ones, leaf tips peeking between.
    private static func tulip(_ ctx: inout GraphicsContext) {
        petalRing(&ctx, count: 3, offset: 33, l: 26, w: 13, color: c("#4E9B5C"),
                  style: .pointed, startAngle: 60)
        petalRing(&ctx, count: 3, offset: 25, l: 44, w: 32, color: c("#F25D8E"), style: .pointed)
        petalRing(&ctx, count: 3, offset: 15, l: 32, w: 24, color: c("#FF8FB3"),
                  style: .pointed, startAngle: 60)
        dot(&ctx, 50, 50, 6.5, c("#FFC9DA"))
        for i in 0..<6 {
            let a = Double(i) * 60 * .pi / 180
            dot(&ctx, 50 + 3.6 * CGFloat(cos(a)), 50 + 3.6 * CGFloat(sin(a)), 1.4, c("#FFCB5C"))
        }
    }

    // Cherry blossom — five notched pink petals, gold stamens.
    private static func blossom(_ ctx: inout GraphicsContext) {
        petalRing(&ctx, count: 5, offset: 26, l: 37, w: 27, color: c("#FFB3CF"), style: .notched)
        dot(&ctx, 50, 50, 10, c("#F585B0"))
        for i in 0..<5 {
            let a = (Double(i) * 72 + 36 - 90) * .pi / 180
            dot(&ctx, 50 + 8.5 * CGFloat(cos(a)), 50 + 8.5 * CGFloat(sin(a)), 1.7, c("#FFCB5C"))
        }
        dot(&ctx, 50, 50, 3.8, c("#FFCB5C"))
    }

    // Camellia — three lush layers of rounded petals, blush into cream.
    private static func camellia(_ ctx: inout GraphicsContext) {
        petalRing(&ctx, count: 8, offset: 30, l: 34, w: 24, color: c("#EE6E9F"))
        petalRing(&ctx, count: 6, offset: 20, l: 26, w: 20, color: c("#FF97BC"), startAngle: 22)
        petalRing(&ctx, count: 5, offset: 11, l: 17, w: 14, color: c("#FFC3D8"), startAngle: 45)
        dot(&ctx, 50, 50, 5.5, c("#FFCB5C"))
    }

    // Rosette — a little prize ribbon: scalloped disc, gold button, two tails.
    private static func rosette(_ ctx: inout GraphicsContext) {
        let tail = Path(roundedRect: CGRect(x: -5, y: -13, width: 10, height: 26), cornerRadius: 3)
        ctx.fill(place(tail, rot: -14, x: 44, y: 68), with: .color(c("#C93A6E")))
        ctx.fill(place(tail, rot: 14, x: 56, y: 68), with: .color(c("#C93A6E")))
        petalRing(&ctx, count: 12, offset: 30, l: 20, w: 15, color: c("#E2417F"))
        dot(&ctx, 50, 50, 29, c("#F587B2"))
        petalRing(&ctx, count: 8, offset: 14, l: 12, w: 10, color: c("#E2417F"), startAngle: 15)
        dot(&ctx, 50, 50, 12, c("#FBD3E5"))
        dot(&ctx, 50, 50, 6.5, c("#FFC24E"))
    }

    // Rose — two rings of red petals around a swirled heart.
    private static func rose(_ ctx: inout GraphicsContext) {
        petalRing(&ctx, count: 6, offset: 29, l: 33, w: 26, color: c("#D92D55"))
        petalRing(&ctx, count: 6, offset: 26, l: 30, w: 24, color: c("#E8496F"), startAngle: 30)
        dot(&ctx, 50, 50, 19, c("#C21E45"))
        arc(&ctx, r: 14, from: -60, to: 190, color: c("#921231"), width: 3.2)
        arc(&ctx, r: 9, from: 80, to: 330, color: c("#921231"), width: 3.2)
        arc(&ctx, r: 4.5, from: 210, to: 460, color: c("#921231"), width: 3.2)
        dot(&ctx, 50, 50, 1.8, c("#921231"))
    }

    // Hibiscus — big coral petals, an orange throat, the signature stamen.
    private static func hibiscus(_ ctx: inout GraphicsContext) {
        petalRing(&ctx, count: 5, offset: 25, l: 40, w: 34, color: c("#FF6E63"))
        petalRing(&ctx, count: 5, offset: 12, l: 20, w: 16, color: c("#FF9A55"))
        dot(&ctx, 50, 50, 8, c("#D64545"))
        var stamen = Path()
        stamen.move(to: CGPoint(x: 50, y: 48))
        stamen.addLine(to: CGPoint(x: 70, y: 26))
        ctx.stroke(stamen, with: .color(c("#FFCB5C")), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        for (x, y) in [(70.0, 24.0), (74.5, 22.5), (72.5, 28.0), (77.0, 27.0), (68.0, 20.0)] {
            dot(&ctx, CGFloat(x), CGFloat(y), 2.2, c("#FFCB5C"))
        }
        sparkle(&ctx, 20, 30, 5)
        sparkle(&ctx, 82, 62, 4, opacity: 0.85)
    }

    // Sunflower — a double crown of gold around a seeded brown heart.
    private static func sunflower(_ ctx: inout GraphicsContext) {
        petalRing(&ctx, count: 13, offset: 31, l: 26, w: 11, color: c("#E09000"),
                  startAngle: 180 / 13)
        petalRing(&ctx, count: 13, offset: 30, l: 25, w: 10, color: c("#FFC42E"))
        dot(&ctx, 50, 50, 16.5, c("#7A4E2B"))
        dot(&ctx, 50, 50, 13, c("#5F3B1F"))
        for i in 0..<8 {
            let a = Double(i) * 45 * .pi / 180
            dot(&ctx, 50 + 9 * CGFloat(cos(a)), 50 + 9 * CGFloat(sin(a)), 1.7, c("#A8794C"))
        }
        for i in 0..<5 {
            let a = (Double(i) * 72 + 36) * .pi / 180
            dot(&ctx, 50 + 4.5 * CGFloat(cos(a)), 50 + 4.5 * CGFloat(sin(a)), 1.5, c("#A8794C"))
        }
        sparkle(&ctx, 18, 22, 5)
        sparkle(&ctx, 84, 32, 4, opacity: 0.85)
    }

    // Lotus — serene pointed petals opening light from the center.
    private static func lotus(_ ctx: inout GraphicsContext) {
        petalRing(&ctx, count: 8, offset: 30, l: 34, w: 19, color: c("#F784AC"), style: .pointed)
        petalRing(&ctx, count: 6, offset: 19, l: 27, w: 16, color: c("#FFB1CB"), style: .pointed, startAngle: 30)
        petalRing(&ctx, count: 4, offset: 10, l: 19, w: 13, color: c("#FFDCE8"), style: .pointed, startAngle: 45)
        dot(&ctx, 50, 50, 5, c("#FFCB5C"))
        sparkle(&ctx, 16, 30, 5)
        sparkle(&ctx, 84, 24, 6, opacity: 0.9)
        sparkle(&ctx, 78, 78, 4, opacity: 0.75)
    }

    // Bouquet — from above now: greenery radiating past a scalloped paper
    // wrap, three little roses clustered on top.
    private static func bouquet(_ ctx: inout GraphicsContext) {
        petalRing(&ctx, count: 3, offset: 36, l: 26, w: 13, color: c("#4E9B5C"), style: .pointed)
        petalRing(&ctx, count: 3, offset: 36, l: 26, w: 13, color: c("#5FA968"),
                  style: .pointed, startAngle: 60)
        petalRing(&ctx, count: 9, offset: 30, l: 16, w: 14, color: c("#F4C9DE"))
        dot(&ctx, 50, 50, 31, c("#F4C9DE"))
        miniRose(&ctx, x: 50, y: 39, r: 9)
        miniRose(&ctx, x: 40, y: 57, r: 9)
        miniRose(&ctx, x: 60, y: 57, r: 9)
        sparkle(&ctx, 16, 24, 6)
        sparkle(&ctx, 86, 36, 5, opacity: 0.9)
        sparkle(&ctx, 22, 76, 4, opacity: 0.75)
    }

    private static func miniRose(_ ctx: inout GraphicsContext, x: CGFloat, y: CGFloat, r: CGFloat) {
        petalRing(&ctx, count: 6, offset: r * 1.05, l: r * 1.5, w: r * 1.2,
                  color: c("#D92D55"), center: CGPoint(x: x, y: y))
        dot(&ctx, x, y, r, c("#C21E45"))
        arc(&ctx, r: r * 0.6, from: -40, to: 200, color: c("#921231"), width: 2,
            center: CGPoint(x: x, y: y))
        dot(&ctx, x, y, r * 0.16, c("#921231"))
    }
}

extension FlowerItem {
    /// Rarer blooms render a touch larger — the shelf reads as a crescendo.
    /// The whole ladder starts above 1 so even the Daisy feels substantial.
    var artScale: CGFloat {
        switch rarity {
        case "Sweet":    1.18
        case "Lovely":   1.26
        case "Rare":     1.34
        case "Precious": 1.44
        default:         1.12
        }
    }
}
