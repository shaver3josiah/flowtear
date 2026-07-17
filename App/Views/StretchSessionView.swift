import SwiftUI

// Guided stretch session — the interactive player. One move at a time: a big
// timer ring counts the hold, the cue sits underneath, haptics mark each
// transition, and finishing marks the day done with a petal celebration.
// Pause, skip, or step back anytime; reduced-motion gets a calm fade-only run.
struct StretchSessionView: View {
    @Environment(Theme.self) private var theme
    @Environment(CycleStore.self) private var store
    @Environment(RewardsStore.self) private var rewards
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let day: StretchDay
    var finishTitle: String = "Session done"
    var multiplier: Int = 1
    /// The calendar date completions and awards land on. Defaults to today;
    /// a session run from a plan day's schedule row passes THAT day, so the
    /// row's checkboxes light up and nothing can be earned twice.
    var logDate: Date = Date()

    @State private var index = 0            // current move
    @State private var remaining = 0        // seconds left on this move
    @State private var paused = false
    @State private var finished = false
    @State private var transitionToken = 0  // haptic trigger
    @State private var earned = 0           // petals collected this session
    @State private var cheer: String? = nil // Posey's between-move encouragement

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var move: StretchMove { day.moves[min(index, day.moves.count - 1)] }
    private var progress: Double {
        move.seconds > 0 ? 1 - Double(remaining) / Double(move.seconds) : 1
    }

    var body: some View {
        ZStack {
            theme.color(.bg).ignoresSafeArea()
            if finished { finishedView } else { playerView }
        }
        .onAppear { remaining = day.moves.first?.seconds ?? 0 }
        .onReceive(tick) { _ in
            guard !paused, !finished else { return }
            if remaining > 1 { remaining -= 1 } else { advance() }
        }
        .sensoryFeedback(.success, trigger: finished)
        .sensoryFeedback(.impact, trigger: transitionToken)
    }

    // MARK: player

