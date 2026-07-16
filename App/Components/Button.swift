import SwiftUI

// Shared press-scale for all FF tap targets (DS `:active{transform:scale()}`).
// Lives here; reused by FFIconButton and FFChip in this module.
struct FFPressButtonStyle: ButtonStyle {
    var scale: CGFloat = FFMotion.pressScale
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(FFMotion.spring, value: configuration.isPressed)
    }
}

// FFButton — the primary action pill (DS core/Button). Full-capsule, springy
// press (.96), soft themed shadow on the filled variants. `icon` is an SF Symbol
// name rendered before the label.
enum FFButtonStyle { case primary, deep, soft, ghost }

enum FFButtonSize {
    case sm, md, lg
    var height: CGFloat { switch self { case .sm: 38; case .md: 46; case .lg: 54 } }
    var hPad: CGFloat   { switch self { case .sm: 16; case .md: 22; case .lg: 30 } }
    var font: CGFloat   { switch self { case .sm: FFType.sm; case .md: FFType.base; case .lg: FFType.md } }
}

struct FFButton: View {
    @Environment(Theme.self) private var theme
    private let title: String
    private let style: FFButtonStyle
    private let size: FFButtonSize
    private let icon: String?
    private let action: () -> Void

    init(_ title: String, style: FFButtonStyle = .primary, size: FFButtonSize = .md,
         icon: String? = nil, action: @escaping () -> Void) {
        self.title = title; self.style = style; self.size = size; self.icon = icon; self.action = action
    }

    private var fg: Color {
        switch style {
        // onPrimary, not literal white: the dark palettes brighten these fills
        // to light pinks, where white text would wash out (~2.8:1).
        case .primary, .deep: theme.color(.onPrimary)
        case .soft:           theme.color(.deep)
        case .ghost:          theme.color(.primaryStrong)
        }
    }

    private var bg: Color {
        switch style {
        case .primary: theme.color(.primaryStrong)
        case .deep:    theme.color(.deep)
        case .soft:    theme.color(.surfaceSoft)
        case .ghost:   .clear
        }
    }

    private var hasShadow: Bool { style == .primary || style == .deep }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                if let icon { Image(systemName: icon) }
                Text(title)
            }
            .font(ffBody(size.font, weight: .semibold))
            .foregroundStyle(fg)
            .frame(height: size.height)
            .padding(.horizontal, size.hPad)
            .background(bg, in: Capsule())
            // DS --shadow: 0 8px 20px -10px var(--shadow) — warm rose, filled only.
            .shadow(color: hasShadow ? theme.shadow : .clear, radius: 10, x: 0, y: 8)
        }
        .buttonStyle(FFPressButtonStyle())
    }
}
