import SwiftUI

// RingSticker — her flower rides the cycle ring like a bead on a bangle. The
// hitbox is the flower itself (the rest of the ring keeps its scrub gesture).
// Dragging along the ring band keeps it magnetically locked to the ring —
// always concentric, never offset; fling it and it keeps spinning like a
// fidget spinner, shedding confetti while it's fast. Pull it clearly off the
// band and it PLUCKS free: drop it inside the ring or off to the side and it
// rests there (persisted); carry it back to the band and it snaps on again.
// Reduce Motion: drag still works, no inertia, no trail.
struct RingSticker: View {
    @Environment(Theme.self) private var theme
    @Environment(RewardsStore.self) private var rewards
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let radius: CGFloat
    /// Fraction of the ring (from 12 o'clock, clockwise) covered by the period
    /// arc — landing the flower there pays a small bonus.
    var periodFraction: Double = 0

    @State private var angle: Double = -0.9
    @State private var freePos: CGPoint = .zero    // center-origin, when plucked
    @State private var onRing = true
    @State private var plucked = false             // mid-drag, off the band
    @State private var velocity: Double = 0        // radians / frame
    @State private var dragging = false
    @State private var spinning = false
    @State private var lastDragAngle: Double? = nil
    @State private var trail: [TrailBit] = []
    @State private var settleBurst = 0
    @State private var spins = 0
    @State private var showTease = false
    @State private var showBonus = false

    /// Frame margin: wide enough that a free rest can clear the snap band on
    /// every axis (margin/2 − 14 > snapBand), so "beside the ring" is stable.
    private var diameter: CGFloat { radius * 2 + 96 }
    /// How far off the ring counts as "still on the band" (magnetic snap zone).
    private let snapBand: CGFloat = 26

    /// Where the flower sits right now, center-origin.
    private var pos: CGPoint {
        if plucked || !onRing { return freePos }
        return CGPoint(x: CGFloat(cos(angle)) * radius, y: CGFloat(sin(angle)) * radius)
    }

    var body: some View {
        ZStack {
            chainBlooms

            if let id = rewards.activeSticker {
                // Confetti trail while she spins it fast.
                ForEach(trail) { bit in
                    Ellipse()
                        .fill(theme.color(bit.tint))
                        .frame(width: 6, height: 9)
                        .rotationEffect(.degrees(bit.spin))
                        .offset(x: CGFloat(cos(bit.angle)) * radius,
                                y: CGFloat(sin(bit.angle)) * radius)
                        .opacity(bit.opacity)
                        .allowsHitTesting(false)
                }

                SparkleBurst(trigger: settleBurst, count: 10)
                    .offset(x: pos.x, y: pos.y)
                    .allowsHitTesting(false)

                // The flower: its 44pt circle IS the hitbox — nothing else here
                // grabs touches, so the ring's own scrub gesture keeps the rest.
                StickerView(id: id, size: 38)
                    .scaleEffect(dragging ? 1.2 : 1)
                    .shadow(color: theme.shadow, radius: dragging || spinning ? 6 : 0)
                    .frame(width: FFSpace.tapMin, height: FFSpace.tapMin)
                    .contentShape(Circle())
                    .offset(x: pos.x, y: pos.y)
                    .highPriorityGesture(stickerDrag)
                    .animation(dragging ? nil : FFMotion.spring, value: dragging)
                    .accessibilityLabel("Your flower sticker")
                    .accessibilityHint("Drag along the ring to spin it, or pull it off and set it anywhere")
            }
        }
        .frame(width: diameter, height: diameter)
        .coordinateSpace(name: "ffRingSticker")
        .overlay(alignment: .top) { teaseBubble }
        .overlay(alignment: .bottom) { bonusBadge }
        .onAppear {
            angle = rewards.stickerAngle
            onRing = rewards.stickerMode != "free"
            // Normalized by RADIUS (not the frame) so a rest keeps the same
            // relation to the band across ring sizes (hero vs preview).
            freePos = CGPoint(x: CGFloat(rewards.stickerX) * radius,
                              y: CGFloat(rewards.stickerY) * radius)
        }
        .sensoryFeedback(.selection, trigger: settleBurst)
    }

    // MARK: the daisy chain — her other worn blooms, riding the same ring

