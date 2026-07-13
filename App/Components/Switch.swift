import SwiftUI

// FFSwitch — the settings / reminder toggle (commonly the trailing control in an
// FFListRow). Soft track fills strong-pink when on; the white knob springs across.
// Controlled via `isOn`.
//
// DS ref: components/core/Switch.jsx
//   track 52x30, radius pill, surfaceSoft -> primaryStrong when on
//   knob 24x24 white, inset 3, deep drop shadow, translateX 22 on
// Hit target padded to 44pt tall for accessibility (visual track stays 30).
struct FFSwitch: View {
    @Environment(Theme.self) private var theme
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(FFMotion.spring) { isOn.toggle() }
        } label: {
            Capsule(style: .continuous)
                .fill(isOn ? theme.color(.primaryStrong) : theme.color(.surfaceSoft))
                .frame(width: 52, height: 30)
                .overlay(alignment: .leading) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                        .shadow(color: Color(.sRGB, red: 66/255, green: 21/255, blue: 39/255, opacity: 0.28),
                                radius: 3, x: 0, y: 2)
                        .padding(.leading, 3)
                        .offset(x: isOn ? 22 : 0)
                }
                .frame(width: 52, height: FFSpace.tapMin)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isToggle)
    }
}
