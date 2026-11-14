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
                    // Today's first log pays the streak bonus, whichever screen
                    // it lands from. (Sample data and restores bypass upsert,
                    // so neither can mint petals.)
                    store.onDayLogged = { key, streak in
                        rewards.awardLogStreak(dateKey: key, streak: streak)
                    }
                    // ...and the quick-log Undo takes it back, exactly as paid.
                    store.onDayUnlogged = { key in
                        rewards.revokeLogStreak(dateKey: key)
                    }
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
    @State private var symptomFocus: SymptomFocus? = nil

    var body: some View {
        ZStack {
            theme.color(.bg).ignoresSafeArea()
            VStack(spacing: FFSpace.s3) {
                Group {
                    switch tab {
                    case .today:    TodayView(onLog: openLog, onOpenStretch: { switchTo(.stretch) },
                                              onOpenInsights: { switchTo(.insights) },
                                              onOpenCalendar: { switchTo(.calendar) })
                    case .calendar: CalendarView(onLog: openLog, focus: $symptomFocus)
                    case .log:      LogView(date: $logDate, onLogged: { switchTo(.today) },
                                            onOpenStretch: { switchTo(.stretch) },
                                            onOpenCalendar: { switchTo(.calendar) },
                                            onOpenInsights: { switchTo(.insights) },
                                            onShowSymptomOnCalendar: { symptom, day in
                                                symptomFocus = SymptomFocus(symptom: symptom, anchor: day)
                                                switchTo(.calendar)
                                            })
                    case .stretch:  StretchCoachView()
                    case .insights: InsightsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.ffViewIn)
                // Picking Log from the bar always lands on today — the way
                // every other tracker behaves. Browsing back to Tuesday and
                // coming back tomorrow must never put today's symptoms on
                // Tuesday. Deep links (a calendar day, a symptom's history)
                // go through openLog and keep the day they point at.
                FFTabBar(selection: Binding(
                    get: { tab },
                    set: { t in
                        if t == .log { logDate = Date() }
                        switchTo(t)
                    }
                ))
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
        // Nothing is ever logged forward in time, whichever screen asked.
        // The calendar answers a future day with a prediction sheet instead;
        // this is the backstop for every other caller.
        logDate = min(date, Date())
        switchTo(.log)
    }

    private func switchTo(_ t: FFTab) {
        withAnimation(FFMotion.spring) { tab = t }
    }
}
