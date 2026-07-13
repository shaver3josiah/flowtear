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
                    #if DEBUG
                    store.seedSampleIfEmpty()
                    #endif
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
                    case .today:    TodayView(onLog: openLog)
                    case .calendar: CalendarView(onLog: openLog)
                    case .log:      LogView(date: $logDate)
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
        .preferredColorScheme(.light)
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
    }

    private func openLog(_ date: Date) {
        logDate = date
        withAnimation(FFMotion.spring) { tab = .log }
    }
}
