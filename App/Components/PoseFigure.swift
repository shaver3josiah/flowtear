import SwiftUI

// PoseFigure — little stick-figure silhouettes that actually match each stretch,
// drawn procedurally (head + spine + limbs) so they follow the theme color and
// scale crisply. Mapped from the move's name; anything unmapped falls back to
// the move's SF Symbol.

enum PoseKind {
    case allFours      // Cat-Cow: hands & knees, spine arched
    case cobra         // lying prone, chest lifted on arms
    case childsPose    // kneeling fold, arms long
    case kneesToChest  // on the back, knees hugged in
    case fish          // on the back, chest arched over support
    case pelvicTilt    // on the back, knees bent, feet down
    case butterfly     // seated, soles together, knees wide
    case sideStretch   // standing, one arm overhead, leaning
    case twist         // on the back, knees dropped to one side
    case hamstring     // on the back, one leg raised straight

    /// Best-effort mapping from a move's display name.
    static func from(name: String) -> PoseKind? {
        let n = name.lowercased()
        if n.contains("cat") { return .allFours }
        if n.contains("cobra") { return .cobra }
        if n.contains("child") { return .childsPose }
        if n.contains("knees-to-chest") || n.contains("knees to chest") { return .kneesToChest }
        if n.contains("fish") { return .fish }
        if n.contains("pelvic") { return .pelvicTilt }
        if n.contains("butterfly") || n.contains("adductor") { return .butterfly }
        if n.contains("side stretch") { return .sideStretch }
        if n.contains("twist") { return .twist }
        if n.contains("hamstring") || n.contains("figure-4") { return .hamstring }
        return nil
    }
}

/// Draws the pose, or the fallback SF Symbol when a move has no figure.
struct PoseFigure: View {
    let move: StretchMove
    var size: CGFloat = 22
    var color: Color

    var body: some View {
        if let kind = PoseKind.from(name: move.name) {
            PoseShape(kind: kind)
                .stroke(color, style: StrokeStyle(lineWidth: size * 0.09,
                                                  lineCap: .round, lineJoin: .round))
                .frame(width: size, height: size)
        } else {
            Image(systemName: move.icon)
                .font(.system(size: size * 0.75, weight: .medium))
                .foregroundStyle(color)
                .frame(width: size, height: size)
        }
    }
}

// All poses drawn in a 0…1 unit space, ground along y≈0.9. The head is a small
// circle; the body is open strokes. Proportions favor readability over anatomy.
struct PoseShape: Shape {
    let kind: PoseKind

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * w, y: rect.minY + y * h) }
        func head(_ x: CGFloat, _ y: CGFloat, r: CGFloat = 0.09) {
            p.addEllipse(in: CGRect(x: rect.minX + (x - r) * w, y: rect.minY + (y - r) * h,
                                    width: 2 * r * w, height: 2 * r * h))
        }
        func line(_ a: CGPoint, _ b: CGPoint) { p.move(to: a); p.addLine(to: b) }
        func curve(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) { p.move(to: a); p.addQuadCurve(to: b, control: c) }

        switch kind {
        case .allFours:
            // Hands & knees; back arched up (the "cat").
            head(0.16, 0.44)
            curve(pt(0.24, 0.48), pt(0.78, 0.52), pt(0.5, 0.22))   // arched spine
            line(pt(0.26, 0.5), pt(0.26, 0.88))                    // arm down
            line(pt(0.74, 0.54), pt(0.74, 0.88))                   // thigh down
            line(pt(0.74, 0.88), pt(0.92, 0.88))                   // shin back
        case .cobra:
            // Prone, chest lifted, legs long behind.
            head(0.2, 0.3)
            curve(pt(0.26, 0.38), pt(0.62, 0.82), pt(0.34, 0.62))  // lifted torso
            line(pt(0.62, 0.82), pt(0.95, 0.86))                   // legs
            line(pt(0.3, 0.44), pt(0.3, 0.84))                     // supporting arm
        case .childsPose:
            // Kneeling, folded forward, arms reaching.
            head(0.24, 0.62)
            curve(pt(0.3, 0.66), pt(0.72, 0.62), pt(0.52, 0.36))   // rounded back
            line(pt(0.72, 0.62), pt(0.72, 0.88))                   // shin under
            line(pt(0.72, 0.88), pt(0.52, 0.88))
            line(pt(0.22, 0.7), pt(0.05, 0.82))                    // arm long
        case .kneesToChest:
            // On the back, knees hugged to the chest.
            head(0.14, 0.66)
            line(pt(0.2, 0.72), pt(0.55, 0.78))                    // back on floor
            curve(pt(0.55, 0.78), pt(0.5, 0.42), pt(0.72, 0.55))   // thighs in
            curve(pt(0.5, 0.42), pt(0.34, 0.52), pt(0.38, 0.38))   // shins tucked
            line(pt(0.9, 0.86), pt(0.06, 0.86))                    // ground line
        case .fish:
            // On the back, chest arched, crown toward the floor.
            head(0.2, 0.62)
            curve(pt(0.26, 0.6), pt(0.6, 0.74), pt(0.4, 0.36))     // arched chest
            line(pt(0.6, 0.74), pt(0.92, 0.78))                    // legs long
            line(pt(0.9, 0.88), pt(0.06, 0.88))                    // ground
        case .pelvicTilt:
            // On the back, knees bent, feet planted.
            head(0.12, 0.72)
            line(pt(0.18, 0.76), pt(0.6, 0.8))                     // back down
            line(pt(0.6, 0.8), pt(0.74, 0.5))                      // thigh up
            line(pt(0.74, 0.5), pt(0.82, 0.86))                    // shin down
            line(pt(0.92, 0.88), pt(0.05, 0.88))                   // ground
        case .butterfly:
            // Seated tall, knees wide, soles together.
            head(0.5, 0.2)
            line(pt(0.5, 0.28), pt(0.5, 0.62))                     // upright spine
            curve(pt(0.5, 0.62), pt(0.24, 0.86), pt(0.2, 0.6))     // left leg wing
            curve(pt(0.5, 0.62), pt(0.76, 0.86), pt(0.8, 0.6))     // right leg wing
            line(pt(0.24, 0.86), pt(0.76, 0.86))                   // soles meet
        case .sideStretch:
            // Standing, one arm overhead, leaning away.
            head(0.55, 0.16)
            curve(pt(0.55, 0.24), pt(0.48, 0.62), pt(0.6, 0.44))   // leaning trunk
            line(pt(0.48, 0.62), pt(0.42, 0.9))                    // leg
            line(pt(0.56, 0.62), pt(0.62, 0.9))                    // leg
            curve(pt(0.55, 0.26), pt(0.28, 0.1), pt(0.4, 0.08))    // arm overhead
        case .twist:
            // On the back, shoulders flat, knees dropped to one side.
            head(0.14, 0.6)
            line(pt(0.2, 0.66), pt(0.56, 0.7))                     // torso down
            line(pt(0.56, 0.7), pt(0.78, 0.52))                    // thighs to the side
            line(pt(0.78, 0.52), pt(0.7, 0.34))                    // shins folded
            line(pt(0.9, 0.86), pt(0.06, 0.86))                    // ground
        case .hamstring:
            // On the back, one leg raised straight up.
            head(0.14, 0.72)
            line(pt(0.2, 0.76), pt(0.62, 0.8))                     // back down
            line(pt(0.62, 0.8), pt(0.66, 0.28))                    // leg to the sky
            line(pt(0.62, 0.8), pt(0.9, 0.84))                     // other leg long
            line(pt(0.94, 0.88), pt(0.06, 0.88))                   // ground
        }
        return p
    }
}
