import SwiftUI

// Cramp-ease stretch coach — a luteal-phase (two weeks pre-period) routine that
// shows today's session based on how many days until the period, tracks completion,
// and states the evidence + safety honestly.
struct StretchCoachView: View {
    @Environment(Theme.self) private var theme
    @Environment(CycleStore.self) private var store

    private var today: Date { Date() }
    private var p: CyclePrediction { store.prediction() }
    private var daysUntil: Int? { p.daysUntilNextPeriod }
    private var todaySession: StretchDay? {
        guard let d = daysUntil, d >= 1, d <= StretchPlan.totalDays else { return nil }
        return StretchPlan.session(daysUntilPeriod: d)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: FFSpace.card) {
                header
                if let s = todaySession { todayCard(s) } else { outOfWindowCard }
                evidenceCard
                safetyCard
                fullPlanCard
            }
            .padding(.horizontal, FFSpace.s5)
            .padding(.vertical, FFSpace.s4)
        }
        .background(theme.color(.bg))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Cramp-ease plan")
                .font(ffDisplay(FFType.xl2, weight: .bold))
                .foregroundStyle(theme.color(.deep))
            Text(StretchPlan.summary)
                .font(ffBody(FFType.sm)).foregroundStyle(theme.color(.muted)).lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: today's session

    private func todayCard(_ s: StretchDay) -> some View {
        let done = store.stretchDone(on: today)
        return FFCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Day \(s.planDay) of \(StretchPlan.totalDays)")
                            .font(ffBody(FFType.xs, weight: .bold)).tracking(0.6)
                            .foregroundStyle(theme.color(.muted))
                        Text(s.focus)
                            .font(ffDisplay(FFType.lg, weight: .semibold))
                            .foregroundStyle(theme.color(.deep))
                    }
                    Spacer()
                    Text("\(s.minutes) min")
                        .font(ffBody(FFType.sm, weight: .semibold))
                        .foregroundStyle(theme.color(.phaseLuteal))
                }
                ForEach(s.moves) { moveRow($0) }
                FFButton(done ? "Done for today" : "Mark today done",
                         style: done ? .soft : .primary,
                         icon: done ? "checkmark.circle.fill" : "checkmark") {
                    store.setStretchDone(!done, on: today)
                }
            }
        }
    }

    private func moveRow(_ m: StretchMove) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle().fill(theme.color(.phaseLuteal)).frame(width: 7, height: 7).padding(.top, 6)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(m.name).font(ffBody(FFType.base, weight: .semibold)).foregroundStyle(theme.color(.text))
                    Spacer(minLength: 8)
                    Text(m.hold).font(ffBody(FFType.xs, weight: .medium)).foregroundStyle(theme.color(.muted))
                }
                Text(m.cue).font(ffBody(FFType.sm)).foregroundStyle(theme.color(.muted)).lineSpacing(2)
            }
        }
    }

    // MARK: out of window

    private var outOfWindowCard: some View {
        FFCard(variant: .soft) {
            VStack(alignment: .leading, spacing: 6) {
                Text(outOfWindowTitle)
                    .font(ffBody(FFType.md, weight: .semibold)).foregroundStyle(theme.color(.deep))
                Text(outOfWindowBody)
                    .font(ffBody(FFType.sm)).foregroundStyle(theme.color(.muted)).lineSpacing(3)
            }
        }
    }

    private var outOfWindowTitle: String {
        if p.phase == .menstrual { return "You're on your period" }
        if daysUntil == nil { return "Your plan appears with a bit of history" }
        return "Your plan starts soon"
    }

    private var outOfWindowBody: String {
        if p.phase == .menstrual {
            return "Gentle knees-to-chest and child's pose can still ease cramps today. The full plan picks back up after ovulation, about two weeks before your next period."
        }
        if daysUntil == nil {
            return "Log a couple of cycles and this plan will appear automatically about two weeks before your period."
        }
        if let start = p.nextPeriodStart,
           let planStart = Calendar.current.date(byAdding: .day, value: -StretchPlan.totalDays, to: start) {
            return "It runs the two weeks before your period — starting around \(planStart.formatted(.dateTime.month().day())). We'll surface it on Today when it begins."
        }
        return "It runs the two weeks before your period."
    }

    // MARK: evidence + safety + full plan

    private var evidenceCard: some View {
        FFCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Why this may help")
                    .font(ffBody(FFType.md, weight: .semibold)).foregroundStyle(theme.color(.deep))
                Text(StretchPlan.evidenceNote)
                    .font(ffBody(FFType.sm)).foregroundStyle(theme.color(.text)).lineSpacing(3)
                Text(StretchPlan.dosingNote)
                    .font(ffBody(FFType.xs)).foregroundStyle(theme.color(.muted)).lineSpacing(2)
                Text(StretchPlan.disclaimer)
                    .font(ffBody(FFType.xs, weight: .medium)).foregroundStyle(theme.color(.muted)).lineSpacing(2)
            }
        }
    }

    private var safetyCard: some View {
        FFCard(variant: .outline) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Before you start", systemImage: "exclamationmark.circle")
                    .font(ffBody(FFType.md, weight: .semibold)).foregroundStyle(theme.color(.deep))
                ForEach(StretchPlan.contraindications, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Circle().fill(theme.color(.primary)).frame(width: 5, height: 5).padding(.top, 6)
                        Text(item).font(ffBody(FFType.sm)).foregroundStyle(theme.color(.text)).lineSpacing(2)
                    }
                }
            }
        }
    }

    private var fullPlanCard: some View {
        FFCard {
            DisclosureGroup {
                VStack(spacing: 0) {
                    ForEach(StretchPlan.days) { day in
                        HStack {
                            Text("Day \(day.planDay)")
                                .font(ffBody(FFType.sm, weight: .semibold))
                                .foregroundStyle(theme.color(.phaseLuteal))
                                .frame(width: 52, alignment: .leading)
                            Text(day.focus).font(ffBody(FFType.sm)).foregroundStyle(theme.color(.text))
                            Spacer()
                            Text("\(day.minutes)m").font(ffBody(FFType.xs)).foregroundStyle(theme.color(.muted))
                        }
                        .padding(.vertical, 7)
                        if day.id != StretchPlan.days.last?.id {
                            Rectangle().fill(theme.color(.line)).frame(height: 1)
                        }
                    }
                }
                .padding(.top, 6)
            } label: {
                Text("See all \(StretchPlan.totalDays) days")
                    .font(ffBody(FFType.md, weight: .semibold)).foregroundStyle(theme.color(.deep))
            }
            .tint(theme.color(.primaryStrong))
        }
    }
}
