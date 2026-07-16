import SwiftUI

// TipsSheet — "the hidden magic." The app's most delightful interactions are
// gestures with no visible affordance; this little guide hands her all of them.
// Opened from the lightbulb on Today (which twinkles until first pressed).
struct TipsSheet: View {
    @Environment(Theme.self) private var theme
    @Environment(\.dismiss) private var dismiss

    private struct Tip: Identifiable {
        let icon: String
        let title: String
        let text: String
        var id: String { title }
    }

    private let tips: [Tip] = [
        Tip(icon: "hand.draw",
            title: "Scrub the ring",
            text: "Drag anywhere on the cycle ring to travel day by day — tap it to read the story of that phase."),
        Tip(icon: "arrow.triangle.2.circlepath",
            title: "Spin, fling & pluck your flower",
            text: "Your flower sticker rides the ring like a bead. Fling it and it spins like a fidget; pull it clearly off and rest it anywhere — inside the ring or beside it. Carry it back and it beads on again."),
        Tip(icon: "sparkle",
            title: "The period-arc bonus",
            text: "Land your flower on the colored period arc and a few bonus petals fall out — once a day, for luck."),
        Tip(icon: "hand.tap",
            title: "Tap-to-jump sliders",
            text: "The flow and log sliders jump straight to wherever you tap — no dragging required."),
        Tip(icon: "checkmark.circle",
            title: "The whole plan is tappable",
            text: "In Stretch, open any day of your plan to see its moves, check them off, or run that day's guided session on the spot — even off-schedule."),
        Tip(icon: "pause.circle",
            title: "Pause your plan",
            text: "Inside the plan picker there's a pause switch — missed days cost nothing while life happens."),
        Tip(icon: "bag",
            title: "Petals buy the pretty things",
            text: "Every stretch earns petal points; the garden shop turns them into flowers, palettes, sounds — even Posey. The book icon has the full rules."),
        Tip(icon: "wand.and.stars",
            title: "Double-tap the bloom",
            text: "The flower in Today's corner opens a little about page with honest answers about predictions and privacy."),
        Tip(icon: "square.and.arrow.up",
            title: "Your data is yours",
            text: "Everything lives on this phone only. Export it all as a spreadsheet from Insights whenever you like."),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FFSpace.section) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("The hidden magic")
                            .font(ffDisplay(FFType.xl, weight: .bold))
                            .foregroundStyle(theme.color(.deep))
                        Text("Everything this garden can do — including the parts that don't announce themselves.")
                            .font(ffBody(FFType.sm))
                            .foregroundStyle(theme.color(.muted))
                    }
                    Spacer()
                    FFIconButton("xmark") { dismiss() }
                }

                VStack(spacing: FFSpace.s2) {
                    ForEach(tips) { tip in
                        tipRow(tip)
                    }
                }
            }
            .padding(FFSpace.s5)
        }
        .background(theme.color(.bg))
    }

    private func tipRow(_ tip: Tip) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: tip.icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(theme.color(.primaryStrong))
                .frame(width: 26)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 3) {
                Text(tip.title)
                    .font(ffBody(FFType.sm, weight: .bold))
                    .foregroundStyle(theme.color(.deep))
                Text(tip.text)
                    .font(ffBody(FFType.sm))
                    .foregroundStyle(theme.color(.text))
                    .lineSpacing(3)
            }
            Spacer(minLength: 0)
        }
        .padding(FFSpace.s4)
        .background(theme.color(.surface), in: RoundedRectangle(cornerRadius: FFRadius.md, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: FFRadius.md, style: .continuous)
            .strokeBorder(theme.color(.line), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}
