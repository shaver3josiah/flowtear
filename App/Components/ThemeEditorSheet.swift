import SwiftUI

// The pencil settings — Bloom-calculator-style theming. Pick one of the full
// palette presets (Cherry, Pink, Rose, Peony, Soft, Light, Dark) or lay a custom
// accent color over any of them; the whole app recolors live through the token
// seam. Cycle-phase and flow colors stay fixed — they carry meaning.
struct ThemeEditorSheet: View {
    @Environment(Theme.self) private var theme
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: FFSpace.s3)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FFSpace.section) {
                header
                presetSection
                accentSection
                Text("Period, fertile and phase colors never change — they mean something.")
                    .font(ffBody(FFType.xs))
                    .foregroundStyle(theme.color(.muted))
            }
            .padding(FFSpace.s5)
        }
        .background(theme.color(.bg))
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Make it yours")
                    .font(ffDisplay(FFType.xl, weight: .bold))
                    .foregroundStyle(theme.color(.deep))
                Text("Pick a palette, then tint it any color you like.")
                    .font(ffBody(FFType.sm))
                    .foregroundStyle(theme.color(.muted))
            }
            Spacer()
            FFIconButton("xmark") { dismiss() }
        }
    }

    // MARK: presets

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: FFSpace.s3) {
            sectionTitle("Palette")
            LazyVGrid(columns: columns, spacing: FFSpace.s3) {
                ForEach(Theme.presetNames, id: \.self) { name in
                    presetChip(name)
                }
            }
        }
    }

    private func presetChip(_ name: String) -> some View {
        let selected = theme.presetName == name
        return Button {
            withAnimation(FFMotion.fast) { theme.setPreset(name) }
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(Theme.swatch(for: name))
                    .frame(width: 18, height: 18)
                    .overlay(Circle().strokeBorder(theme.color(.line), lineWidth: 1))
                Text(Theme.label(for: name))
                    .font(ffBody(FFType.sm, weight: .semibold))
                    .foregroundStyle(theme.color(selected ? .deep : .text))
                Spacer(minLength: 0)
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(theme.color(.primaryStrong))
                }
            }
            .padding(.horizontal, 12)
            .frame(height: FFSpace.tapMin)
            .background(theme.color(selected ? .surfaceSoft : .surface),
                        in: RoundedRectangle(cornerRadius: FFRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: FFRadius.md, style: .continuous)
                    .strokeBorder(selected ? theme.color(.primaryStrong) : theme.color(.line),
                                  lineWidth: selected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(Theme.label(for: name)) palette")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: custom accent

    private var accentSection: some View {
        VStack(alignment: .leading, spacing: FFSpace.s3) {
            sectionTitle("Your color")
            FFCard {
                VStack(alignment: .leading, spacing: FFSpace.s3) {
                    ColorPicker(selection: accentBinding, supportsOpacity: false) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Accent")
                                .font(ffBody(FFType.md, weight: .semibold))
                                .foregroundStyle(theme.color(.text))
                            Text("Recolors buttons, highlights and the bloom")
                                .font(ffBody(FFType.xs))
                                .foregroundStyle(theme.color(.muted))
                        }
                    }
                    if theme.customAccentHex != nil {
                        FFButton("Back to the palette's own color", style: .ghost, size: .sm,
                                 icon: "arrow.uturn.backward") {
                            withAnimation(FFMotion.fast) { theme.resetCustomAccent() }
                        }
                    }
                }
            }
        }
    }

    private var accentBinding: Binding<Color> {
        Binding(
            get: { theme.customAccent ?? theme.color(.primary) },
            set: { theme.setCustomAccent($0) }
        )
    }

    private func sectionTitle(_ t: String) -> some View {
        Text(t)
            .font(ffBody(FFType.md, weight: .semibold))
            .foregroundStyle(theme.color(.deep))
    }
}
