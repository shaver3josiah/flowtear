import SwiftUI

// FFPickerSlider — a discrete DS slider for ordered pickers (flow intensity,
// discharge). Leftmost stop is "None" (nil); each step right selects the next
// option. Fully custom track so it feels friendly, not fussy:
//   • TAP anywhere and the knob jumps to the nearest stop — close counts.
//   • While she's touching, little tick marks fade in to show the zones,
//     lighting up as the knob passes them.
//   • A light haptic per step; the current pick reads out beside the title.
struct FFPickerSlider<Option: Hashable>: View {
    @Environment(Theme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let title: String
    let options: [Option]              // ordered, without the none stop
    let label: (Option) -> String
    @Binding var selection: Option?
    var tint: Tok = .primary
    var noneLabel: String = "None"

    @State private var touching = false
    @State private var dragIndex: Int? = nil   // live index while touching

    private var stops: Int { options.count + 1 }      // none + options
    private var selectedIndex: Int {
        guard let s = selection, let i = options.firstIndex(of: s) else { return 0 }
        return i + 1
    }
    private var liveIndex: Int { dragIndex ?? selectedIndex }

    private let trackHeight: CGFloat = 30
    private let knobSize: CGFloat = 26

    var body: some View {
        VStack(alignment: .leading, spacing: FFSpace.s2) {
            if !title.isEmpty {
                HStack {
                    Text(title)
                        .font(ffBody(FFType.md, weight: .semibold))
                        .foregroundStyle(theme.color(.deep))
                    Spacer()
                    valueReadout
                }
            }

            GeometryReader { geo in
                let usable = geo.size.width - knobSize
                let step = stops > 1 ? usable / CGFloat(stops - 1) : 0
                let knobX = CGFloat(liveIndex) * step

                ZStack(alignment: .leading) {
                    // Track with a warm fill up to the knob.
                    Capsule()
                        .fill(theme.color(.surfaceSoft))
                        .frame(height: 10)
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(theme.color(tint).opacity(0.45))
                                .frame(width: knobX + knobSize / 2, height: 10)
                        }
                        .overlay(Capsule().strokeBorder(theme.color(.line), lineWidth: 1))
                        .frame(maxHeight: .infinity, alignment: .center)

                    // Zone ticks — they appear while she's touching, and light
                    // up once the knob has passed them.
                    ForEach(0..<stops, id: \.self) { i in
                        Capsule()
                            .fill(theme.color(i <= liveIndex ? tint : .line))
                            .frame(width: 3, height: i == liveIndex ? 14 : 9)
                            .offset(x: knobSize / 2 + CGFloat(i) * step - 1.5)
                            .opacity(touching ? 1 : 0)
                            .animation(reduceMotion ? nil : FFMotion.fast, value: touching)
                            .animation(reduceMotion ? nil : FFMotion.fast, value: liveIndex)
                    }

                    // The knob.
                    Circle()
                        .fill(theme.color(.surface))
                        .overlay(Circle().strokeBorder(theme.color(tint), lineWidth: 3))
                        .overlay(
                            Circle().fill(theme.color(tint))
                                .frame(width: 8, height: 8)
                                .opacity(liveIndex == 0 ? 0.25 : 1)
                        )
                        .frame(width: knobSize, height: knobSize)
                        .shadow(color: theme.shadow, radius: touching ? 6 : 2, y: 1)
                        .scaleEffect(touching ? 1.15 : 1)
                        .offset(x: knobX)
                        .animation(reduceMotion ? nil : FFMotion.spring, value: touching)
                        .animation(reduceMotion ? nil : (touching ? FFMotion.fast : FFMotion.spring), value: liveIndex)
                }
                // One gesture covers both: a tap jumps straight to the nearest
                // stop, a drag scrubs through them.
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { v in
                            touching = true
                            dragIndex = nearestStop(x: v.location.x, step: step)
                        }
                        .onEnded { v in
                            let idx = nearestStop(x: v.location.x, step: step)
                            commit(idx)
                            touching = false
                            dragIndex = nil
                        }
                )
            }
            .frame(height: trackHeight + 8)

            HStack {
                Text(noneLabel)
                Spacer()
                if let last = options.last { Text(label(last)) }
            }
            .font(ffBody(FFType.xs2, weight: .medium))
            .foregroundStyle(theme.color(.muted))
        }
        .sensoryFeedback(.selection, trigger: liveIndex)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title.isEmpty ? "Picker" : title)
        .accessibilityValue(selection.map(label) ?? noneLabel)
        .accessibilityAdjustableAction { direction in
            let next = selectedIndex + (direction == .increment ? 1 : -1)
            commit(min(max(next, 0), stops - 1))
        }
    }

    private var valueReadout: some View {
        Text(selection.map(label) ?? noneLabel)
            .font(ffBody(FFType.sm, weight: .bold))
            .foregroundStyle(selection == nil ? theme.color(.muted) : theme.color(tint))
            .contentTransition(.opacity)
    }

    private func nearestStop(x: CGFloat, step: CGFloat) -> Int {
        guard step > 0 else { return 0 }
        let raw = Int(((x - knobSize / 2) / step).rounded())
        return min(max(raw, 0), stops - 1)
    }

    private func commit(_ index: Int) {
        selection = index <= 0 ? nil : options[min(index - 1, options.count - 1)]
    }
}
