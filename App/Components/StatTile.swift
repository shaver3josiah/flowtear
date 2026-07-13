import SwiftUI

// StatTile — a compact stat panel (DS tracking/StatTile). Big Playfair value
// (tinted) over a muted micro-label, on a soft tinted panel. Grid these for the
// Insights summary: average cycle, average period, cycles tracked, streak.
struct StatTile: View {
    @Environment(Theme.self) private var theme

    let title: String
    let value: String
    var unit: String? = nil
    var tint: Tok = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(ffNumber(FFType.xl2))
                    // Deep plum numerals — the tint on surfaceSoft fails WCAG (~2.2:1).
                    // Color identity stays on the ring/badge; the stat reads as brand plum.
                    .foregroundStyle(theme.color(.deep))
                if let unit {
                    Text(unit)
                        .font(ffBody(FFType.sm, weight: .medium))
                        .foregroundStyle(theme.color(.muted))
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            Text(title)
                .font(ffBody(FFType.xs, weight: .medium))
                .foregroundStyle(theme.color(.muted))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(FFSpace.s4)
        .background(theme.color(.surfaceSoft),
                    in: RoundedRectangle(cornerRadius: FFRadius.md, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
