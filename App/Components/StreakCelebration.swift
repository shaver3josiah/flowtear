import SwiftUI
import UIKit

// StreakCelebration — the ring-center moment after today's log lands:
// "Welcome!" → "Streak +1" (with the petals it paid) → "X days in a row",
// each line springing in over a soft surface disc while gold twinkles wake,
// then everything fades and the day readout returns. Plays once per mount
// and calls onDone. Under Reduce Motion the sequence collapses to the one
// line that matters, shown statically.
struct StreakCelebration: View {
    @Environment(Theme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let streak: Int
    let bonus: Int
    /// The ring's size — the disc covers just its open center.
    let size: CGFloat
    var onDone: () -> Void

    @State private var phase = -1   // -1 hidden · 0 Welcome! · 1 Streak +1 · 2 count · 3 done

    private var line: String? {
        switch phase {
        case 0: "Welcome!"
        case 1: "Streak +1"
        case 2: streak == 1 ? "1 day in a row" : "\(streak) days in a row"
        default: nil
        }
    }

    var body: some View {
        ZStack {
            if (0...2).contains(phase) {
                Circle()
                    .fill(theme.color(.surface).opacity(0.94))
                    .frame(width: size * 0.62, height: size * 0.62)
                    .transition(.opacity)

                VStack(spacing: 4) {
                    if let line {
                        Text(line)
                            .font(ffDisplay(FFType.xl, weight: .bold))
                            .foregroundStyle(theme.color(.deep))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .id(phase)   // each line gets its own entrance
                            .transition(.scale(scale: 0.6).combined(with: .opacity))
                    }
                    if phase >= 1, bonus > 0 {
                        Text("+\(bonus) petals")
                            .font(ffBody(FFType.sm, weight: .semibold))
                            .foregroundStyle(theme.color(.primaryStrong))
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, size * 0.16)

                FFTwinkle(size: 9, color: theme.color(.flowerCenter))
                    .offset(x: -size * 0.18, y: -size * 0.16)
                    .opacity(phase == 2 ? 1 : 0)
                FFTwinkle(size: 6, color: theme.color(.flowerCenter))
                    .offset(x: size * 0.19, y: -size * 0.10)
                    .opacity(phase >= 1 ? 1 : 0)
            }
        }
        .allowsHitTesting(false)
        .sensoryFeedback(.selection, trigger: phase)
        .accessibilityElement()
        .accessibilityLabel(streak == 1
            ? "Streak started, 1 day in a row. \(bonus) petals earned."
            : "Streak plus one, \(streak) days in a row. \(bonus) petals earned.")
        .task {
            UIAccessibility.post(notification: .announcement,
                                 argument: streak == 1
                                    ? "Streak started. \(bonus) petals earned."
                                    : "Streak plus one. \(streak) days in a row. \(bonus) petals earned.")
            // A cancelled sleep (fast tab-away tears the view down) must stop
            // the sequence, not race through the remaining phases.
            if reduceMotion {
                phase = 2
                try? await Task.sleep(for: .seconds(2.2))
                guard !Task.isCancelled else { return }
                phase = 3
                onDone()
                return
            }
            for p in 0...2 {
                withAnimation(FFMotion.spring) { phase = p }
                try? await Task.sleep(for: .seconds(p == 2 ? 1.6 : 1.0))
                guard !Task.isCancelled else { return }
            }
            withAnimation(FFMotion.signature) { phase = 3 }
            onDone()
        }
    }
}
