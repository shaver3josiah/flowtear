import SwiftUI

// The pencil settings — Bloom-calculator-style theming. Pick one of the full
// palette presets (the two dark moods, Plum Night and Midnight, then Cherry,
// Pink, Rose, Peony, Soft, Light) or lay a custom accent color over any of
// them; the whole app recolors live through the token seam. Cycle-phase and
// flow colors stay fixed — they carry meaning.
struct ThemeEditorSheet: View {
    @Environment(Theme.self) private var theme
    @Environment(RewardsStore.self) private var rewards
    @Environment(CycleStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    /// Close this sheet and jump to the Stretch tab (wired by TodayView).
    var onGoEarn: (() -> Void)? = nil
    @State private var showShop = false
    @State private var petalGap: PetalGap?
    @State private var pendingBuy: PendingBuy?
    @AppStorage("flowtear.petalsOnRing") private var petalsOnRing = true
    @AppStorage("flowtear.quiet") private var quietMode = false
    @AppStorage("flowtear.appLock") private var appLock = false
    @AppStorage(FFReminders.stretchOnKey) private var stretchReminder = false
    @AppStorage(FFReminders.stretchMinutesKey) private var stretchMinutes = 18 * 60
    @AppStorage(FFReminders.periodOnKey) private var periodReminder = false

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: FFSpace.s3)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FFSpace.section) {
                header
                FFButton("Garden shop — spend your petal points", style: .soft, icon: "bag") {
                    showShop = true
                }
                presetSection
                accentSection
                studioSection
                touchesSection
                remindersSection
                privacySection
                Text("Period, fertile and phase colors never change — they mean something.")
                    .font(ffBody(FFType.xs))
                    .foregroundStyle(theme.color(.muted))
            }
            .padding(FFSpace.s5)
        }
        .background(theme.color(.bg))
        .sheet(isPresented: $showShop) { GardenShopView(onGoEarn: { onGoEarn?() }) }
        .sheet(item: $petalGap) { gap in
            NeedMorePetalsView(gap: gap, onGoStretch: { onGoEarn?() })
        }
        .petalPurchaseConfirm($pendingBuy, balance: rewards.balance)
        .onChange(of: stretchReminder) { _, on in replanReminders(justEnabled: on) }
        .onChange(of: periodReminder) { _, on in replanReminders(justEnabled: on) }
        .onChange(of: stretchMinutes) { _, _ in replanReminders(justEnabled: false) }
    }

    private func replanReminders(justEnabled: Bool) {
        let next = store.prediction().nextPeriodStart
        if justEnabled { FFReminders.requestThenRefresh(nextPeriodStart: next) }
        else { FFReminders.refresh(nextPeriodStart: next) }
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
        let owned = rewards.themeOwned(name)
        return Button {
            if owned {
                withAnimation(FFMotion.fast) { theme.setPreset(name) }
            } else if !rewards.canAfford(RewardsStore.themePrice) {
                petalGap = PetalGap(name: "the \(Theme.label(for: name)) palette",
                                    price: RewardsStore.themePrice)
            } else {
                pendingBuy = PendingBuy(name: "the \(Theme.label(for: name)) palette",
                                        price: RewardsStore.themePrice) {
                    if rewards.buyTheme(name) {
                        withAnimation(FFMotion.fast) { theme.setPreset(name) }
                    }
                }
            }
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
                } else if !owned {
                    Label("\(RewardsStore.themePrice)", systemImage: "sparkle")
                        .font(ffBody(FFType.xs2, weight: .bold))
                        .foregroundStyle(theme.color(rewards.canAfford(RewardsStore.themePrice) ? .deep : .muted))
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
        .accessibilityLabel("\(Theme.label(for: name)) palette"
                            + (owned ? "" : ", locked, \(RewardsStore.themePrice) petals"))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: custom accent

    @ViewBuilder private var accentSection: some View {
        if rewards.accentUnlocked {
            unlockedAccent
        } else {
            VStack(alignment: .leading, spacing: FFSpace.s3) {
                sectionTitle("Your color")
                FFCard(variant: .outline) {
                    HStack(spacing: 10) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(theme.color(.muted))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Custom accent color")
                                .font(ffBody(FFType.md, weight: .semibold))
                                .foregroundStyle(theme.color(.text))
                            Text("Unlock with petal points from stretching")
                                .font(ffBody(FFType.xs)).foregroundStyle(theme.color(.muted))
                        }
                        Spacer(minLength: 4)
                        Button {
                            if !rewards.canAfford(RewardsStore.accentPrice) {
                                petalGap = PetalGap(name: "the custom accent color",
                                                    price: RewardsStore.accentPrice)
                            } else {
                                pendingBuy = PendingBuy(name: "the custom accent color",
                                                        price: RewardsStore.accentPrice) {
                                    _ = rewards.buyAccent()
                                }
                            }
                        } label: {
                            Label("\(RewardsStore.accentPrice)", systemImage: "sparkle")
                                .font(ffBody(FFType.xs, weight: .bold))
                                .foregroundStyle(theme.color(rewards.canAfford(RewardsStore.accentPrice) ? .deep : .muted))
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(theme.color(.surfaceSoft), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var unlockedAccent: some View {
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

    // Color Studio — recolor nearly everything, once unlocked in the shop.
    @ViewBuilder private var studioSection: some View {
        if rewards.colorStudioUnlocked {
            VStack(alignment: .leading, spacing: FFSpace.s3) {
                sectionTitle("Color Studio")
                FFCard {
                    VStack(alignment: .leading, spacing: FFSpace.s2) {
                        ForEach(Theme.studioTokens, id: \.rawValue) { tok in
                            ColorPicker(selection: studioBinding(tok), supportsOpacity: false) {
                                Text(Theme.studioLabel(tok))
                                    .font(ffBody(FFType.sm, weight: .medium))
                                    .foregroundStyle(theme.color(.text))
                            }
                        }
                        if !theme.studioOverrides.isEmpty {
                            FFButton("Reset the studio", style: .ghost, size: .sm,
                                     icon: "arrow.uturn.backward") {
                                withAnimation(FFMotion.fast) { theme.resetStudio() }
                            }
                        }
                    }
                }
            }
        }
    }

    // Little touches — the ambient magic, hers to switch off.
    private var touchesSection: some View {
        VStack(alignment: .leading, spacing: FFSpace.s3) {
            sectionTitle("Little touches")
            FFCard {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Falling petals")
                            .font(ffBody(FFType.md, weight: .semibold))
                            .foregroundStyle(theme.color(.text))
                        Text("Petals drift around your cycle ring on Today")
                            .font(ffBody(FFType.xs))
                            .foregroundStyle(theme.color(.muted))
                    }
                    Spacer(minLength: 4)
                    FFSwitch(isOn: $petalsOnRing)
                        .accessibilityLabel("Falling petals around the cycle ring")
                }
                Rectangle().fill(theme.color(.line)).frame(height: 1)
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Quiet mode")
                            .font(ffBody(FFType.md, weight: .semibold))
                            .foregroundStyle(theme.color(.text))
                        Text("Celebration sounds stay silent — the sparkle stays")
                            .font(ffBody(FFType.xs))
                            .foregroundStyle(theme.color(.muted))
                    }
                    Spacer(minLength: 4)
                    FFSwitch(isOn: $quietMode)
                        .accessibilityLabel("Quiet mode, silence celebration sounds")
                }
            }
        }
    }

    // Gentle reminders — opt-in, local-only nudges she controls completely.
    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: FFSpace.s3) {
            sectionTitle("Gentle reminders")
            FFCard {
                VStack(alignment: .leading, spacing: FFSpace.s3) {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Stretch nudge")
                                .font(ffBody(FFType.md, weight: .semibold))
                                .foregroundStyle(theme.color(.text))
                            Text("One soft daily reminder at your time")
                                .font(ffBody(FFType.xs))
                                .foregroundStyle(theme.color(.muted))
                        }
                        Spacer(minLength: 4)
                        FFSwitch(isOn: $stretchReminder)
                            .accessibilityLabel("Daily stretch reminder")
                    }
                    if stretchReminder {
                        DatePicker("Remind me at", selection: stretchTimeBinding,
                                   displayedComponents: .hourAndMinute)
                            .font(ffBody(FFType.sm, weight: .medium))
                            .foregroundStyle(theme.color(.text))
                            .tint(theme.color(.primaryStrong))
                    }
                    Rectangle().fill(theme.color(.line)).frame(height: 1)
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Period heads-up")
                                .font(ffBody(FFType.md, weight: .semibold))
                                .foregroundStyle(theme.color(.text))
                            Text("A note two days before it's expected")
                                .font(ffBody(FFType.xs))
                                .foregroundStyle(theme.color(.muted))
                        }
                        Spacer(minLength: 4)
                        FFSwitch(isOn: $periodReminder)
                            .accessibilityLabel("Period heads-up reminder")
                    }
                    Text("Reminders are scheduled on this phone only — nothing leaves it.")
                        .font(ffBody(FFType.xs2))
                        .foregroundStyle(theme.color(.muted))
                }
            }
        }
    }

    /// stretchMinutes (minutes past midnight) <-> a Date for the picker.
    private var stretchTimeBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: stretchMinutes / 60,
                                      minute: stretchMinutes % 60,
                                      second: 0, of: Date()) ?? Date()
            },
            set: {
                let c = Calendar.current.dateComponents([.hour, .minute], from: $0)
                stretchMinutes = (c.hour ?? 18) * 60 + (c.minute ?? 0)
            }
        )
    }

    // Privacy — the optional Face ID / passcode lock.
    private var privacySection: some View {
        VStack(alignment: .leading, spacing: FFSpace.s3) {
            sectionTitle("Privacy")
            FFCard {
                HStack(spacing: 10) {
                    Image(systemName: "faceid")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(theme.color(.primaryStrong))
                        .frame(width: 26)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Lock with Face ID")
                            .font(ffBody(FFType.md, weight: .semibold))
                            .foregroundStyle(theme.color(.text))
                        Text("Your garden opens only for you — Face ID or your passcode")
                            .font(ffBody(FFType.xs))
                            .foregroundStyle(theme.color(.muted))
                    }
                    Spacer(minLength: 4)
                    FFSwitch(isOn: $appLock)
                        .accessibilityLabel("Lock the app with Face ID")
                }
            }
        }
    }

    private func studioBinding(_ tok: Tok) -> Binding<Color> {
        Binding(
            get: { theme.color(tok) },
            set: { theme.setStudioColor(tok, $0) }
        )
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
