import SwiftUI

// FFBadge — small soft-tinted status label with an optional leading dot
// (DS core/Badge). Background is the tint at low opacity, text/dot in the full
// tint (mirrors the DS "good" tone formula, generalized to any token).
struct FFBadge: View {
    @Environment(Theme.self) private var theme
    private let text: String
    private let tint: Tok
    private let dot: Bool

    init(_ text: String, tint: Tok = .primary, dot: Bool = false) {
        self.text = text; self.tint = tint; self.dot = dot
    }

    var body: some View {
        HStack(spacing: 5) {
            if dot {
                Circle().fill(theme.color(tint)).frame(width: 7, height: 7)
            }
            Text(text)
        }
        .font(ffBody(FFType.xs, weight: .semibold))
        .tracking(0.3)
        // Text in deep plum for contrast (light tints like fertile-gold fail WCAG
        // as text); the dot + wash carry the color identity.
        .foregroundStyle(theme.color(.deep))
        .frame(height: 24)
        .padding(.horizontal, 10)
        .background(theme.color(tint).opacity(0.15), in: Capsule())
    }
}
