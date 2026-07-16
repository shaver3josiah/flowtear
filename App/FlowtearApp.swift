import SwiftUI

@main
struct FlowtearApp: App {
    @State private var theme = Theme()
    @State private var store = CycleStore()
    @State private var rewards = RewardsStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(theme)
                .environment(store)
                .environment(rewards)
                .task {
                    // First open: seed 3 months of lived-in sample data so every
                    // screen previews rich. One-shot, clearable from Insights.
                    store.seedSampleIfFirstLaunch()
                }
        }
    }
}

struct RootView: View {
    @Environment(Theme.self) private var theme
    @Environment(CycleStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab: FFTab = .today
    @State private var logDate = Date()

    var body: some View {
        ZStack {
            theme.color(.bg).ignoresSafeArea()
            VStack(spacing: FFSpace.s3) {
                Group {
                    switch tab {
                    case .today:    TodayView(onLog: openLog, onOpenStretch: { switchTo(.stretch) },
                                              onOpenInsights: { switchTo(.insights) },
                                              onOpenCalendar: { switchTo(.calendar) })
                    case .calendar: CalendarView(onLog: openLog)
                    case .log:      LogView(date: $logDate, onLogged: { switchTo(.today) },
                                            onOpenStretch: { switchTo(.stretch) },
                                            onOpenCalendar: { switchTo(.calendar) },
                                            onOpenInsights: { switchTo(.insights) })
                    case .stretch:  StretchCoachView()
                    case .insights: InsightsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.ffViewIn)
                FFTabBar(selection: $tab)
            }
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .preferredColorScheme(theme.isDarkMode ? .dark : .light)
        // Larger text is real accessibility: allow the full non-accessibility
        // range (three steps past the old xLarge clamp). The layouts are all
        // flexible stacks, so they reflow rather than clip.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        // Whichever way she lands on Insights (tab bar or programmatic), the
        // new-insights shimmer stands down.
        .onChange(of: tab) { _, newTab in
            if newTab == .insights { store.markInsightsSeen() }
        }
        // Keep the period heads-up tracking her latest logs — rebuilt both when
        // she returns AND when she leaves, so logging a period mid-session can
        // never leave a stale "expected in 2 days" queued from the old dates.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active || phase == .background {
                FFReminders.refresh(nextPeriodStart: store.prediction().nextPeriodStart)
            }
        }
        .appLockGate()
    }

    private func openLog(_ date: Date) {
        logDate = date
        switchTo(.log)
    }

    private func switchTo(_ t: FFTab) {
        withAnimation(FFMotion.spring) { tab = t }
    }
}
