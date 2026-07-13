import SwiftUI

// FlowScale — the period flow selector (DS tracking/FlowScale): four droplets
// that deepen and grow from spotting to heavy, colors from the flow ramp.
// Single-select, tap-to-toggle (tap the selected one again to clear). The
// centerpiece of the daily log sheet. >=44pt targets; the label under each
// droplet carries the level so it never rides on color alone.
struct FlowScale: View {
    @Environment(Theme.self) private var theme
    @Binding var selection: Flow?

    // spotting → heavy: deepening ramp tint + growing droplet.
    private let levels: [(flow: Flow, tint: Tok, drop: CGFloat)] = [
        (.spotting, .flowSpotting, 20),
        (.light,    .flowLight,    24),
        (.medium,   .flowMedium,   28),
        (.heavy,    .flowHeavy,    32),
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(levels, id: \.flow) { level in
                let isOn = selection == level.flow
                Button {
                    selection = isOn ? nil : level.flow
                } label: {
                    VStack(spacing: 6) {
                        Droplet()
                            .fill(theme.color(level.tint))
                            .frame(width: level.drop * 0.72, height: level.drop)
                            .frame(height: 32, alignment: .bottom)   // baseline-align the growing drops
                            .opacity(isOn ? 1 : 0.45)
                        Text(level.flow.label)
                            .font(ffBody(FFType.xs, weight: .semibold))
                            .foregroundStyle(isOn ? theme.color(.deep) : theme.color(.muted))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 6)
                    .background(
                        RoundedRectangle(cornerRadius: FFRadius.md)
                            .fill(isOn ? theme.color(.surfaceSoft) : .clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: FFRadius.md)
                                    .strokeBorder(isOn ? theme.color(.line) : .clear, lineWidth: 1.5)
                            )
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(FFPressButtonStyle(scale: 0.95))
                .accessibilityLabel("\(level.flow.label) flow")
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Flow intensity")
    }
}

// Teardrop: pointed tip at top, round bulb at bottom. Mirrors the DS droplet SVG.
private struct Droplet: Shape {
    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let r = rect.width * 0.5
        let cy = rect.maxY - r                 // bulb center
        let tip = CGPoint(x: cx, y: rect.minY)
        let bottom = CGPoint(x: cx, y: rect.maxY)
        var p = Path()
        p.move(to: tip)
        p.addCurve(to: bottom,
                   control1: CGPoint(x: cx - r * 0.2, y: cy - r * 0.9),
                   control2: CGPoint(x: cx - r * 1.3, y: cy + r * 0.6))
        p.addCurve(to: tip,
                   control1: CGPoint(x: cx + r * 1.3, y: cy + r * 0.6),
                   control2: CGPoint(x: cx + r * 0.2, y: cy - r * 0.9))
        p.closeSubpath()
        return p
    }
}
