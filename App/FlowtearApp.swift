import SwiftUI

@main
struct FlowtearApp: App {
    @State private var theme = Theme()
    @State private var store = CycleStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(theme)
                .environment(store)
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
    @State private var tab: FFTab = .today
    @State private var logDate = Date()

    var body: some View {
        ZStack {
            theme.color(.bg).ignoresSafeArea()
            VStack(spacing: FFSpace.s3) {
                Group {
                    switch tab {
                    case .today:    TodayView(onLog: openLog, onOpenStretch: { switchTo(.stretch) })
                    case .calendar: CalendarView(onLog: openLog)
                    case .log:      LogView(date: $logDate)
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
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
    }

    private func openLog(_ date: Date) {
        logDate = date
        switchTo(.log)
    }

    private func switchTo(_ t: FFTab) {
        withAnimation(FFMotion.spring) { tab = t }
    }
}
