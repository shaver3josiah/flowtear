import SwiftUI

// RingSticker — her flower rides the cycle ring like a bead on a bangle. Drag
// it and it orbits (always snapped to the ring); fling it and it keeps spinning
// like a fidget spinner, shedding confetti while it's fast, easing to a stop
// with a little sparkle. The resting angle persists. Reduce Motion: drag moves
// it, no inertia, no trail.
struct RingSticker: View {
    @Environment(Theme.self) private var theme
    @Environment(RewardsStore.self) private var rewards
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let radius: CGFloat
    /// Fraction of the ring (from 12 o'clock, clockwise) covered by the period
    /// arc — landing the flower there pays a small bonus.
    var periodFraction: Double = 0

    @State private var angle: Double = -0.9
    @State private var velocity: Double = 0       // radians / frame
    @State private var dragging = false
    @State private var spinning = false
    @State private var lastDragAngle: Double? = nil
    @State private var trail: [TrailBit] = []
    @State private var settleBurst = 0
    @State private var spins = 0
    @State private var showTease = false
    @State private var showBonus = false

    private var diameter: CGFloat { radius * 2 + 56 }

    var body: some View {
        if let id = rewards.activeSticker {
            ZStack {
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

                StickerView(id: id, size: 30)
                    .scaleEffect(dragging ? 1.2 : 1)
                    .shadow(color: theme.shadow, radius: dragging || spinning ? 6 : 0)
                    .offset(x: CGFloat(cos(angle)) * radius,
                            y: CGFloat(sin(angle)) * radius)
                    .overlay(
                        SparkleBurst(trigger: settleBurst, count: 10)
                            .offset(x: CGFloat(cos(angle)) * radius,
                                    y: CGFloat(sin(angle)) * radius)
                    )
                    .animation(dragging ? nil : FFMotion.spring, value: dragging)
            }
            .frame(width: diameter, height: diameter)
            .overlay(alignment: .top) { teaseBubble }
            .overlay(alignment: .bottom) { bonusBadge }
            .contentShape(ringHitArea)
            .gesture(orbitDrag)
            .onAppear { angle = rewards.stickerAngle }
            .sensoryFeedback(.selection, trigger: settleBurst)
            .accessibilityLabel("Your flower sticker on the ring")
            .accessibilityHint("Drag to spin it around the ring")
        }
    }

    // Only the band near the ring grabs touches — the ring's own scrub gesture
    // keeps the interior.
    private var ringHitArea: some Shape {
        Circle().inset(by: 8)
            .subtracting(Circle().inset(by: 52))
    }

    private var orbitDrag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { v in
                dragging = true
                spinning = false
                let c = diameter / 2
                let a = Double(atan2(v.location.y - c, v.location.x - c))
                if let last = lastDragAngle {
                    var delta = a - last
                    if delta > .pi { delta -= 2 * .pi }
                    if delta < -.pi { delta += 2 * .pi }
                    velocity = delta
                    if !reduceMotion, abs(delta) > 0.06 { emitTrail() }
                }
                lastDragAngle = a
                angle = a
            }
            .onEnded { _ in
                dragging = false
                lastDragAngle = nil
                if !reduceMotion && abs(velocity) > 0.035 {
                    startSpin()
                } else {
                    settle()
                }
            }
    }

    // Posey's gentle nudge after the fifth fling in a row.
    @ViewBuilder private var teaseBubble: some View {
        if showTease {
            HStack(spacing: 8) {
                FlowerMark(size: 22)
                Text("All that spinning, petal — imagine the petals if we stretched.")
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
            Label("+5 — right on your period day", systemImage: "sparkle")
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
