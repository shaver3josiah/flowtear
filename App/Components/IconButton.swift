import SwiftUI

// FFIconButton — round, icon-only tap target (DS core/IconButton). 44pt minimum,
// surfaceSoft circle, primaryStrong glyph, press scale .92. Give it an
// `.accessibilityLabel(...)` at the call site so VoiceOver names the action.
struct FFIconButton: View {
    @Environment(Theme.self) private var theme
    private let systemName: String
    private let action: () -> Void

    init(_ systemName: String, action: @escaping () -> Void) {
        self.systemName = systemName
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.color(.primaryStrong))
                .frame(width: FFSpace.tapMin, height: FFSpace.tapMin)
                .background(theme.color(.surfaceSoft), in: Circle())
        }
        .buttonStyle(FFPressButtonStyle(scale: 0.92))
    }
}
