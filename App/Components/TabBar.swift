import SwiftUI

// FFTabBar — the four-destination bottom bar in the DS look: a floating white
// rail with a soft rose pill under the active tab. Order is Today / Calendar /
// Log / Insights. Icons are SF Symbols carried on the FFTab enum.
enum FFTab: String, CaseIterable, Identifiable {
    case today, calendar, log, insights
    var id: String { rawValue }
    var title: String {
        switch self { case .today: "Today"; case .calendar: "Calendar"
                      case .log: "Log"; case .insights: "Insights" }
    }
    var icon: String {
        switch self { case .today: "drop.fill"; case .calendar: "calendar"
                      case .log: "square.and.pencil"; case .insights: "chart.bar.fill" }
    }
}

struct FFTabBar: View {
    @Environment(Theme.self) private var theme
    @Binding var selection: FFTab

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
    }

    @ViewBuilder private func tabButton(_ tab: FFTab) -> some View {
        let active = tab == selection
        Button {
            withAnimation(FFMotion.spring) { selection = tab }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.icon)
                    .font(.system(size: 17, weight: .semibold))
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
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(active ? [.isButton, .isSelected] : .isButton)
    }
}
