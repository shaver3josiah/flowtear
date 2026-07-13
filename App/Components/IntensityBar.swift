import SwiftUI

// IntensityBar — a labeled horizontal bar for breakdown charts (DS
// tracking/IntensityBar): flow-by-day, pain, symptom frequency. Fraction =
// value/max; the fill animates in on mount with the signature easing (skipped
// under Reduce Motion). Stack several in a Card to make an insights chart.
struct IntensityBar: View {
    @Environment(Theme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let label: String
    let value: Double
    let max: Double
    var tint: Tok

    @State private var appeared = false

    private var fraction: Double {
        guard max > 0 else { return 0 }
        return Swift.min(1, Swift.max(0, value / max))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(ffBody(FFType.sm, weight: .semibold))
                .foregroundStyle(theme.color(.text))

            ZStack(alignment: .leading) {
                Capsule().fill(theme.color(.surfaceSoft))
                GeometryReader { geo in
                    Capsule()
                        .fill(theme.color(tint))
                        .frame(width: geo.size.width * (appeared ? fraction : 0))
                }
            }
            .frame(height: 9)
        }
        .onAppear {
            if reduceMotion { appeared = true }
            else { withAnimation(FFMotion.slow) { appeared = true } }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue("\(Int((fraction * 100).rounded())) percent")
    }
}
