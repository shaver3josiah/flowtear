import SwiftUI

// SlideToLog — the commit gesture. A flower knob rides a shimmering track; it
// follows the thumb organically (slight grow while held), sheds petals as it
// travels, and completes with a burst + success haptic past 80%. Springs back
// if released early. Disabled (dimmed, inert) when there's nothing new to log.
// Reduce Motion: no shimmer or petals, plain slide + fade.
struct SlideToLog: View {
    @Environment(Theme.self) private var theme
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
    private let knob: CGFloat = 48

    var body: some View {
        GeometryReader { geo in
            let travel = max(geo.size.width - knob - 8, 1)
            let progress = min(max(dragX / travel, 0), 1)

            ZStack(alignment: .leading) {
                track(progress: progress)
                label(progress: progress, width: geo.size.width)
                petalTrail
                knobView
                    .offset(x: 4 + dragX)
                SparkleBurst(trigger: burst, count: 18)
                    .offset(x: 4 + dragX + knob / 2)
            }
            .gesture(drag(travel: travel))
        }
        .frame(height: height)
        .opacity(enabled ? 1 : 0.45)
        .allowsHitTesting(enabled && !committed)
        .sensoryFeedback(.success, trigger: committed)
        .sensoryFeedback(.selection, trigger: petals.count)
        .accessibilityRepresentation {
            // A plain button for assistive tech — the gesture is the flourish,
            // not the only path.
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

    private func track(progress: CGFloat) -> some View {
        Capsule()
            .fill(theme.color(.surfaceSoft))
            .overlay(
                // Filled portion warms behind the knob.
                GeometryReader { g in
                    Capsule()
                        .fill(theme.color(.primary).opacity(0.28))
                        .frame(width: knob + 4 + dragX)
                }
            )
            .overlay(shimmer)
            .overlay(Capsule().strokeBorder(theme.color(.line), lineWidth: 1))
            .clipShape(Capsule())
    }

    // A soft light band drifting along the track — the glimmer.
    @ViewBuilder private var shimmer: some View {
        if !reduceMotion && !committed {
            LinearGradient(
                colors: [.clear, .white.opacity(0.5), .clear],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(width: 90)
            .offset(x: shimmerPhase ? 320 : -110)
            .allowsHitTesting(false)
        }
    }

    private func label(progress: CGFloat, width: CGFloat) -> some View {
        Text(committed ? "Logged" : "Slide to log")
            .font(ffBody(FFType.sm, weight: .bold))
            .tracking(0.6)
            .foregroundStyle(theme.color(committed ? .good : .muted))
            .frame(maxWidth: .infinity)
            .opacity(committed ? 1 : Double(1 - progress * 1.6))
            .animation(FFMotion.fast, value: committed)
    }

    private var knobView: some View {
        ZStack {
            Circle()
                .fill(theme.color(.surface))
                .shadow(color: theme.shadow, radius: dragging ? 8 : 4, y: 2)
            if committed {
                Image(systemName: "checkmark")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(theme.color(.good))
            } else {
                FlowerMark(size: 28)
            }
        }
        .frame(width: knob, height: knob)
        .scaleEffect(dragging ? 1.08 : 1)
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
        DragGesture(minimumDistance: 0)
            .onChanged { v in
                dragging = true
                dragX = min(max(v.translation.width, 0), travel)
                // Shed a petal roughly every 34pt of rightward travel.
                if !reduceMotion, dragX - lastEmitX > 34 {
                    lastEmitX = dragX
                    emitPetal(at: dragX)
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
        onCommit()
        // Settle back to ready after the moment of glory.
        Task {
            try? await Task.sleep(for: .seconds(1.4))
            withAnimation(FFMotion.signature) {
                committed = false
                dragX = 0
            }
            lastEmitX = 0
            petals.removeAll()
        }
    }

    private func emitPetal(at x: CGFloat) {
        let i = petals.count
        let up = i % 2 == 0
        let petal = TrailPetal(
            x: x + 10, y: height / 2 - 6,
            spin: Double((i &* 73) % 60) - 30,
            tint: i % 3 == 0 ? .flowerCenter : (i % 3 == 1 ? .primary : .phaseFollicular)
        )
        petals.append(petal)
        let id = petal.id
        withAnimation(.easeOut(duration: 0.7)) {
            if let idx = petals.firstIndex(where: { $0.id == id }) {
                petals[idx].y += up ? -34 : 26
                petals[idx].x += 14
                petals[idx].spin += up ? 70 : -70
                petals[idx].faded = true
            }
        }
        // Trim the array so long drags stay light.
        if petals.count > 14 { petals.removeFirst(petals.count - 14) }
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
