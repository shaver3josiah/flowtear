import SwiftUI

// FFListRow — a settings / reminders row: soft rounded leading icon, title +
// optional subtitle, and a trailing slot (FFSwitch, chevron, value text). Stack
// several inside an FFCard for a settings group.
//
// DS ref: components/core/ListRow.jsx
//   gap 14; lead 40x40 radius-sm surfaceSoft, primaryStrong glyph
//   title text-base semibold text; sub text-xs muted; trail text-sm medium muted
struct FFListRow<Trailing: View>: View {
    @Environment(Theme.self) private var theme
    let icon: String
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var trailing: () -> Trailing

    init(icon: String,
         title: String,
         subtitle: String? = nil,
         @ViewBuilder trailing: @escaping () -> Trailing) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.color(.primaryStrong))
                .frame(width: 40, height: 40)
                .background(theme.color(.surfaceSoft),
                            in: RoundedRectangle(cornerRadius: FFRadius.sm, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(ffBody(FFType.base, weight: .semibold))
                    .foregroundStyle(theme.color(.text))
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(ffBody(FFType.xs))
                        .foregroundStyle(theme.color(.muted))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            trailing()
                .font(ffBody(FFType.sm, weight: .medium))
                .foregroundStyle(theme.color(.muted))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
    }
}
