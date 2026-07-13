import SwiftUI

// FFToast — the flower-headed notice from the Bloom family: white surface, the
// bloom mark, a deep title and a muted message that truncates. For saves,
// reminders and gentle confirmations. No timer — mount/unmount it yourself in a
// fixed top slot. Mirrors Toast.jsx layout.
struct FFToast: View {
    @Environment(Theme.self) private var theme

    var message: String
    /// Bold deep-colored headline (optional).
    var title: String?
    /// SF Symbol name to replace the leading FlowerMark (optional).
    var icon: String?

    init(message: String, title: String? = nil, icon: String? = nil) {
        self.message = message
        self.title = title
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(theme.color(.primaryStrong))
                } else {
                    FlowerMark(size: 34)
                        .accessibilityHidden(true)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                if let title {
                    Text(title)
                        .font(ffBody(FFType.base, weight: .semibold))
                        .foregroundStyle(theme.color(.deep))
                }
                Text(message)
                    .font(ffBody(FFType.sm))
                    .foregroundStyle(theme.color(.muted))
                    .lineLimit(2)
                    .truncationMode(.tail)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .frame(maxWidth: 380, alignment: .leading)
        .background(theme.color(.surface),
                    in: RoundedRectangle(cornerRadius: FFRadius.card, style: .continuous))
        .shadow(color: theme.shadow, radius: 12, x: 0, y: 10)   // --shadow-float-ish: 0 10px 24px -8px
        .accessibilityElement(children: .combine)
    }
}
