import SwiftUI

// FFCard — the fundamental surface primitive (DS core/Card). White with a soft
// rose drop shadow and the canonical 22px corner; soft/accent/outline variants
// for quieter panels. `interactive` lifts the card (float shadow) to read as
// tappable — the consumer attaches its own tap gesture / Button.
enum FFCardVariant { case plain, soft, accent, outline }

struct FFCard<Content: View>: View {
    @Environment(Theme.self) private var theme
    var variant: FFCardVariant = .plain
    var interactive: Bool = false
    @ViewBuilder var content: () -> Content

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: FFRadius.card, style: .continuous)
    }

    private var bg: Color {
        switch variant {
        case .plain, .outline: theme.color(.surface)
        case .soft:            theme.color(.surfaceSoft)
        case .accent:          theme.color(.surface2)
        }
    }

    var body: some View {
        shadowed(
            content()
                .padding(FFSpace.card)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(bg)
                .clipShape(shape)
                .overlay {
                    if variant == .outline {
                        shape.strokeBorder(theme.color(.line), lineWidth: 1)
                    }
                }
        )
    }

    // plain gets the resting card shadow; interactive lifts to the float shadow;
    // soft/accent/outline stay flat.
    // ponytail: interactive = elevated look only (no press-scale) — the card has
    // no action of its own, so tracking press here would swallow the consumer's tap.
    @ViewBuilder private func shadowed(_ v: some View) -> some View {
        if interactive { v.ffFloatShadow(theme) }
        else if variant == .plain { v.ffCardShadow(theme) }
        else { v }
    }
}