    /// Non-bead worn blooms. Spread: evenly spaced from 12 o'clock. Linked
    /// (chain-together mode): snapped up behind the bead, so a drag or fling
    /// of the bead spins the whole chain as one. Tapping any bloom toggles
    /// the mode, same as the Today tab's chain button.
    @ViewBuilder private var chainBlooms: some View {
        let blooms = rewards.ringChain.filter { $0 != rewards.activeSticker }
        ForEach(Array(blooms.enumerated()), id: \.offset) { i, id in
            let p = chainPos(index: i, count: blooms.count)
            StickerView(id: id, size: 26)
                .frame(width: 36, height: 36)
                .contentShape(Circle())
                .onTapGesture {
                    withAnimation(reduceMotion ? nil : FFMotion.spring) {
                        rewards.chainLinked.toggle()
                    }
                }
                .offset(x: p.x, y: p.y)
                .animation(reduceMotion ? nil : FFMotion.spring, value: rewards.chainLinked)
                .accessibilityLabel("\(RewardsStore.flowers.first { $0.id == id }?.name ?? id) on your ring")
                .accessibilityHint(rewards.chainLinked ? "Spreads your flowers back around the ring"
                                                       : "Snaps your flowers together into a chain")
        }
    }

    /// Hoisted out of the ViewBuilder (release type-check lesson). Linked mode
    /// trails the bead clockwise, one bloom-width apart; with no bead to trail
    /// the blooms fall back to the even spread.
    private func chainPos(index: Int, count: Int) -> CGPoint {
        let a: Double
        if rewards.chainLinked && rewards.activeSticker != nil {
            a = angle + Double(index + 1) * Double(32 / radius)
        } else {
            a = Double(index) / Double(max(count, 1)) * 2 * .pi - .pi / 2
        }
        return CGPoint(x: radius * CGFloat(cos(a)), y: radius * CGFloat(sin(a)))
    }

