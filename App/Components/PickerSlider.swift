import SwiftUI

// FFPickerSlider — a discrete DS-styled slider for ordered pickers (flow
// intensity, discharge). Leftmost stop is always "None" (nil); each step right
// selects the next option. The current pick reads out beside the title, with a
// light haptic per step.
struct FFPickerSlider<Option: Hashable>: View {
    @Environment(Theme.self) private var theme

    let title: String
    let options: [Option]              // ordered, without the none stop
    let label: (Option) -> String
    @Binding var selection: Option?
    var tint: Tok = .primary
    var noneLabel: String = "None"

    private var sliderValue: Binding<Double> {
        Binding(
            get: {
                guard let s = selection, let i = options.firstIndex(of: s) else { return 0 }
                return Double(i + 1)
            },
            set: { raw in
                let i = Int(raw.rounded())
                selection = i <= 0 ? nil : options[min(i - 1, options.count - 1)]
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FFSpace.s2) {
            HStack {
                Text(title)
                    .font(ffBody(FFType.md, weight: .semibold))
                    .foregroundStyle(theme.color(.deep))
                Spacer()
                Text(selection.map(label) ?? noneLabel)
                    .font(ffBody(FFType.sm, weight: .bold))
                    .foregroundStyle(selection == nil ? theme.color(.muted) : theme.color(tint))
                    .contentTransition(.opacity)
            }
            Slider(value: sliderValue, in: 0...Double(options.count), step: 1)
                .tint(theme.color(tint))
            HStack {
                Text(noneLabel)
                Spacer()
                if let last = options.last { Text(label(last)) }
            }
            .font(ffBody(FFType.xs2, weight: .medium))
            .foregroundStyle(theme.color(.muted))
        }
        .sensoryFeedback(.selection, trigger: selection)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(selection.map(label) ?? noneLabel)
    }
}
