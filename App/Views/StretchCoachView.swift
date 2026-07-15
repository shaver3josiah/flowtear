import SwiftUI

// Stretch — its own mode. Today's session with a guided interactive player,
// a progress strip for the current 14-day window, the full schedule (each day
// expandable, with done-checks), and the evidence + safety, honestly framed.
struct StretchCoachView: View {
    @Environment(Theme.self) private var theme
    @Environment(CycleStore.self) private var store
    @State private var playing = false
    @State private var expandedDay: Int? = nil

    private var today: Date { Date() }
    private var p: CyclePrediction { store.prediction() }
    private var daysUntil: Int? { p.daysUntilNextPeriod }
    private var todaySession: StretchDay? {
        guard let d = daysUntil, d >= 1, d <= StretchPlan.totalDays else { return nil }
        return StretchPlan.session(daysUntilPeriod: d)
    }
    /// Calendar date a given plan day falls on (nil without a prediction).
    private func date(forPlanDay planDay: Int) -> Date? {
        guard let next = p.nextPeriodStart,
              let start = Calendar.current.date(byAdding: .day, value: -StretchPlan.totalDays, to: next)
        else { return nil }
        return Calendar.current.date(byAdding: .day, value: planDay - 1, to: start)
    }
    private func isDone(planDay: Int) -> Bool {
        guard let d = date(forPlanDay: planDay), d <= today else { return false }
        return store.stretchDone(on: d)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: FFSpace.card) {
                header
                SampleBanner()
                if let s = todaySession { todayCard(s) } else { outOfWindowCard }
                if todaySession != nil { progressStrip }
                scheduleCard
                evidenceCard
                safetyCard
            }
            .padding(.horizontal, FFSpace.s5)
            .padding(.top, FFSpace.s2)
            .padding(.bottom, FFSpace.s6)
        }
        .fullScreenCover(isPresented: $playing) {
            if let s = todaySession { StretchSessionView(day: s) }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Stretch")
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
                        Text("TODAY · DAY \(s.planDay) OF \(StretchPlan.totalDays)")
                            .font(ffBody(FFType.xs2, weight: .bold)).tracking(0.8)
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
                if done {
                    Label("Done for today — lovely work", systemImage: "checkmark.circle.fill")
                        .font(ffBody(FFType.sm, weight: .semibold))
                        .foregroundStyle(theme.color(.good))
                } else {
                    FFButton("Start guided session", style: .primary, icon: "play.fill") {
                        playing = true
                    }
                    FFButton("Mark done without the timer", style: .ghost, size: .sm, icon: "checkmark") {
                        store.setStretchDone(true, on: today)
                    }
                }
            }
        }
    }

    private func moveRow(_ m: StretchMove) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: m.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(theme.color(.phaseLuteal))
                .frame(width: 24)
                .padding(.top, 1)
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

    // MARK: window progress

    private var progressStrip: some View {
        let doneCount = (1...StretchPlan.totalDays).filter { isDone(planDay: $0) }.count
        return FFCard(variant: .soft) {
            VStack(alignment: .leading, spacing: FFSpace.s2) {
                HStack {
                    Text("This window")
                        .font(ffBody(FFType.sm, weight: .semibold))
                        .foregroundStyle(theme.color(.deep))
                    Spacer()
                    Text("\(doneCount) of \(StretchPlan.totalDays) days")
                        .font(ffBody(FFType.sm, weight: .bold))
                        .foregroundStyle(theme.color(.phaseLuteal))
                }
                HStack(spacing: 3) {
                    ForEach(1...StretchPlan.totalDays, id: \.self) { d in
                        Capsule()
                            .fill(theme.color(isDone(planDay: d) ? .phaseLuteal : .surface))
                            .frame(height: 6)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
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
            return "Gentle knees-to-chest and child's pose can still ease cramps today. The full plan picks back up after ovulation — browse the whole schedule below meanwhile."
        }
        if daysUntil == nil {
            return "Log a couple of cycles and the 14-day plan will time itself to the two weeks before your period."
        }
        if let start = date(forPlanDay: 1) {
            return "It runs the two weeks before your period — starting around \(start.formatted(.dateTime.month().day())). The full schedule is below."
        }
        return "It runs the two weeks before your period. The full schedule is below."
    }

    // MARK: full schedule (every day expandable, with done-state)

    private var scheduleCard: some View {
        FFCard {
            VStack(alignment: .leading, spacing: FFSpace.s2) {
                Text("The 14 days")
                    .font(ffBody(FFType.md, weight: .semibold)).foregroundStyle(theme.color(.deep))
                VStack(spacing: 0) {
                    ForEach(StretchPlan.days) { day in
                        scheduleRow(day)
                        if day.id != StretchPlan.days.last?.id {
                            Rectangle().fill(theme.color(.line)).frame(height: 1)
                        }
                    }
                }
            }
        }
    }

    private func scheduleRow(_ day: StretchDay) -> some View {
        let isToday = todaySession?.planDay == day.planDay
        let expanded = expandedDay == day.planDay
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(FFMotion.fast) { expandedDay = expanded ? nil : day.planDay }
            } label: {
                HStack(spacing: 10) {
                    statusIcon(day)
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 6) {
                            Text("Day \(day.planDay)")
                                .font(ffBody(FFType.sm, weight: .bold))
                                .foregroundStyle(theme.color(isToday ? .primaryStrong : .deep))
                            if isToday {
                                Text("today")
                                    .font(ffBody(FFType.xs2, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 7).padding(.vertical, 2)
                                    .background(theme.color(.primaryStrong), in: Capsule())
                            }
                            if let d = date(forPlanDay: day.planDay) {
                                Text(d.formatted(.dateTime.month(.abbreviated).day()))
                                    .font(ffBody(FFType.xs2))
                                    .foregroundStyle(theme.color(.muted))
                            }
                        }
                        Text(day.focus)
                            .font(ffBody(FFType.sm))
                            .foregroundStyle(theme.color(.text))
                    }
                    Spacer(minLength: 4)
                    Text("\(day.minutes)m")
                        .font(ffBody(FFType.xs)).foregroundStyle(theme.color(.muted))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(theme.color(.muted))
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                }
                .padding(.vertical, 9)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Day \(day.planDay), \(day.focus), \(day.minutes) minutes")
            .accessibilityHint(expanded ? "Collapses the moves" : "Shows the moves")

            if expanded {
                VStack(alignment: .leading, spacing: FFSpace.s2) {
                    ForEach(day.moves) { moveRow($0) }
                }
                .padding(.leading, 34)
                .padding(.bottom, FFSpace.s3)
                .transition(.opacity)
            }
        }
    }

    @ViewBuilder private func statusIcon(_ day: StretchDay) -> some View {
        if isDone(planDay: day.planDay) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(theme.color(.good))
        } else {
            Image(systemName: "circle")
                .font(.system(size: 18))
                .foregroundStyle(theme.color(.line))
        }
    }

    // MARK: evidence + safety

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
}
