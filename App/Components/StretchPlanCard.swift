import SwiftUI

// Today's entry to the cramp-ease stretch plan (Stay Flexy-informed dosing).
// Always visible so the schedule is never lost: in the two weeks before the
// period it shows today's session; outside the window it shows when the plan
// starts. Tapping jumps to the Stretch tab.
struct StretchPlanCard: View {
    @Environment(Theme.self) private var theme
    @Environment(CycleStore.self) private var store
    var action: () -> Void = {}

    private var p: CyclePrediction { store.prediction() }
    private var session: StretchDay? {
        guard let d = p.daysUntilNextPeriod, d >= 1, d <= StretchPlan.totalDays else { return nil }
        return StretchPlan.session(daysUntilPeriod: d)
    }

    var body: some View {
        Button(action: action) {
            FFCard {
                HStack(spacing: 12) {
                    Image(systemName: "figure.cooldown")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(theme.color(.phaseLuteal))
                        .frame(width: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cramp-ease stretch plan")
                            .font(ffBody(FFType.md, weight: .semibold))
                            .foregroundStyle(theme.color(.deep))
                        Text(subtitle)
                            .font(ffBody(FFType.sm))
                            .foregroundStyle(theme.color(.muted))
                            .lineLimit(1).minimumScaleFactor(0.8)
                    }
                    Spacer(minLength: 0)
                    trailingIcon
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the Stretch tab with the 14-day schedule")
    }

    private var subtitle: String {
        if let s = session {
            return "Day \(s.planDay) of \(StretchPlan.totalDays) · \(s.focus) · \(s.minutes) min"
        }
        if p.phase == .menstrual {
            return "On your period — plan resumes after ovulation"
        }
        if let start = p.nextPeriodStart,
           let planStart = Calendar.current.date(byAdding: .day, value: -StretchPlan.totalDays, to: start),
           planStart > Date() {
            return "Starts \(planStart.formatted(.dateTime.month().day())) — see the 14-day schedule"
        }
        return "The 14-day schedule for the two weeks before your period"
    }

    @ViewBuilder private var trailingIcon: some View {
        if session != nil && store.stretchDone(on: Date()) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.color(.good))
        } else {
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.color(.muted))
        }
    }
}
