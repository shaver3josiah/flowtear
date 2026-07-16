import SwiftUI

// The stretch garden: points pill, the flower shop (10 flowers of rising rarity
// + Posey), theme/accent/Color-Studio unlocks, sticker equipping, the rules
// sheet, and the shareable lifetime card.

// MARK: - Points pill (lives in the Stretch header)

struct PointsPill: View {
    @Environment(Theme.self) private var theme
    @Environment(RewardsStore.self) private var rewards

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "sparkle")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(theme.color(.flowerCenter))
            Text("\(rewards.balance)")
                .font(ffNumber(FFType.sm, weight: .semibold))
                .foregroundStyle(theme.color(.deep))
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(theme.color(.surface), in: Capsule())
        .overlay(Capsule().strokeBorder(theme.color(.line), lineWidth: 1))
        .animation(FFMotion.spring, value: rewards.balance)
        .accessibilityLabel("\(rewards.balance) petal points")
    }
}

// MARK: - The shop

struct GardenShopView: View {
    @Environment(Theme.self) private var theme
    @Environment(RewardsStore.self) private var rewards
    @Environment(\.dismiss) private var dismiss
    @State private var showShare = false
    @State private var buyBurst = 0

    private let columns = [GridItem(.adaptive(minimum: 104), spacing: FFSpace.s3)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FFSpace.section) {
                header
                stickerNote
                flowerGrid
                poseyCard
                themeSection
                shareButton
            }
            .padding(FFSpace.s5)
        }
        .background(theme.color(.bg))
        .overlay(SparkleBurst(trigger: buyBurst, count: 24))
        .sheet(isPresented: $showShare) { ShareCardView() }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("The garden shop")
                    .font(ffDisplay(FFType.xl, weight: .bold))
                    .foregroundStyle(theme.color(.deep))
                Text("Spend your petal points. Lifetime score never goes down.")
                    .font(ffBody(FFType.sm)).foregroundStyle(theme.color(.muted))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                PointsPill()
                FFIconButton("xmark") { dismiss() }
            }
        }
    }

    private var stickerNote: some View {
        Text("Flowers you own become stickers — tap one to wear it on your Today tab.")
            .font(ffBody(FFType.xs))
            .foregroundStyle(theme.color(.muted))
    }

    private var flowerGrid: some View {
        LazyVGrid(columns: columns, spacing: FFSpace.s3) {
            ForEach(RewardsStore.flowers) { f in
                flowerCell(f)
            }
        }
    }

    private func flowerCell(_ f: FlowerItem) -> some View {
        let owned = rewards.ownedFlowers.contains(f.id)
        let equipped = rewards.activeSticker == f.id
        let affordable = rewards.canAfford(f.price)
        return Button {
            if owned {
                rewards.activeSticker = equipped ? nil : f.id
            } else if rewards.buyFlower(f.id) {
                buyBurst += 1
            }
        } label: {
            VStack(spacing: 6) {
                Text(f.emoji).font(.system(size: 34))
                    .saturation(owned || affordable ? 1 : 0.35)
                Text(f.name)
                    .font(ffBody(FFType.sm, weight: .semibold))
                    .foregroundStyle(theme.color(.text))
                Text(f.rarity.uppercased())
                    .font(ffBody(FFType.xs2, weight: .bold)).tracking(0.6)
                    .foregroundStyle(theme.color(.phaseLuteal))
                Group {
                    if equipped {
                        Label("Worn", systemImage: "checkmark")
                    } else if owned {
                        Text("Tap to wear")
                    } else {
                        Label("\(f.price)", systemImage: "sparkle")
                    }
                }
                .font(ffBody(FFType.xs, weight: .bold))
                .foregroundStyle(equipped ? .white : theme.color(owned ? .primaryStrong : (affordable ? .deep : .muted)))
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(equipped ? theme.color(.primaryStrong) : theme.color(.surfaceSoft), in: Capsule())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FFSpace.s3)
            .background(theme.color(.surface), in: RoundedRectangle(cornerRadius: FFRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: FFRadius.md, style: .continuous)
                    .strokeBorder(equipped ? theme.color(.primaryStrong) : theme.color(.line),
                                  lineWidth: equipped ? 1.5 : 1)
            )
        }
        .buttonStyle(FFPressButtonStyle(scale: 0.96))
        .sensoryFeedback(.success, trigger: rewards.ownedFlowers.contains(f.id))
        .accessibilityLabel("\(f.name), \(f.rarity), \(owned ? (equipped ? "worn" : "owned") : "\(f.price) points")")
    }

    private var poseyCard: some View {
        let owned = rewards.poseyOwned
        let equipped = rewards.activeSticker == "posey"
        return FFCard(variant: .accent) {
            HStack(spacing: 14) {
                FlowerMark(size: 44)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Posey herself")
                        .font(ffDisplay(FFType.md, weight: .semibold))
                        .foregroundStyle(theme.color(.deep))
                    Text(owned ? "She's yours. The rarest bloom in the garden."
                               : "The legendary sticker. Your coach, on your Today tab.")
                        .font(ffBody(FFType.xs)).foregroundStyle(theme.color(.muted))
                }
                Spacer(minLength: 4)
                Button {
                    if owned { rewards.activeSticker = equipped ? nil : "posey" }
                    else if rewards.buyPosey() { buyBurst += 1 }
                } label: {
                    Group {
                        if equipped { Label("Worn", systemImage: "checkmark") }
                        else if owned { Text("Wear") }
                        else { Label("\(RewardsStore.poseyPrice)", systemImage: "sparkle") }
                    }
                    .font(ffBody(FFType.xs, weight: .bold))
                    .foregroundStyle(equipped ? .white : theme.color(.deep))
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(equipped ? theme.color(.primaryStrong) : theme.color(.surfaceSoft), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // Themes / accent / Color Studio — the expensive shelf.
    private var themeSection: some View {
        VStack(alignment: .leading, spacing: FFSpace.s3) {
            Text("Palettes & colors")
                .font(ffBody(FFType.md, weight: .semibold)).foregroundStyle(theme.color(.deep))
            ForEach(Theme.presetNames.filter { !RewardsStore.freeThemes.contains($0) }, id: \.self) { name in
                unlockRow(icon: nil, swatch: Theme.swatch(for: name),
                          title: "\(Theme.label(for: name)) palette",
                          owned: rewards.themeOwned(name), price: RewardsStore.themePrice) {
                    if rewards.buyTheme(name) { buyBurst += 1 }
                }
            }
            unlockRow(icon: "paintpalette.fill", swatch: nil, title: "Custom accent color",
                      owned: rewards.accentUnlocked, price: RewardsStore.accentPrice) {
                if rewards.buyAccent() { buyBurst += 1 }
            }
            unlockRow(icon: "slider.horizontal.3", swatch: nil, title: "Color Studio — recolor nearly everything",
                      owned: rewards.colorStudioUnlocked, price: RewardsStore.colorStudioPrice) {
                if rewards.buyColorStudio() { buyBurst += 1 }
            }
            Text("Cherry, Rose and Dark are always free. Unlocked colors live in the pencil settings on Today.")
                .font(ffBody(FFType.xs2)).foregroundStyle(theme.color(.muted))
        }
    }

    private func unlockRow(icon: String?, swatch: Color?, title: String,
                           owned: Bool, price: Int, buy: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            if let swatch {
                Circle().fill(swatch).frame(width: 20, height: 20)
                    .overlay(Circle().strokeBorder(theme.color(.line), lineWidth: 1))
            } else if let icon {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.color(.primaryStrong))
                    .frame(width: 20)
            }
            Text(title).font(ffBody(FFType.sm, weight: .semibold)).foregroundStyle(theme.color(.text))
            Spacer(minLength: 4)
            if owned {
                Label("Owned", systemImage: "checkmark")
                    .font(ffBody(FFType.xs, weight: .bold)).foregroundStyle(theme.color(.good))
            } else {
                Button(action: buy) {
                    Label("\(price)", systemImage: "sparkle")
                        .font(ffBody(FFType.xs, weight: .bold))
                        .foregroundStyle(theme.color(rewards.canAfford(price) ? .deep : .muted))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(theme.color(.surfaceSoft), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(theme.color(.surface), in: RoundedRectangle(cornerRadius: FFRadius.md, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: FFRadius.md, style: .continuous)
            .strokeBorder(theme.color(.line), lineWidth: 1))
    }

    private var shareButton: some View {
        FFButton("Share your garden", style: .soft, icon: "square.and.arrow.up") {
            showShare = true
        }
    }
}

// MARK: - The rules, written for her

struct StretchRulesView: View {
    @Environment(Theme.self) private var theme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FFSpace.section) {
                HStack {
                    Text("How the garden grows")
                        .font(ffDisplay(FFType.xl, weight: .bold))
                        .foregroundStyle(theme.color(.deep))
                    Spacer()
                    FFIconButton("xmark") { dismiss() }
                }

                rulesCard("Earning petal points", "sparkle", [
                    "Every pose you check off earns 15 points.",
                    "Each pose after the first that day earns an extra +5 — stringing them together pays.",
                    "Finish every pose in the day's session: +10 bonus on top.",
                    "The first time you ever do a pose with the guided player: +30 bonus (once per pose — there are new ones to discover across the plans).",
                ])

                rulesCard("Plan multipliers", "arrow.up.circle", [
                    "Anytime session: everything counts ×1.",
                    "On the 3-day starter plan: everything counts ×2.",
                    "On the full 14-day plan: everything counts ×4.",
                    "The multiplier applies to every point you earn that day, bonuses included.",
                ])

                rulesCard("A worked example", "function", [
                    "On the 3-day starter, you check 4 poses and finish the day, all guided for the first time:",
                    "Poses: 15 + (15+5) + (15+5) + (15+5) = 75. Day bonus: +10. First-time guided: +30 × 4 = 120.",
                    "That's 205 × 2 (starter multiplier) = 410 points in one day.",
                ])

                rulesCard("Spending", "bag", [
                    "Ten flowers of rising rarity — Daisy (100) up to Bouquet (7,500). Own one, wear it as a sticker on your Today tab.",
                    "Posey herself is the legendary sticker: 10,000.",
                    "Palettes — Pink, Peony, Soft, Light: 600 each. Cherry, Rose and Dark are always free.",
                    "Custom accent color: 1,500 — tint the whole app any color you like.",
                    "Color Studio: 8,000 — recolor nearly everything, one color at a time.",
                ])

                rulesCard("The fine print (the kind you'll like)", "heart", [
                    "Your lifetime score only ever goes up — spending never touches it.",
                    "Unchecking a pose returns its points, so no take-backs needed.",
                    "Everything you unlock is yours forever, on this phone.",
                ])
            }
            .padding(FFSpace.s5)
        }
        .background(theme.color(.bg))
    }

    private func rulesCard(_ title: String, _ icon: String, _ lines: [String]) -> some View {
        FFCard {
            VStack(alignment: .leading, spacing: FFSpace.s2) {
                Label(title, systemImage: icon)
                    .font(ffBody(FFType.md, weight: .semibold))
                    .foregroundStyle(theme.color(.deep))
                ForEach(lines, id: \.self) { line in
                    HStack(alignment: .top, spacing: 8) {
                        Circle().fill(theme.color(.primary)).frame(width: 5, height: 5).padding(.top, 6)
                        Text(line).font(ffBody(FFType.sm)).foregroundStyle(theme.color(.text)).lineSpacing(2)
                    }
                }
            }
        }
    }
}

// MARK: - The share card (made to be screenshotted)

struct ShareCardView: View {
    @Environment(Theme.self) private var theme
    @Environment(RewardsStore.self) private var rewards
    @Environment(CycleStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private var daysStretched: Int {
        store.logsSnapshot.filter { $0.stretchDone == true }.count
    }

    var body: some View {
        ZStack {
            theme.color(.bg).ignoresSafeArea()
            PetalRain(count: 14)
            VStack(spacing: FFSpace.s4) {
                Spacer()
                FlowerMark(size: 64, breathe: true)
                Text("My stretch garden")
                    .font(ffDisplay(FFType.xl2, weight: .bold))
                    .foregroundStyle(theme.color(.deep))

                Text("\(rewards.lifetime)")
                    .font(ffNumber(72, weight: .semibold))
                    .foregroundStyle(theme.color(.primaryStrong))
                Text("LIFETIME PETAL POINTS")
                    .font(ffBody(FFType.xs, weight: .bold)).tracking(1.4)
                    .foregroundStyle(theme.color(.muted))

                HStack(spacing: FFSpace.s5) {
                    shareStat("\(daysStretched)", "days stretched")
                    shareStat("\(rewards.ownedFlowers.count + (rewards.poseyOwned ? 1 : 0))", "flowers collected")
                }
                .padding(.top, FFSpace.s2)

                if !rewards.ownedFlowers.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(RewardsStore.flowers.filter { rewards.ownedFlowers.contains($0.id) }) { f in
                            Text(f.emoji).font(.system(size: 24))
                        }
                        if rewards.poseyOwned { FlowerMark(size: 24) }
                    }
                }

                Text("Uncorked")
                    .font(ffScript(30))
                    .foregroundStyle(theme.color(.deep))
                    .padding(.top, FFSpace.s2)
                Spacer()
                Text("Screenshot me and show someone you love.")
                    .font(ffBody(FFType.xs)).foregroundStyle(theme.color(.muted))
                FFButton("Done", style: .soft) { dismiss() }
                    .padding(.bottom, FFSpace.s3)
            }
            .padding(FFSpace.s5)
        }
    }

    private func shareStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(ffNumber(FFType.xl, weight: .semibold)).foregroundStyle(theme.color(.deep))
            Text(label.uppercased()).font(ffBody(FFType.xs2, weight: .bold)).tracking(0.8)
                .foregroundStyle(theme.color(.muted))
        }
    }
}
