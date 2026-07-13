import SwiftUI

// DayCell — one day in the month calendar (DS tracking/DayCell). Layers a
// phase-soft wash, an optional dashed predicted ring, an amber ovulation ring,
// a today ring, and a logged-flow dot. 44pt tap target; the state is spelled
// out in the accessibility label so nothing is conveyed by color alone.
struct DayCell: View {
    @Environment(Theme.self) private var theme

    let day: Int
    let isToday: Bool
    let isPeriod: Bool
    let isPredicted: Bool
    let isFertile: Bool
    let isOvulation: Bool
    var flow: Flow? = nil
    let action: () -> Void

    private let disc: CGFloat = 38   // wash disc; leaves a gap for the today ring
    private let tap: CGFloat = 44

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(fillColor)
                    .frame(width: disc, height: disc)

                if isPredicted {
                    Circle()
                        .strokeBorder(theme.color(.phaseMenstrual),
                                      style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                        .frame(width: disc, height: disc)
                }
                if isOvulation {
                    Circle()
                        .strokeBorder(theme.color(.phaseOvulation), lineWidth: 2)
                        .frame(width: disc, height: disc)
                }

                Text("\(day)")
                    .font(ffBody(FFType.sm, weight: isToday ? .bold : .medium))
                    .foregroundStyle(numberColor)

                if let flow {
                    Circle()
                        .fill(dotColor(flow))
                        .frame(width: 5, height: 5)
                        .offset(y: 12)
                }

                if isToday {
                    Circle()
                        .strokeBorder(theme.color(.primaryStrong), lineWidth: 2)
                        .frame(width: tap, height: tap)
                }
            }
            .frame(width: tap, height: tap)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(a11yLabel)
    }

    private var fillColor: Color {
        if isPeriod { return theme.color(.phaseMenstrualSoft) }
        if isFertile || isOvulation { return theme.color(.phaseFertileSoft) }
        return .clear
    }

    private var numberColor: Color {
        // Always the dark ink — phaseMenstrual on the soft-rose period wash is only
        // ~3.1:1 (fails WCAG for a 13pt number). The soft fill + rings carry the state.
        theme.color(.text)
    }

    private func dotColor(_ flow: Flow) -> Color {
        switch flow {
        case .spotting: theme.color(.flowSpotting)
        case .light:    theme.color(.flowLight)
        case .medium:   theme.color(.flowMedium)
        case .heavy:    theme.color(.flowHeavy)
        }
    }

    // e.g. "Day 14, period day, fertile, today"
    private var a11yLabel: String {
        var parts = ["Day \(day)"]
        if isPeriod    { parts.append("period day") }
        if isPredicted { parts.append("predicted period") }
        if isFertile   { parts.append("fertile") }
        if isOvulation { parts.append("ovulation") }
        if let flow    { parts.append("\(flow.label) flow") }
        if isToday     { parts.append("today") }
        return parts.joined(separator: ", ")
    }
}
