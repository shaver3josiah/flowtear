import SwiftUI

// PhaseBadge — the prominent current-phase indicator (DS tracking/PhaseBadge):
// a phase-tinted soft pill with a color dot and the phase name. Renders nothing
// when the phase is unknown (no history yet). The dot + label carry the phase
// name in text, so meaning never rides on color alone.
struct PhaseBadge: View {
    @Environment(Theme.self) private var theme
    let phase: CyclePhase?

    var body: some View {
        if let phase {
            HStack(spacing: 8) {
                Circle()
                    .fill(theme.color(CycleRing.tint(phase)))
                    .frame(width: 8, height: 8)
                Text(phase.label)
                    .font(ffBody(FFType.sm, weight: .semibold))
                    .foregroundStyle(theme.color(.deep))
            }
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(theme.color(CycleRing.softTint(phase)), in: Capsule())
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(phase.label) phase")
        }
    }
}
