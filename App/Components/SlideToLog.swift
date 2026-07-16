import SwiftUI

// SlideToLog — the commit gesture. A wide rectangular tab (flower on the left,
// a right-pointing triangle on the right) rides a shimmering track; it follows
// the thumb organically, sprays petals UP and DOWN as it travels, and completes
// past 80% with a burst + success haptic. A plain TAP commits too. Springs back
// if released early; dimmed and inert when there's nothing new to log.
//
// Concentric geometry (the design math):
//   track height 56  →  capsule corner radius 28
//   knob inset 6pt on every side  →  knob 44pt tall (≥44pt tap target)
//   knob corner radius = 28 − 6 = 22   (inner radius = outer − inset,
//   so the knob's corners share the track's centers — true concentricity)
//   rest offset x = 6; travel = width − knobW − 12; full: right edge = W − 6.
struct SlideToLog: View {
    @Environment(Theme.self) private var theme
    @Environment(RewardsStore.self) private var rewards
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var enabled: Bool
    var onCommit: () -> Void

    @State private var dragX: CGFloat = 0
    @State private var dragging = false
    @State private var committed = false
    @State private var burst = 0
    @State private var petals: [TrailPetal] = []
    @State private var lastEmitX: CGFloat = 0
    @State private var shimmerPhase = false

    private let height: CGFloat = 56
    private let inset: CGFloat = 6
    private let knobW: CGFloat = 76
    private var knobH: CGFloat { height - inset * 2 }          // 44
    private var knobRadius: CGFloat { height / 2 - inset }     // 22 — concentric

    var body: some View {
        GeometryReader { geo in
            let travel = max(geo.size.width - knobW - inset * 2, 1)
            let progress = min(max(dragX / travel, 0), 1)

            ZStack(alignment: .leading) {
                track
                label(progress: progress)
                petalTrail
                knobView
                    .offset(x: inset + dragX)
                    .gesture(drag(travel: travel))
                    .onTapGesture { if !committed { complete(travel: travel) } }
                SparkleBurst(trigger: burst, count: 20)
                    .offset(x: inset + dragX + knobW / 2)
            }
        }
        .frame(height: height)
        .opacity(enabled ? 1 : 0.45)
        .allowsHitTesting(enabled && !committed)
        .sensoryFeedback(.success, trigger: committed)
        .sensoryFeedback(.selection, trigger: petals.count)
        .accessibilityRepresentation {
            Button("Log this day") { complete(travel: 1) }
                .disabled(!enabled)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false)) {
                shimmerPhase = true
            }
        }
    }

    // MARK: pieces

    private var track: some View {
        Capsule()
            .fill(theme.color(.surfaceSoft))
            .overlay(
                Capsule()
                    .fill(theme.color(.primary).opacity(0.28))
                    .frame(width: inset + knobW + dragX)
                    .frame(maxWidth: .infinity, alignment: .leading)
            )
            .overlay(shimmer)
            .overlay(Capsule().strokeBorder(theme.color(.line), lineWidth: 1))
            .clipShape(Capsule())
    }

    @ViewBuilder private var shimmer: some View {
        if !reduceMotion && !committed {
            LinearGradient(colors: [.clear, .white.opacity(0.5), .clear],
                           startPoint: .leading, endPoint: .trailing)
                .frame(width: 90)
                .offset(x: shimmerPhase ? 320 : -110)
                .allowsHitTesting(false)
        }
    }

    private func label(progress: CGFloat) -> some View {
        Text(committed ? "Logged" : "Slide to log")
            .font(ffBody(FFType.sm, weight: .bold))
            .tracking(0.6)
            .foregroundStyle(theme.color(committed ? .good : .muted))
            .frame(maxWidth: .infinity)
            .opacity(committed ? 1 : Double(1 - progress * 1.6))
            .animation(FFMotion.fast, value: committed)
    }

    // The tab: flower at left, triangle pointing the way at right.
    private var knobView: some View {
        HStack(spacing: 8) {
            if committed {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(theme.color(.good))
                    .frame(maxWidth: .infinity)
            } else {
                FlowerMark(size: 24)
                Image(systemName: "arrowtriangle.right.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(theme.color(.primaryStrong))
            }
        }
        .padding(.horizontal, 12)
        .frame(width: knobW, height: knobH)
        .background(
            RoundedRectangle(cornerRadius: knobRadius, style: .continuous)
                .fill(theme.color(.surface))
                .shadow(color: theme.shadow, radius: dragging ? 8 : 4, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: knobRadius, style: .continuous)
                .strokeBorder(theme.color(.line), lineWidth: 1)
        )
        .scaleEffect(dragging ? 1.06 : 1)
        .animation(FFMotion.spring, value: dragging)
    }

    @ViewBuilder private var petalTrail: some View {
        ForEach(petals) { p in
            Ellipse()
                .fill(theme.color(p.tint))
                .frame(width: 7, height: 11)
                .rotationEffect(.degrees(p.spin))
                .offset(x: p.x, y: p.y)
                .opacity(p.faded ? 0 : 0.9)
                .allowsHitTesting(false)
        }
    }

    // MARK: gesture

    private func drag(travel: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { v in
                dragging = true
                dragX = min(max(v.translation.width, 0), travel)
                // A pair of petals — one up, one down — every 26pt of travel.
                if !reduceMotion, dragX - lastEmitX > 26 {
                    lastEmitX = dragX
                    emitPetals(at: dragX)
                }
            }
            .onEnded { _ in
                dragging = false
                if dragX > travel * 0.8 { complete(travel: travel) }
                else {
                    withAnimation(FFMotion.spring) { dragX = 0 }
                    lastEmitX = 0
                }
            }
    }

    private func complete(travel: CGFloat) {
        withAnimation(FFMotion.spring) { dragX = travel }
        committed = true
        burst += 1
        rewards.playCelebrationIfOwned()
        // Let the burst and checkmark land before the caller navigates away.
        Task {
            try? await Task.sleep(for: .seconds(0.9))
            onCommit()
            try? await Task.sleep(for: .seconds(0.5))
            withAnimation(FFMotion.signature) {
                committed = false
                dragX = 0
            }
            lastEmitX = 0
            petals.removeAll()
        }
    }

    // One petal fans upward, its twin fans downward — a spray, not a dribble.
    private func emitPetals(at x: CGFloat) {
        let i = petals.count
        let jitter = CGFloat((i &* 2654435761) % 17)
        spawn(TrailPetal(x: x + 14, y: height / 2 - 8,
                         spin: Double((i &* 73) % 50) - 25,
                         tint: i % 3 == 0 ? .flowerCenter : .primary),
              dy: -(36 + jitter), dx: 16 + jitter * 0.5, dSpin: 80)
        spawn(TrailPetal(x: x + 8, y: height / 2 + 2,
                         spin: Double((i &* 131) % 50) - 25,
                         tint: i % 2 == 0 ? .phaseFollicular : .primary),
              dy: 30 + jitter * 0.8, dx: 12 + jitter * 0.4, dSpin: -80)
        if petals.count > 18 { petals.removeFirst(petals.count - 18) }
    }

    private func spawn(_ petal: TrailPetal, dy: CGFloat, dx: CGFloat, dSpin: Double) {
        petals.append(petal)
        let id = petal.id
        withAnimation(.easeOut(duration: 0.75)) {
            if let idx = petals.firstIndex(where: { $0.id == id }) {
                petals[idx].y += dy
                petals[idx].x += dx
                petals[idx].spin += dSpin
                petals[idx].faded = true
            }
        }
    }
}

private struct TrailPetal: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var spin: Double
    var tint: Tok
    var faded = false
}
