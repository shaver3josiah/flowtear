#if DEBUG
import SwiftUI

// Preview scaffolding + a gallery of every screen and component rendered as if
// real data was logged. Open this file's canvas to see the whole app at once.
// (All DEBUG-only; nothing here ships.)

enum Sample {
    static let store = CycleStore.preview()
    static let theme = Theme()
    static let rewards = RewardsStore()
    static var prediction: CyclePrediction { store.prediction() }
}

extension View {
    /// Standard preview environment: sample-loaded store + theme, light scheme.
    func previewEnv() -> some View {
        self.environment(Sample.theme)
            .environment(Sample.store)
            .environment(Sample.rewards)
            .preferredColorScheme(.light)
    }
}

// MARK: - Screens

#Preview("Today") { TodayView(onLog: { _ in }).previewEnv() }
#Preview("Calendar") { CalendarView(onLog: { _ in }, focus: .constant(nil)).previewEnv() }
#Preview("Log") { LogPreviewHost().previewEnv() }
#Preview("Insights") { InsightsView().previewEnv() }
#Preview("Stretch coach") { StretchCoachView().previewEnv() }
#Preview("Stretch card (Today)") { StretchPlanCard().previewEnv().padding() }
#Preview("Theme editor") { ThemeEditorSheet().previewEnv() }
#Preview("Garden shop") { GardenShopView().previewEnv() }
#Preview("Rules") { StretchRulesView().previewEnv() }
#Preview("Share card") { ShareCardView().previewEnv() }
#Preview("Tutorial") { StretchTutorialView().previewEnv() }
#Preview("About") { AboutView().previewEnv() }
#Preview("Pose figures") {
    let moves = StretchPlan.days.flatMap { $0.moves }
    var seen = Set<String>()
    let unique = moves.filter { seen.insert($0.name).inserted }
    return ScrollView {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(unique) { m in
                HStack(spacing: 12) {
                    PoseFigure(move: m, size: 34, color: Sample.theme.color(.phaseLuteal))
                    Text(m.name).font(ffBody(FFType.sm))
                }
            }
        }.padding()
    }.previewEnv()
}
#Preview("Stretch session") {
    StretchSessionView(day: StretchPlan.days[2], finishTitle: "Day 3 done").previewEnv()
}

#Preview("Coach flower") {
    CoachFlower(message: "Ready when you are. Even five gentle minutes counts.")
        .previewEnv().padding()
}

#Preview("Slide to log") {
    VStack(spacing: 30) {
        SlideToLog(enabled: true) {}
        SlideToLog(enabled: false) {}
    }.previewEnv().padding()
}

// LogView takes a Date binding; give it one for the preview.
private struct LogPreviewHost: View {
    @State private var date = Date()
    var body: some View { LogView(date: $date) }
}

// MARK: - Hero / tracking components

#Preview("Cycle ring") {
    CycleRing(prediction: Sample.prediction).previewEnv().padding()
}

#Preview("Fertile window + BBT") {
    ScrollView { FertileWindowCard().padding() }.previewEnv()
}

#Preview("Phase detail") {
    PhaseDetailSheet(phase: .luteal, day: 24, cycleLength: 28, isToday: true).previewEnv()
}

#Preview("Phase badges") {
    VStack(spacing: 10) {
        ForEach([CyclePhase.menstrual, .follicular, .fertile, .ovulation, .luteal], id: \.self) {
            PhaseBadge(phase: $0)
        }
    }.previewEnv().padding()
}

#Preview("Flow scale") {
    FlowScale(selection: .constant(.medium)).previewEnv().padding()
}

#Preview("Picker sliders") {
    VStack(spacing: 24) {
        FFPickerSlider(title: "Flow", options: Flow.allCases, label: { $0.label },
                       selection: .constant(.medium), tint: .phaseMenstrual)
        FFPickerSlider(title: "Discharge", options: Discharge.allCases, label: { $0.label },
                       selection: .constant(.eggWhite), tint: .phaseFertile)
    }.previewEnv().padding()
}

#Preview("Day cells") {
    HStack(spacing: 4) {
        DayCell(day: 2, isToday: false, isPeriod: true, isPredicted: false, isFertile: false, isOvulation: false, flow: .heavy) {}
        DayCell(day: 13, isToday: false, isPeriod: false, isPredicted: false, isFertile: true, isOvulation: false) {}
        DayCell(day: 14, isToday: true, isPeriod: false, isPredicted: false, isFertile: true, isOvulation: true) {}
        DayCell(day: 28, isToday: false, isPeriod: false, isPredicted: true, isFertile: false, isOvulation: false) {}
    }.previewEnv().padding()
}

#Preview("Stat tiles") {
    HStack(spacing: 10) {
        StatTile(title: "Cycle day", value: "19", tint: .primary)
        StatTile(title: "Next period", value: "9", unit: "days", tint: .phaseMenstrual)
        StatTile(title: "Phase", value: "Luteal", tint: .phaseLuteal)
    }.previewEnv().padding()
}

#Preview("Intensity bars") {
    VStack(spacing: 10) {
        IntensityBar(label: "Cramps", value: 8, max: 10, tint: .phaseMenstrual)
        IntensityBar(label: "Bloating", value: 5, max: 10, tint: .primary)
        IntensityBar(label: "Headache", value: 3, max: 10, tint: .phaseLuteal)
    }.previewEnv().padding()
}

// MARK: - Core components

#Preview("Buttons") {
    VStack(spacing: 12) {
        FFButton("Primary") {}
        FFButton("Deep", style: .deep) {}
        FFButton("Soft", style: .soft, icon: "plus") {}
        FFButton("Ghost", style: .ghost) {}
    }.previewEnv().padding()
}

#Preview("Chips & badges") {
    VStack(spacing: 12) {
        HStack { FFChip("Happy", selected: true) {}; FFChip("Calm", selected: false) {} }
        HStack { FFBadge("Fertile", tint: .phaseFertile, dot: true); FFBadge("Late", tint: .phaseMenstrual, dot: true) }
    }.previewEnv().padding()
}

#Preview("Card variants") {
    VStack(spacing: 12) {
        FFCard { Text("Plain card").previewText() }
        FFCard(variant: .soft) { Text("Soft card").previewText() }
        FFCard(variant: .outline) { Text("Outline card").previewText() }
    }.previewEnv().padding()
}

private extension Text {
    func previewText() -> some View { self.font(ffBody(FFType.md)).foregroundStyle(Sample.theme.color(.text)) }
}
#endif
