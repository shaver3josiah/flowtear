import SwiftUI

// Posey — the stretch coach. A storybook flower with a face: blinking eyes,
// rosy cheeks, a little smile, leaf arms — one of which waves hello. She sways
// on her stem and speaks in a named bubble. Classy company, never clippy.
// Reduce Motion: she stands still (no sway, wave, or blink), everything else intact.
struct CoachFlower: View {
    @Environment(Theme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let message: String
    static let name = "Posey"

    @State private var sway = false
    @State private var wave = false
    @State private var blink = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            posey
                .frame(width: 68, height: 100)
                .rotationEffect(.degrees(sway ? 2.5 : -2.5), anchor: .bottom)
                .task {
                    guard !reduceMotion else { return }
                    withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { sway = true }
                    // A friendly wave on arrival…
                    withAnimation(.easeInOut(duration: 0.35).repeatCount(5, autoreverses: true)) { wave = true }
                    // …and the occasional blink, forever after.
                    while !Task.isCancelled {
                        try? await Task.sleep(for: .seconds(3.2))
                        withAnimation(.easeInOut(duration: 0.09)) { blink = true }
                        try? await Task.sleep(for: .seconds(0.12))
                        withAnimation(.easeInOut(duration: 0.09)) { blink = false }
                    }
                }
                .accessibilityHidden(true)

            // Her speech bubble, with a nameplate.
            VStack(alignment: .leading, spacing: 4) {
                Text(Self.name.uppercased())
                    .font(ffBody(FFType.xs2, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(theme.color(.primaryStrong))
                Text(message)
                    .font(ffBody(FFType.sm, weight: .medium))
                    .foregroundStyle(theme.color(.text))
                    .lineSpacing(3)
            }
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
            .accessibilityLabel("\(Self.name) says: \(message)")
        }
    }

    // MARK: Posey herself — bloom, face, stem, one waving arm

    private var posey: some View {
        ZStack(alignment: .top) {
            StemShape()
                .stroke(theme.color(.good), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                .padding(.top, 36)

            // Left arm rests; right arm waves hello.
            leaf.rotationEffect(.degrees(-52), anchor: .bottomTrailing)
                .offset(x: -18, y: 58)
            leaf.scaleEffect(x: -1)
                .rotationEffect(.degrees(wave ? 76 : 44), anchor: .bottomLeading)
                .offset(x: 18, y: 58)

            FlowerMark(size: 46)
            face.offset(y: 15)   // sits on the bloom's golden center
        }
    }

    private var face: some View {
        VStack(spacing: 2) {
            HStack(spacing: 5) {
                eye
                eye
            }
            // A small, contented smile.
            SmileShape()
                .stroke(theme.color(.deep), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
                .frame(width: 9, height: 4)
        }
        .overlay(alignment: .leading) { cheek.offset(x: -7, y: 1) }
        .overlay(alignment: .trailing) { cheek.offset(x: 7, y: 1) }
    }

    private var eye: some View {
        Capsule()
            .fill(theme.color(.deep))
            .frame(width: 2.6, height: 4.6)
            .scaleEffect(y: blink ? 0.15 : 1, anchor: .center)
    }

    private var cheek: some View {
        Circle()
            .fill(theme.color(.primary).opacity(0.45))
            .frame(width: 3.6, height: 3.6)
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

private struct SmileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY),
                       control: CGPoint(x: rect.midX, y: rect.maxY + rect.height))
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