    private var playerView: some View {
        VStack(spacing: FFSpace.s5) {
            header

            Spacer(minLength: 0)

            // Timer ring with the move's icon at its heart.
            ZStack {
                Circle().stroke(theme.color(.surfaceSoft), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(theme.color(.phaseLuteal),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(reduceMotion ? nil : .linear(duration: 1), value: progress)
                VStack(spacing: 6) {
                    PoseFigure(move: move, size: 62, color: theme.color(.phaseLuteal))
                    Text(timeText)
                        .font(ffNumber(FFType.xl3, weight: .semibold))
                        .foregroundStyle(theme.color(.deep))
                        .contentTransition(.numericText())
                    Text(move.hold)
                        .font(ffBody(FFType.sm, weight: .medium))
                        .foregroundStyle(theme.color(.muted))
                }
            }
            .frame(width: 240, height: 240)
            .overlay(SparkleBurst(trigger: transitionToken, count: 16))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(move.name), \(remaining) seconds left")

            VStack(spacing: FFSpace.s2) {
                Text(move.name)
                    .font(ffDisplay(FFType.xl, weight: .bold))
                    .foregroundStyle(theme.color(.deep))
                    .multilineTextAlignment(.center)
                Text(move.cue)
                    .font(ffBody(FFType.base))
                    .foregroundStyle(theme.color(.text))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, FFSpace.s5)
            }
            .id(index)
            .transition(reduceMotion ? .opacity : .ffViewIn)

            Spacer(minLength: 0)
            controls
        }
        .padding(FFSpace.s5)
    }

    private var header: some View {
        VStack(spacing: FFSpace.s3) {
            HStack {
                FFIconButton("xmark") { dismiss() }
                    .accessibilityLabel("End session")
                Spacer()
                if earned > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(theme.color(.flowerCenter))
                        Text("+\(earned)")
                            .font(ffNumber(FFType.sm, weight: .semibold))
                            .foregroundStyle(theme.color(.deep))
                            .contentTransition(.numericText())
                    }
                    .animation(reduceMotion ? nil : FFMotion.spring, value: earned)
                    .accessibilityLabel("\(earned) petals earned so far")
                }
                Text("Move \(index + 1) of \(day.moves.count)")
                    .font(ffBody(FFType.sm, weight: .semibold))
                    .foregroundStyle(theme.color(.muted))
            }
            // Session progress: one segment per move.
            HStack(spacing: 4) {
                ForEach(day.moves.indices, id: \.self) { i in
                    Capsule()
                        .fill(theme.color(i < index ? .phaseLuteal : (i == index ? .primaryStrong : .surfaceSoft)))
                        .frame(height: 4)
                }
            }
            .accessibilityHidden(true)
            // Posey's between-move whisper, gone again in a couple of seconds.
            if let line = cheer {
                Text(line)
                    .font(ffBody(FFType.xs, weight: .semibold))
                    .foregroundStyle(theme.color(.primaryStrong))
                    .transition(.opacity)
                    .task(id: line) {
                        try? await Task.sleep(for: .seconds(2.4))
                        withAnimation(reduceMotion ? nil : FFMotion.fast) {
                            if cheer == line { cheer = nil }
                        }
                    }
            }
        }
    }

    /// A different whisper each transition; the midpoint gets its own.
    private func sayCheer() {
        let midpoint = day.moves.count / 2
        let line: String
        if index == midpoint && day.moves.count >= 3 {
            line = "Halfway there. You're doing lovely."
        } else {
            let lines = ["Beautiful. Next one, petal.",
                         "That's it. Shoulders soft.",
                         "Gorgeous work. Keep breathing.",
                         "One more bloom in the garden."]
            line = lines[index % lines.count]
        }
        withAnimation(reduceMotion ? nil : FFMotion.fast) { cheer = line }
    }

    private var controls: some View {
        HStack(spacing: FFSpace.s3) {
            FFIconButton("backward.end.fill") { back() }
                .accessibilityLabel("Previous move")
                .opacity(index == 0 ? 0.4 : 1)
                .disabled(index == 0)
            FFButton(paused ? "Resume" : "Pause",
                     style: paused ? .primary : .soft,
                     icon: paused ? "play.fill" : "pause.fill") {
                paused.toggle()
            }
            .frame(maxWidth: .infinity)
            FFIconButton("forward.end.fill") { advance() }
                .accessibilityLabel("Next move")
        }
    }

    private var timeText: String {
        remaining >= 60 ? String(format: "%d:%02d", remaining / 60, remaining % 60) : "\(remaining)s"
    }

    private func advance() {
        transitionToken += 1
        // The move she just finished counts — check it off (never uncheck),
        // award its points, and pay the first-ever-guided bonus for this pose.
        if !store.stretchMovesDone(on: logDate).contains(index) {
            let doneBefore = store.stretchMovesDone(on: logDate).count
            store.toggleStretchMove(index, on: logDate, totalMoves: day.moves.count)
            earned += rewards.awardPose(dateKey: store.key(for: logDate),
                                        alreadyDone: doneBefore, total: day.moves.count,
                                        multiplier: multiplier)
        }
        earned += rewards.awardGuidedFirstTime(moveName: move.name, multiplier: multiplier)
        if index + 1 < day.moves.count {
            withAnimation(reduceMotion ? nil : FFMotion.signature) {
                index += 1
                remaining = day.moves[index].seconds
            }
            sayCheer()
        } else {
            store.setStretchDone(true, on: logDate)
            rewards.playCelebrationIfOwned()
            withAnimation(reduceMotion ? nil : FFMotion.signature) { finished = true }
        }
    }

    private func back() {
        guard index > 0 else { return }
        transitionToken += 1
        withAnimation(reduceMotion ? nil : FFMotion.signature) {
            index -= 1
            remaining = day.moves[index].seconds
        }
    }

    // MARK: finished

    private var finishedView: some View {
        let streak = store.stretchStreak()
        return ZStack {
            PetalRain(count: 18)
            VStack(spacing: FFSpace.s4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(theme.color(.good))
                Text(finishTitle)
                    .font(ffDisplay(FFType.xl2, weight: .bold))
                    .foregroundStyle(theme.color(.deep))
                if earned > 0 {
                    VStack(spacing: 2) {
                        Text("+\(earned)")
                            .font(ffNumber(FFType.xl3, weight: .semibold))
                            .foregroundStyle(theme.color(.flowerCenter))
                        Text("PETAL POINTS EARNED")
                            .font(ffBody(FFType.xs2, weight: .bold)).tracking(1.2)
                            .foregroundStyle(theme.color(.muted))
                    }
                    .overlay(SparkleBurst(trigger: 1, count: 16))
                }
                if streak >= 2 {
                    HStack(spacing: 5) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(theme.color(.flowerCenter))
                        Text("That makes a \(streak) day streak")
                            .font(ffBody(FFType.sm, weight: .bold))
                            .foregroundStyle(theme.color(.deep))
                    }
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(theme.color(.surface), in: Capsule())
                    .overlay(Capsule().strokeBorder(theme.color(.flowerCenter).opacity(0.6), lineWidth: 1))
                }
                Text("That's \(day.minutes) gentle minutes toward an easier period.")
                    .font(ffBody(FFType.base))
                    .foregroundStyle(theme.color(.muted))
                    .multilineTextAlignment(.center)
                FFButton("Done", style: .primary) { dismiss() }
                    .padding(.top, FFSpace.s2)
            }
            .padding(FFSpace.s6)
        }
    }
}
