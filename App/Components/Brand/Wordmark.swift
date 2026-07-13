import SwiftUI

// Wordmark — the Flowtear name in brand type with the bloom mark. This lockup IS
// the logo (no image asset). `display` (Playfair 600) is the everyday lockup;
// `script` (Great Vibes) is reserved for splash & affectionate moments. Color
// comes from --deep. Mirrors Wordmark.jsx sizing (mark scales with the text).
struct Wordmark: View {
    @Environment(Theme.self) private var theme

    var script: Bool
    var size: CGFloat
    var showMark: Bool
    var text: String

    init(script: Bool = false, size: CGFloat = 28, showMark: Bool = true, text: String = "Flowtear") {
        self.script = script
        self.size = size
        self.showMark = showMark
        self.text = text
    }

    var body: some View {
        HStack(spacing: script ? size * 0.40 : size * 0.55) {
            if showMark {
                FlowerMark(size: script ? size * 1.15 : size)
                    .accessibilityHidden(true)
            }
            Text(text)
                .font(script ? ffScript(size) : ffDisplay(size, weight: .semibold))
                .tracking(script ? size * 0.01 : size * -0.01)   // --tracking-tight = -0.01em
                .foregroundStyle(theme.color(.deep))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }
}
