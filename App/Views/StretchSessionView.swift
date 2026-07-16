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
        }
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
            rewards.awardPose(dateKey: store.key(for: logDate),
                              alreadyDone: doneBefore, total: day.moves.count,
                              multiplier: multiplier)
        }
        rewards.awardGuidedFirstTime(moveName: move.name, multiplier: multiplier)
        if index + 1 < day.moves.count {
            withAnimation(reduceMotion ? nil : FFMotion.signature) {
                index += 1
                remaining = day.moves[index].seconds
            }
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
        ZStack {
            PetalRain(count: 18)
            VStack(spacing: FFSpace.s4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(theme.color(.good))
                Text(finishTitle)
                    .font(ffDisplay(FFType.xl2, weight: .bold))
                    .foregroundStyle(theme.color(.deep))
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
