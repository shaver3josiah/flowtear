import SwiftUI

// Posey — the stretch coach. A storybook flower with a face: blinking eyes,
// rosy cheeks, a little smile, leaf arms — one of which waves hello. She sways
// on her stem and speaks in a named bubble. Classy company, never clippy.
// Reduce Motion: she stands still (no sway, wave, or blink), everything else intact.
struct CoachFlower: View {
    @Environment(Theme.self) private var theme
    @Environment(RewardsStore.self) private var rewards
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let message: String
    var celebrateToken: Int = 0
    var lastAward: Int = 0
    static let name = "Posey"

    @State private var sway = false
    @State private var wave = false
    @State private var blink = false
    @State private var bounce = false
    @State private var tilt = false
    @State private var watering = false
    @State private var balloon = false
    @State private var starBurst = 0
    @State private var showAward = false
    @State private var awardHideTask: Task<Void, Never>? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            posey
                .frame(width: 68, height: 100)
                .rotationEffect(.degrees(sway ? 2.5 : -2.5), anchor: .bottom)
                .task {
                    guard !reduceMotion else { return }
                    withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { sway = true }
                    // A friendly wave on arrival, then a little something every
                    // ~10 seconds so she always feels alive: wave, bounce, head
                    // tilt, double-blink — round and round. Blinks in between.
                    doWave()
                    var antic = 0
                    while !Task.isCancelled {
                        try? await Task.sleep(for: .seconds(3.3))
                        withAnimation(.easeInOut(duration: 0.09)) { blink = true }
                        try? await Task.sleep(for: .seconds(0.12))
                        withAnimation(.easeInOut(duration: 0.09)) { blink = false }
                        try? await Task.sleep(for: .seconds(3.3))
                        withAnimation(.easeInOut(duration: 0.09)) { blink = true }
                        try? await Task.sleep(for: .seconds(0.12))
                        withAnimation(.easeInOut(duration: 0.09)) { blink = false }
                        try? await Task.sleep(for: .seconds(3.3))
                        switch antic % 3 {
                        case 0: doWave()
                        case 1:
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.45).repeatCount(3, autoreverses: true)) { bounce = true }
                            try? await Task.sleep(for: .seconds(1.0))
                            withAnimation(.easeOut(duration: 0.2)) { bounce = false }
                        default:
                            withAnimation(.easeInOut(duration: 0.5)) { tilt = true }
                            try? await Task.sleep(for: .seconds(1.2))
                            withAnimation(.easeInOut(duration: 0.5)) { tilt = false }
                        }
                        antic += 1
                    }
                }
                .overlay(alignment: .top) { wateringOverlay }
                .overlay(SparkleBurst(trigger: starBurst, count: 14).offset(y: 20))
                .overlay(alignment: .top) {
                    if showAward {
                        Text("+\(lastAward)")
                            .font(ffNumber(FFType.lg, weight: .semibold))
                            .foregroundStyle(theme.color(.flowerCenter))
                            .offset(y: -26)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                // Hidden AFTER the overlays so the transient "+N" text can never
                // surface as a stray VoiceOver element mid-celebration (the award
                // is already spoken via the bubble/points elsewhere).
                .accessibilityHidden(true)
                .onChange(of: celebrateToken) { _, _ in celebrate() }

            // Her speech bubble, with a nameplate.
            VStack(alignment: .leading, spacing: 4) {
                Text(Self.name.uppercased())
                    .font(ffBody(FFType.xs2, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(theme.color(.primaryStrong))
                Text(message)
                    .font(ffBody(FFType.sm, weight: .medium))
                    .foregroundStyle(theme.color(.text))
                    .lineSpacing(3)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(theme.color(.surface),
                        in: RoundedRectangle(cornerRadius: FFRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: FFRadius.md, style: .continuous)
                    .strokeBorder(theme.color(.line), lineWidth: 1)
            )
            .overlay(alignment: .bottomLeading) {
                BubbleTail()
                    .fill(theme.color(.surface))
                    .overlay(BubbleTail().stroke(theme.color(.line), lineWidth: 1))
                    .frame(width: 12, height: 10)
                    .offset(x: -8, y: -14)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel("\(Self.name) says: \(message)")
        }
    }

    // Points! Water her, she swells with pride, stars fly, the number floats up.
    // Reduce Motion keeps the INFORMATION (the +N award readout, shown plainly
    // for a moment) and drops only the theatrics — never both.
    private func celebrate() {
        // Each celebration restarts the full display window — a rapid second
        // check-off must never let the FIRST award's hide truncate the second.
        awardHideTask?.cancel()
        guard !reduceMotion else {
            // If a full-motion celebration was just cancelled (Reduce Motion
            // flipped mid-sequence), clear its theatrics so nothing strands.
            watering = false
            balloon = false
            showAward = true
            awardHideTask = Task {
                try? await Task.sleep(for: .seconds(1.4))
                guard !Task.isCancelled else { return }
                showAward = false
            }
            return
        }
        withAnimation(.easeIn(duration: 0.25)) { watering = true }
        awardHideTask = Task {
            try? await Task.sleep(for: .seconds(0.5))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.2)) { watering = false }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) { balloon = true }
            starBurst += 1
            withAnimation(FFMotion.spring) { showAward = true }
            try? await Task.sleep(for: .seconds(0.9))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.35)) { balloon = false; showAward = false }
        }
    }

    @ViewBuilder private var wateringOverlay: some View {
        if watering {
            VStack(spacing: 2) {
                Image(systemName: "drop.fill")
                Image(systemName: "drop.fill").font(.system(size: 7))
                Image(systemName: "drop.fill").font(.system(size: 5))
            }
            .font(.system(size: 9))
            .foregroundStyle(theme.color(.phaseFertile))
            .offset(y: -14)
            .transition(.opacity)
        }
    }

    private func doWave() {
        withAnimation(.easeInOut(duration: 0.35).repeatCount(5, autoreverses: true)) { wave = true }
        Task {
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation(.easeOut(duration: 0.3)) { wave = false }
        }
    }

    // MARK: Posey herself — bloom, face, stem, one waving arm

    private var posey: some View {
        ZStack(alignment: .top) {
            StemShape()
                .stroke(theme.color(.good), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                .padding(.top, 36)

            // Left arm rests; right arm waves hello.
            leaf.rotationEffect(.degrees(-52), anchor: .bottomTrailing)
                .offset(x: -18, y: 58)
            leaf.scaleEffect(x: -1)
                .rotationEffect(.degrees(wave ? 76 : 44), anchor: .bottomLeading)
                .offset(x: 18, y: 58)

            FlowerMark(size: 46)
                // The crown she chained on her ring, resting on Posey's petals —
                // an overlay on the bloom itself so it sways, tilts and bounces
                // with her. Same blooms, same order, as the ring.
                .overlay {
                    if rewards.poseyCrowned && rewards.ringChain.count >= 3 {
                        crown
                    }
                }
                .rotationEffect(.degrees(tilt ? 10 : 0), anchor: .bottom)
                .scaleEffect(balloon ? 1.18 : 1, anchor: .bottom)
                .offset(y: bounce ? -5 : 0)
            face
                .rotationEffect(.degrees(tilt ? 10 : 0), anchor: .bottom)
                .offset(y: 15 + (bounce ? -5 : 0))   // rides the bloom
        }
    }

    private var face: some View {
        VStack(spacing: 2.5) {
            HStack(spacing: 5) {
                eye
                eye
            }
            // The faintest contented curve — barely there, like a soft hum.
            // (A wide, deep grin on a face this small read as unsettling; the
            // fix is less mouth, not more.) bloomInk keeps the face legible on
            // her petals in both light and dark palettes.
            SmileShape()
                .stroke(theme.color(.bloomInk).opacity(0.75),
                        style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
                .frame(width: 6, height: 2)
        }
        .overlay(alignment: .leading) { cheek.offset(x: -7, y: 1) }
        .overlay(alignment: .trailing) { cheek.offset(x: 7, y: 1) }
    }

    private var eye: some View {
        Capsule()
            .fill(theme.color(.bloomInk))
            .frame(width: 2.6, height: 4.6)
            .scaleEffect(y: blink ? 0.15 : 1, anchor: .center)
    }

    private var cheek: some View {
        Circle()
            .fill(theme.color(.bloomInk).opacity(0.22))
            .frame(width: 3.6, height: 3.6)
    }

    private var leaf: some View {
        Ellipse()
            .fill(theme.color(.good).opacity(0.85))
            .frame(width: 22, height: 10)
    }

    /// The flower crown: her chained blooms fanned in an arc over the bloom's
    /// crown-line, each tilted outward like a woven daisy chain.
    private var crown: some View {
        let chain = Array(rewards.ringChain.prefix(7))   // a crown, not a hedge
        return ZStack {
            ForEach(Array(chain.enumerated()), id: \.offset) { i, id in
                let spot = Self.crownSpot(index: i, count: chain.count)
                StickerView(id: id, size: 11)
                    .rotationEffect(.degrees(spot.tilt))
                    .offset(x: spot.x, y: spot.y)
            }
        }
        .allowsHitTesting(false)
    }

    /// Crown geometry, hoisted out of the ViewBuilder so the release build's
    /// type-checker never chokes on inline CGFloat/Double trig.
    static func crownSpot(index: Int, count: Int, radius: CGFloat = 24) -> (x: CGFloat, y: CGFloat, tilt: Double) {
        let t: Double = count <= 1 ? 0.5 : Double(index) / Double(count - 1)
        let deg: Double = -142 + 104 * t                 // fan across the top arc
        let rad: Double = deg * .pi / 180
        return (x: radius * CGFloat(cos(rad)),
                y: radius * CGFloat(sin(rad)),
                tilt: (deg + 90) * 0.5)
    }
}

private struct StemShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let x = rect.midX
        p.move(to: CGPoint(x: x, y: rect.minY))
        p.addCurve(to: CGPoint(x: x, y: rect.maxY),
                   control1: CGPoint(x: x - 9, y: rect.minY + rect.height * 0.35),
                   control2: CGPoint(x: x + 9, y: rect.minY + rect.height * 0.7))
        return p
    }
}

private struct SmileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY),
                       control: CGPoint(x: rect.midX, y: rect.maxY + rect.height))
        return p
    }
}

private struct BubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
