import SwiftUI

/// Something she tapped but can't afford yet.
struct PetalGap: Identifiable {
    let name: String
    let price: Int
    var id: String { name }
}

// NeedMorePetalsView — the gentle "not yet" splash. Instead of a locked tap
// silently doing nothing, this names the exact gap, shows how far she's come,
// and walks her straight to the stretching side to earn the rest.
struct NeedMorePetalsView: View {
    @Environment(Theme.self) private var theme
    @Environment(RewardsStore.self) private var rewards
    @Environment(\.dismiss) private var dismiss

    let gap: PetalGap
    /// Jump to the Stretch tab (the caller closes its own sheets first).
    var onGoStretch: (() -> Void)? = nil

    private var needed: Int { max(gap.price - rewards.balance, 0) }
    private var progress: Double { min(Double(rewards.balance) / Double(max(gap.price, 1)), 1) }

    var body: some View {
        ZStack {
            theme.color(.bg).ignoresSafeArea()
            PetalRain(count: 8)
            VStack(spacing: FFSpace.s4) {
                Spacer(minLength: 0)
                FlowerMark(size: 56, breathe: true)
                Text("Almost there, petal!")
                    .font(ffDisplay(FFType.xl, weight: .bold))
                    .foregroundStyle(theme.color(.deep))
                VStack(spacing: 4) {
                    Text("\(needed)")
                        .font(ffNumber(56, weight: .semibold))
                        .foregroundStyle(theme.color(.primaryStrong))
                    Text("MORE PETAL POINTS")
                        .font(ffBody(FFType.xs, weight: .bold)).tracking(1.2)
                        .foregroundStyle(theme.color(.muted))
                    Text("to bring home \(gap.name)")
                        .font(ffBody(FFType.sm, weight: .medium))
                        .foregroundStyle(theme.color(.text))
                }
                VStack(spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(theme.color(.surfaceSoft))
                            Capsule().fill(theme.color(.primaryStrong))
                                .frame(width: max(geo.size.width * progress, 10))
                        }
                    }
                    .frame(height: 10)
                    Text("\(rewards.balance) of \(gap.price) saved")
                        .font(ffBody(FFType.xs))
                        .foregroundStyle(theme.color(.muted))
                }
                .padding(.horizontal, FFSpace.s5)
                FFButton("Earn petals stretching", style: .primary, icon: "figure.cooldown") {
                    dismiss()
                    onGoStretch?()
                }
                FFButton("Keep browsing", style: .ghost, size: .sm) { dismiss() }
                Spacer(minLength: 0)
            }
            .padding(FFSpace.s5)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("You need \(needed) more petal points for \(gap.name). You have \(rewards.balance) of \(gap.price).")
    }
}
