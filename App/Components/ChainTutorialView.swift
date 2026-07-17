import SwiftUI

// ChainTutorialView — a hands-on little lesson: tap demo blooms and watch them
// join a practice ring, exactly like the real one on Today. Reach three and a
// crown appears on a practice Posey. Nothing here touches her real chain; it
// exists so the feature explains itself in twenty seconds of play.
struct ChainTutorialView: View {
    @Environment(Theme.self) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var demoChain: [String] = []
    @State private var crownBurst = 0

    private let demoBlooms = ["daisy", "tulip", "blossom", "rose", "sunflower"]

    var body: some View {
        ScrollView {
            VStack(spacing: FFSpace.s4) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Make a daisy chain")
                            .font(ffDisplay(FFType.xl, weight: .bold))
                            .foregroundStyle(theme.color(.deep))
                        Text("A practice ring. Tap blooms and watch them join it.")
                            .font(ffBody(FFType.sm))
                            .foregroundStyle(theme.color(.muted))
                    }
                    Spacer()
                    FFIconButton("xmark") { dismiss() }
                }

                // The practice ring, with Posey at its heart once crowned.
                ZStack {
                    Circle()
                        .stroke(theme.color(.surfaceSoft), lineWidth: 12)
                        .frame(width: 150, height: 150)
                    RingChainView(chain: demoChain, radius: 75)
                    if demoChain.count >= 3 {
                        demoPosey
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Text(demoChain.isEmpty ? "your ring" : "\(demoChain.count) of 3")
                            .font(ffBody(FFType.xs, weight: .bold)).tracking(0.6)
                            .foregroundStyle(theme.color(.muted))
                    }
                }
                .frame(height: 190)
                .overlay(SparkleBurst(trigger: crownBurst, count: 20))
                .animation(FFMotion.spring, value: demoChain.count)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(demoChain.count >= 3
                    ? "Practice ring with \(demoChain.count) blooms and a crowned Posey"
                    : "Practice ring with \(demoChain.count) of 3 blooms")

                Text(stepLine)
                    .font(ffBody(FFType.sm, weight: .semibold))
                    .foregroundStyle(theme.color(.deep))
                    .multilineTextAlignment(.center)
                    .animation(nil, value: demoChain.count)

                // The practice blooms.
                HStack(spacing: FFSpace.s2) {
                    ForEach(demoBlooms, id: \.self) { id in
                        demoBloomChip(id)
                    }
                }

                Text("Your real chain works the same way: in the shop, tap the blooms you own into a chain and they circle your Today ring together. Three or more and Posey wears them as a crown.")
                    .font(ffBody(FFType.xs))
                    .foregroundStyle(theme.color(.muted))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)

                FFButton("Got it, let's chain mine", style: .primary, icon: "link") { dismiss() }
            }
            .padding(FFSpace.s5)
        }
        .background(theme.color(.bg))
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onChange(of: demoChain.count) { old, new in
            if old < 3 && new >= 3 { crownBurst += 1 }
        }
    }

    private var stepLine: String {
        switch demoChain.count {
        case 0:  "Tap a bloom below to start the chain."
        case 1:  "Lovely. Two more for a crown."
        case 2:  "One more. Posey is watching."
        default: "A crown! She'll wear yours just like this."
        }
    }

    // Practice Posey: the bloom with the demo chain fanned over her petals,
    // using the exact same crown geometry the real Posey wears.
    private var demoPosey: some View {
        FlowerMark(size: 46)
            .overlay {
                ZStack {
                    let chain = Array(demoChain.prefix(7))
                    ForEach(Array(chain.enumerated()), id: \.offset) { i, id in
                        let spot = CoachFlower.crownSpot(index: i, count: chain.count)
                        StickerView(id: id, size: 11)
                            .rotationEffect(.degrees(spot.tilt))
                            .offset(x: spot.x, y: spot.y)
                    }
                }
            }
            .allowsHitTesting(false)
    }

    private func demoBloomChip(_ id: String) -> some View {
        let chained = demoChain.contains(id)
        return Button {
            withAnimation(FFMotion.spring) {
                if let i = demoChain.firstIndex(of: id) { demoChain.remove(at: i) }
                else { demoChain.append(id) }
            }
        } label: {
            VStack(spacing: 3) {
                StickerView(id: id, size: 34)
                    .frame(height: 42)
                Image(systemName: chained ? "checkmark.circle.fill" : "plus.circle")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.color(chained ? .good : .muted))
            }
            .frame(maxWidth: .infinity, minHeight: FFSpace.tapMin + 16)
            .background(theme.color(chained ? .surfaceSoft : .surface),
                        in: RoundedRectangle(cornerRadius: FFRadius.sm, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: FFRadius.sm, style: .continuous)
                    .strokeBorder(chained ? theme.color(.primaryStrong) : theme.color(.line),
                                  lineWidth: chained ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Practice \(RewardsStore.flowers.first { $0.id == id }?.name ?? id)\(chained ? ", chained" : "")")
    }
}
