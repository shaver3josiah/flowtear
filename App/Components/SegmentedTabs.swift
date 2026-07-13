import SwiftUI

// FFSegmentedTabs — the capsule tab switcher from the Bloom KTabBar. A soft
// track (surfaceSoft) with a strong-pink pill sliding under the active label.
// Full-width, equal-width segments. Controlled via `selection`.
//
// DS ref: components/core/SegmentedTabs.jsx
//   track: gap 4, padding 4, surfaceSoft, radius pill
//   seg:   height 36, padding 0/18, body semibold text-sm, muted
//   active: primaryStrong fill, white, soft colored shadow (0 4px 12px -6px)
struct FFSegmentedTabs: View {
    @Environment(Theme.self) private var theme
    let items: [String]
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 4) {
            ForEach(items, id: \.self) { item in
                let active = item == selection
                Button {
                    withAnimation(FFMotion.signature) { selection = item }
                } label: {
                    Text(item)
                        .font(ffBody(FFType.sm, weight: .semibold))
                        .foregroundStyle(active ? Color.white : theme.color(.muted))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(
                            Capsule(style: .continuous)
                                .fill(active ? theme.color(.primaryStrong) : .clear)
                                .shadow(color: active ? theme.shadow : .clear,
                                        radius: 6, x: 0, y: 4)
                        )
                        .contentShape(Capsule(style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(active ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(4)
        .background(theme.color(.surfaceSoft), in: Capsule(style: .continuous))
    }
}
