import SwiftUI

// CoachFlower — the friendly stretch coach: the bloom on a curved stem with two
// leaf arms raised in a cheer, plus a speech bubble of encouragement. She sways
// gently (Reduce Motion: stands still). Classy, not clippy.
struct CoachFlower: View {
    @Environment(Theme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let message: String
    @State private var sway = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            flower
                .frame(width: 64, height: 96)
                .rotationEffect(.degrees(sway ? 2.5 : -2.5), anchor: .bottom)
                .onAppear {
                    guard !reduceMotion else { return }
                    withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                        sway = true
                    }
                }
                .accessibilityHidden(true)

            // Speech bubble with a soft tail toward the coach.
            Text(message)
                .font(ffBody(FFType.sm, weight: .medium))
                .foregroundStyle(theme.color(.text))
                .lineSpacing(3)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(theme.color(.surface),
                            in: RoundedRectangle(cornerRadius: FFRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: FFRadius.md, style: .continuous)
                        .strokeBorder(theme.color(.line), lineWidth: 1)
                )
                .overlay(alignment: .bottomLeading) {
                    BubbleTail()
                        .fill(theme.color(.surface))
                        .overlay(BubbleTail().stroke(theme.color(.line), lineWidth: 1))
                        .frame(width: 12, height: 10)
                        .offset(x: -8, y: -14)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel("Your coach says: \(message)")
        }
    }

    // Bloom head + curved stem + two leaf arms lifted like a little cheer.
    private var flower: some View {
        ZStack(alignment: .top) {
            // Stem — a gentle S-curve down from under the bloom.
            StemShape()
                .stroke(theme.color(.good), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                .padding(.top, 34)

            // Leaf arms — angled up and outward.
            leaf.rotationEffect(.degrees(-52), anchor: .bottomTrailing)
                .offset(x: -17, y: 56)
            leaf.scaleEffect(x: -1)
                .rotationEffect(.degrees(52), anchor: .bottomLeading)
                .offset(x: 17, y: 56)

            FlowerMark(size: 44)
        }
    }

    private var leaf: some View {
        Ellipse()
            .fill(theme.color(.good).opacity(0.85))
            .frame(width: 22, height: 10)
    }
}

private struct StemShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let x = rect.midX
        p.move(to: CGPoint(x: x, y: rect.minY))
        p.addCurve(to: CGPoint(x: x, y: rect.maxY),
                   control1: CGPoint(x: x - 9, y: rect.minY + rect.height * 0.35),
                   control2: CGPoint(x: x + 9, y: rect.minY + rect.height * 0.7))
        return p
    }
}

private struct BubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
