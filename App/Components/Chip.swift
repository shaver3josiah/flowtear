import SwiftUI

// FFChip — a selectable pill for multi-select vocabularies (DS core/Chip).
// Resting: surfaceSoft fill, muted text. Selected: strong-pink fill, white text,
// plus the `.isSelected` trait so selection isn't conveyed by color alone.
struct FFChip: View {
    @Environment(Theme.self) private var theme
    private let title: String
    private let selected: Bool
    private let icon: String?
    private let action: () -> Void

    init(_ title: String, selected: Bool, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title; self.selected = selected; self.icon = icon; self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon { Image(systemName: icon) }
                Text(title)
            }
            .font(ffBody(FFType.sm, weight: .semibold))
            .foregroundStyle(selected ? .white : theme.color(.muted))
            .frame(height: 40)
            .padding(.horizontal, 16)
            .background(selected ? theme.color(.primaryStrong) : theme.color(.surfaceSoft), in: Capsule())
        }
        .buttonStyle(FFPressButtonStyle(scale: 0.95))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
