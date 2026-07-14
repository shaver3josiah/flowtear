import SwiftUI

// Contextual Today entry to the cramp-ease stretch plan. Shows only during the
// two weeks before the period (the luteal window); taps open the full coach.
struct StretchPlanCard: View {
    @Environment(Theme.self) private var theme
    @Environment(CycleStore.self) private var store
    @State private var show = false

    private var p: CyclePrediction { store.prediction() }
    private var session: StretchDay? {
        guard let d = p.daysUntilNextPeriod, d >= 1, d <= StretchPlan.totalDays else { return nil }
        return StretchPlan.session(daysUntilPeriod: d)
    }

    var body: some View {
        if let s = session {
            Button { show = true } label: {
                FFCard {
                    HStack(spacing: 12) {
                        Image(systemName: "figure.cooldown")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(theme.color(.phaseLuteal))
                            .frame(width: 30)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Cramp-ease plan")
                                .font(ffBody(FFType.md, weight: .semibold))
                                .foregroundStyle(theme.color(.deep))
                            Text("Day \(s.planDay) of \(StretchPlan.totalDays) · \(s.focus) · \(s.minutes) min")
                                .font(ffBody(FFType.sm)).foregroundStyle(theme.color(.muted))
                                .lineLimit(1).minimumScaleFactor(0.8)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: store.stretchDone(on: Date()) ? "checkmark.circle.fill" : "chevron.right")
                            .font(.system(size: store.stretchDone(on: Date()) ? 18 : 13, weight: .semibold))
                            .foregroundStyle(theme.color(store.stretchDone(on: Date()) ? .good : .muted))
                    }
                }
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $show) {
                StretchCoachView()
                    .presentationDragIndicator(.visible)
            }
        }
    }
}
