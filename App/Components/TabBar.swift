import SwiftUI

// FFTabBar — the bottom bar in the DS look: a floating white rail with a soft
// rose pill under the active tab. Order is Today / Calendar / Log / Stretch /
// Insights. Icons are SF Symbols carried on the FFTab enum.
enum FFTab: String, CaseIterable, Identifiable {
    case today, calendar, log, stretch, insights
    var id: String { rawValue }
    var title: String {
        switch self { case .today: "Today"; case .calendar: "Calendar"
                      case .log: "Log"; case .stretch: "Stretch"; case .insights: "Insights" }
    }
    var icon: String {
        switch self { case .today: "drop.fill"; case .calendar: "calendar"
                      case .log: "square.and.pencil"; case .stretch: "figure.cooldown"
                      case .insights: "chart.bar.fill" }
    }
}

struct FFTabBar: View {
    @Environment(Theme.self) private var theme
    @Environment(CycleStore.self) private var store
    @Environment(RewardsStore.self) private var rewards
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var selection: FFTab

    // Every 5 seconds, a little light sweeps the Insights tab when there's
    // something new to see there. Stands down once she visits.
    @State private var sweepToken = 0
    private let sweepTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: FFSpace.s1) {
            ForEach(FFTab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(FFSpace.s1 + 2)   // 6
        .background(theme.color(.surface))
        .clipShape(RoundedRectangle(cornerRadius: FFRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: FFRadius.lg, style: .continuous)
                .strokeBorder(theme.color(.line), lineWidth: 1)
        )
        .ffFloatShadow(theme)
        .padding(.horizontal, FFSpace.s4)
        .onReceive(sweepTimer) { _ in
            if store.hasNewInsights && selection != .insights && !reduceMotion {
                sweepToken += 1
            }
        }
    }

    @ViewBuilder private func tabButton(_ tab: FFTab) -> some View {
        let active = tab == selection
        Button {
            withAnimation(FFMotion.spring) { selection = tab }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .overlay(alignment: .topTrailing) {
                        if tab == .today, let e = rewards.activeStickerEmoji {
                            Text(e).font(.system(size: 10)).offset(x: 9, y: -6)
                        }
                    }
                Text(tab.title)
                    .font(ffBody(FFType.xs2, weight: .semibold))
            }
            .foregroundStyle(active ? theme.color(.primaryStrong) : theme.color(.muted))
            .frame(maxWidth: .infinity, minHeight: FFSpace.tapMin)
            .padding(.vertical, FFSpace.s1)
            .background(
                RoundedRectangle(cornerRadius: FFRadius.pill, style: .continuous)
                    .fill(active ? theme.color(.surfaceSoft) : .clear)
            )
            .overlay {
                if tab == .insights && store.hasNewInsights && !active {
                    InsightsSweep(token: sweepToken)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title + (tab == .insights && store.hasNewInsights ? ", new insights" : ""))
        .accessibilityAddTraits(active ? [.isButton, .isSelected] : .isButton)
    }
}

// One diagonal band of light gliding across the Insights tab, re-fired per
// token. The band moves INSIDE a stationary pill-shaped clip of the tab bounds.
private struct InsightsSweep: View {
    let token: Int

    var body: some View {
        GeometryReader { geo in
            SweepBand(width: geo.size.width)
        }
        .clipShape(RoundedRectangle(cornerRadius: FFRadius.pill, style: .continuous))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .id(token)   // new token -> fresh band -> one more sweep
    }
}

private struct SweepBand: View {
    let width: CGFloat
    @State private var x: CGFloat = -30

    var body: some View {
        LinearGradient(colors: [.clear, .white.opacity(0.65), .clear],
                       startPoint: .leading, endPoint: .trailing)
            .frame(width: 26)
            .rotationEffect(.degrees(18))
            .offset(x: x)
            .onAppear {
                x = -30
                withAnimation(.easeInOut(duration: 0.9)) { x = width + 30 }
            }
    }
}