    private var stickerDrag: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("ffRingSticker"))
            .onChanged { v in
                dragging = true
                spinning = false
                let c = diameter / 2
                let dx = v.location.x - c
                let dy = v.location.y - c
                let r = hypot(dx, dy)
                let onBand = abs(r - radius) <= snapBand
                // A free-resting flower needs real movement before it re-beads —
                // a bare tap must never yank it out of its placed spot.
                let moved = hypot(v.translation.width, v.translation.height) > 8
                if onBand && (onRing || moved) {
                    // On the band: magnetically locked to the ring, concentric.
                    plucked = false
                    onRing = true
                    let a = Double(atan2(dy, dx))
                    if let last = lastDragAngle {
                        var delta = a - last
                        if delta > .pi { delta -= 2 * .pi }
                        if delta < -.pi { delta += 2 * .pi }
                        velocity = delta
                        if !reduceMotion, abs(delta) > 0.06 { emitTrail() }
                    }
                    lastDragAngle = a
                    angle = a
                } else if !onBand && (onRing || plucked || moved) {
                    // Plucked: the flower follows her finger anywhere.
                    plucked = true
                    lastDragAngle = nil
                    velocity = 0
                    let limit = c - 14
                    freePos = CGPoint(x: min(max(dx, -limit), limit),
                                      y: min(max(dy, -limit), limit))
                }
                // else: an untraveled touch on a free-resting flower — hold still.
            }
            .onEnded { _ in
                dragging = false
                lastDragAngle = nil
                if plucked {
                    plucked = false
                    let rest = hypot(freePos.x, freePos.y)
                    if abs(rest - radius) <= snapBand {
                        // Dropped onto the band — it beads back onto the ring.
                        angle = Double(atan2(freePos.y, freePos.x))
                        onRing = true
                        rewards.stickerMode = "ring"
                        settle()
                    } else {
                        onRing = false
                        rewards.stickerX = Double(freePos.x / radius)
                        rewards.stickerY = Double(freePos.y / radius)
                        rewards.stickerMode = "free"
                        settleBurst += 1
                        withAnimation(.easeOut(duration: 0.4)) { trail.removeAll() }
                    }
                } else if onRing {
                    rewards.stickerMode = "ring"
                    if !reduceMotion && abs(velocity) > 0.035 {
                        startSpin()
                    } else {
                        settle()
                    }
                }
                // else: an idle tap on a free-resting flower — leave it be.
            }
    }

    // Posey's gentle nudge after the fifth fling in a row.
    @ViewBuilder private var teaseBubble: some View {
        if showTease {
            HStack(spacing: 8) {
                FlowerMark(size: 22)
                Text("All that spinning, petal. Imagine the petals if we stretched.")
                    .font(ffBody(FFType.xs, weight: .medium))
                    .foregroundStyle(theme.color(.text))
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(theme.color(.surface), in: Capsule())
            .overlay(Capsule().strokeBorder(theme.color(.line), lineWidth: 1))
            .shadow(color: theme.shadow, radius: 6, y: 2)
            .transition(.move(edge: .top).combined(with: .opacity))
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder private var bonusBadge: some View {
        if showBonus {
            Label("+5, right on your period day", systemImage: "sparkle")
                .font(ffBody(FFType.xs, weight: .bold))
                .foregroundStyle(theme.color(.deep))
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(theme.color(.phaseMenstrualSoft), in: Capsule())
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .allowsHitTesting(false)
        }
    }

    // The fidget: inertia with gentle friction, confetti while fast.
    private func startSpin() {
        spinning = true
        spins += 1
        if spins >= 5 {
            spins = 0
            Task { @MainActor in
                withAnimation(FFMotion.spring) { showTease = true }
                try? await Task.sleep(for: .seconds(4))
                withAnimation(FFMotion.fast) { showTease = false }
            }
        }
        Task { @MainActor in
            var frames = 0
            while spinning && abs(velocity) > 0.006 && !Task.isCancelled {
                angle += velocity
                velocity *= 0.965
                frames += 1
                if abs(velocity) > 0.05 && frames % 3 == 0 { emitTrail() }
                fadeTrail()
                try? await Task.sleep(for: .milliseconds(16))
            }
            spinning = false
            settle()
        }
    }

    private func settle() {
        velocity = 0
        rewards.stickerAngle = angle
        settleBurst += 1
        checkPeriodLanding()
        Task {
            try? await Task.sleep(for: .seconds(0.8))
            withAnimation(.easeOut(duration: 0.4)) { trail.removeAll() }
        }
    }

    // Landed on the bleed arc? A small once-a-day bonus, with a note.
    private func checkPeriodLanding() {
        guard periodFraction > 0 else { return }
        let deg = angle * 180 / .pi
        var f = ((deg + 90) / 360).truncatingRemainder(dividingBy: 1)
        if f < 0 { f += 1 }
        guard f < periodFraction else { return }
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        guard rewards.awardPeriodLanding(dateKey: df.string(from: Date())) else { return }
        Task { @MainActor in
            withAnimation(FFMotion.spring) { showBonus = true }
            try? await Task.sleep(for: .seconds(3))
            withAnimation(FFMotion.fast) { showBonus = false }
        }
    }

    private func emitTrail() {
        let i = trail.count
        trail.append(TrailBit(
            angle: angle - Double(velocity) * 2,
            spin: Double((i &* 97) % 70) - 35,
            tint: i % 3 == 0 ? .flowerCenter : (i % 2 == 0 ? .primary : .phaseFollicular)
        ))
        if trail.count > 16 { trail.removeFirst(trail.count - 16) }
    }

    private func fadeTrail() {
        for idx in trail.indices { trail[idx].opacity *= 0.9 }
        trail.removeAll { $0.opacity < 0.05 }
    }
}

private struct TrailBit: Identifiable {
    let id = UUID()
    var angle: Double
    var spin: Double
    var tint: Tok
    var opacity: Double = 0.85
}

// RingChainView — her daisy chain: every bloom she's chained in the shop rides
// the ring together, evenly spaced from 12 o'clock. Purely decorative (the one
// ACTIVE sticker stays the draggable bead); no touches stolen from the scrub.
struct RingChainView: View {
    let chain: [String]
    let radius: CGFloat

    var body: some View {
        ZStack {
            ForEach(Array(chain.enumerated()), id: \.offset) { i, id in
                let p = position(for: i)
                StickerView(id: id, size: 19)
                    .offset(x: p.x, y: p.y)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // Hoisted out of the ViewBuilder: the inline CGFloat/Double trig mix made
    // the release build's type-checker time out (simulator builds squeaked by).
    private func position(for index: Int) -> CGPoint {
        let angle: Double = Double(index) / Double(max(chain.count, 1)) * 2 * .pi - .pi / 2
        return CGPoint(x: radius * CGFloat(cos(angle)),
                       y: radius * CGFloat(sin(angle)))
    }
}
