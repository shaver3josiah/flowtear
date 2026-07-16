import SwiftUI

// FFChip — a selectable pill for multi-select vocabularies (DS core/Chip).
// Resting: surfaceSoft fill, muted text. Selected: strong-pink fill, white text,
// plus the `.isSelected` trait so selection isn't conveyed by color alone.
struct FFChip: View {
    @Environment(Theme.self) private var theme
    private let title: String
    private let selected: Bool
    private let icon: String?
    private let emoji: String?
    private let tint: Tok
    private let action: () -> Void

    init(_ title: String, selected: Bool, icon: String? = nil, emoji: String? = nil,
         tint: Tok = .primaryStrong, action: @escaping () -> Void) {
        self.title = title; self.selected = selected; self.icon = icon
        self.emoji = emoji; self.tint = tint; self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let emoji {
                    // A small, quiet face — a picking aid, not a decoration parade.
                    Text(emoji)
                        .font(.system(size: 14))
                        .accessibilityHidden(true)
                } else if let icon {
                    Image(systemName: icon)
                        .symbolEffect(.bounce, value: selected)
                }
                Text(title)
            }
            .font(ffBody(FFType.sm, weight: .semibold))
            // onPrimary is calibrated for the brand ramp only; other tint fills
            // (e.g. the lavender mood chips) stay fixed mid-tones in every
            // preset, so they take the fixed dark bloom ink instead.
            .foregroundStyle(selected ? theme.color(tint == .primaryStrong ? .onPrimary : .bloomInk)
                                      : theme.color(.muted))
            .frame(height: 40)
            .padding(.horizontal, 16)
            .background(selected ? theme.color(tint) : theme.color(.surfaceSoft), in: Capsule())
            .overlay(
                Capsule().strokeBorder(
                    selected ? .clear : theme.color(.line), lineWidth: 1)
            )
            .scaleEffect(selected ? 1.0 : 0.98)
            .animation(FFMotion.spring, value: selected)
        }
        .buttonStyle(FFPressButtonStyle(scale: 0.93))
        .sensoryFeedback(.selection, trigger: selected)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
