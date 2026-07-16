import SwiftUI

// Stretch — her coach. A friendly flower cheers her on; the plan knows what day
// she's on automatically; every stretch is a checkbox that celebrates with a
// petal-and-sparkle burst; the whole day can be checked too. Two tiers: the
// 3-day starter (default) and the full 14-day plan — switching either way is
// manual and never touches her logged history (completions live on dates).
struct StretchCoachView: View {
    @Environment(Theme.self) private var theme
    @Environment(CycleStore.self) private var store
    @Environment(RewardsStore.self) private var rewards
    @State private var playing = false
    @State private var showShop = false
    @State private var showRules = false
    @State private var burstToken = 0
    @State private var dayBurstToken = 0
    @State private var expandedDay: Int? = nil

    private var today: Date { Date() }
    private var p: CyclePrediction { store.prediction() }
    private var tier: StretchTier { store.fullStretchPlan ? .full : .starter }
    private var daysUntil: Int? { p.daysUntilNextPeriod }
    private var todaySession: StretchDay? {
        guard let d = daysUntil, d >= 1, d <= tier.totalDays else { return nil }
        return StretchPlan.session(daysUntilPeriod: d, tier: tier)
    }
    /// Off-schedule fallback so checking off stretches is always available.
    private var anytimeSession: StretchDay { StretchPlan.starterDays[0] }
    private var activeSession: StretchDay { todaySession ?? anytimeSession }
    /// Points multiplier: anytime x1, 3-day starter x2, full 14-day x4.
    private var multiplier: Int { todaySession == nil ? 1 : (tier == .full ? 4 : 2) }

    private func date(forPlanDay planDay: Int) -> Date? {
        guard let next = p.nextPeriodStart,
              let start = Calendar.current.date(byAdding: .day, value: -tier.totalDays, to: next)
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
                gardenHeader
                CoachFlower(message: coachLine)
                SampleBanner()
                if let s = todaySession {
                    todayCard(s, heading: "TODAY · DAY \(StretchPlan.planDay(s, tier: tier)) OF \(tier.totalDays)")
                    progressStrip
                } else {
                    outOfWindowCard
                    // Stretching is never locked: any day, she can run and check
                    // off a session — it logs to today like any other.
                    todayCard(anytimeSession, heading: "ANYTIME SESSION · NO SCHEDULE NEEDED")
                }
                planSwitchCard
                scheduleCard
                evidenceCard
                safetyCard
            }
            .padding(.horizontal, FFSpace.s5)
            .padding(.top, FFSpace.s2)
            .padding(.bottom, FFSpace.s6)
        }
        .fullScreenCover(isPresented: $playing) {
            StretchSessionView(day: activeSession, finishTitle: sessionFinishTitle,
                               multiplier: multiplier)
        }
        .sheet(isPresented: $showShop) { GardenShopView() }
        .sheet(isPresented: $showRules) { StretchRulesView() }
    }

    // Points pill + the shop, with the RULES in the top-right corner.
    private var gardenHeader: some View {
        HStack(spacing: FFSpace.s2) {
            PointsPill()
            Spacer(minLength: 0)
            FFIconButton("bag") { showShop = true }
                .accessibilityLabel("Garden shop")
            FFIconButton("book") { showRules = true }
                .accessibilityLabel("How points and unlocks work")
        }
    }

    private var sessionFinishTitle: String {
        if let s = todaySession { return "Day \(StretchPlan.planDay(s, tier: tier)) done" }
        return "Session done"
    }

    // MARK: the coach's voice — warm, specific, never nagging

    private var coachLine: String {
        let dayNumber = Calendar.current.component(.day, from: today)
        let done = store.stretchMovesDone(on: today)
        if store.stretchDone(on: today) {
            return ["All done — I'm so proud I could wilt. Rest those roots.",
                    "Beautiful work today, petal. Even the sun took notes.",
                    "Stretches complete. Somewhere, a garden applauds."][dayNumber % 3]
        }
        if !done.isEmpty {
            return ["You've started — that's the hard part. Keep going, petal.",
                    "Look at you go. A couple more and we're done.",
                    "Halfway feelings are the best feelings, I always say."][dayNumber % 3]
        }
        if let s = todaySession {
            return ["Ready when you are — even five gentle minutes counts.",
                    "Just \(s.minutes) easy minutes today. I'll be right here on my stem.",
                    "No rush, petal. We bloom on our own schedule."][dayNumber % 3]
        }
        if p.phase == .menstrual {
            return ["Rest week, petal. A gentle knees-to-chest still helps if cramps bite.",
                    "You made it — be soft with yourself this week."][dayNumber % 2]
        }
        return ["No schedule today — but stretching is always in season. Care for a quick trio?",
                "Off-plan days are my favorite: no rules, just a little reach and bend.",
                "I'll wave when your plan starts. Meanwhile, the anytime session is right below."][dayNumber % 3]
    }

    // MARK: today's session — day checkbox + per-move checkboxes with bursts

    private func todayCard(_ s: StretchDay, heading: String) -> some View {
        let movesDone = store.stretchMovesDone(on: today)
        let dayDone = store.stretchDone(on: today)
        return FFCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(heading)
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

                // Each stretch is its own little victory.
                ForEach(Array(s.moves.enumerated()), id: \.element.id) { i, m in
                    moveCheckRow(m, index: i, checked: movesDone.contains(i), session: s)
                }

                if !dayDone {
                    FFButton("Start guided session", style: .primary, icon: "play.fill") {
                        playing = true
                    }
                }

                // The whole-day checkbox.
                Button {
                    let finishing = !dayDone
                    store.setStretchDone(finishing, on: today)
                    if finishing { dayBurstToken += 1 }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: dayDone ? "checkmark.square.fill" : "square")
                            .font(.system(size: 19, weight: .medium))
                            .foregroundStyle(theme.color(dayDone ? .good : .muted))
                        Text(dayDone ? "Today's stretching — done" : "Mark the whole day done")
                            .font(ffBody(FFType.sm, weight: .semibold))
                            .foregroundStyle(theme.color(.text))
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                    .frame(minHeight: FFSpace.tapMin)
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.success, trigger: dayBurstToken)
                .accessibilityAddTraits(dayDone ? .isSelected : [])
            }
            .overlay(SparkleBurst(trigger: dayBurstToken, count: 22))
        }
    }

    private func moveCheckRow(_ m: StretchMove, index: Int, checked: Bool, session: StretchDay) -> some View {
        Button {
            let doneBefore = store.stretchMovesDone(on: today).count
            let wasFullDay = doneBefore == session.moves.count
            let completedDay = store.toggleStretchMove(index, on: today, totalMoves: session.moves.count)
            if !checked {
                rewards.awardPose(alreadyDone: doneBefore, total: session.moves.count,
                                  multiplier: multiplier)
                burstToken += 1                      // checking ON celebrates
            } else {
                rewards.revokePose(remainingDone: max(doneBefore - 1, 0),
                                   total: session.moves.count,
                                   wasFullDay: wasFullDay, multiplier: multiplier)
            }
            if completedDay { dayBurstToken += 1 }   // finishing the set celebrates louder
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: checked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(theme.color(checked ? .good : .line))
                    .padding(.top, 1)
                Image(systemName: m.icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(theme.color(.phaseLuteal))
                    .frame(width: 22)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(m.name)
                            .font(ffBody(FFType.base, weight: .semibold))
                            .foregroundStyle(theme.color(.text))
                            .strikethrough(checked, color: theme.color(.muted))
                        Spacer(minLength: 8)
                        Text(m.hold).font(ffBody(FFType.xs, weight: .medium)).foregroundStyle(theme.color(.muted))
                    }
                    Text(m.cue).font(ffBody(FFType.sm)).foregroundStyle(theme.color(.muted)).lineSpacing(2)
                }
            }
            .contentShape(Rectangle())
            .overlay(alignment: .leading) {
                if checked { SparkleBurst(trigger: burstToken, count: 12).offset(x: 10) }
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: checked)
        .accessibilityLabel(m.name)
        .accessibilityAddTraits(checked ? .isSelected : [])
    }

    // MARK: window progress

    private var progressStrip: some View {
        let doneCount = (1...tier.totalDays).filter { isDone(planDay: $0) }.count
        return FFCard(variant: .soft) {
            VStack(alignment: .leading, spacing: FFSpace.s2) {
                HStack {
                    Text("This window")
                        .font(ffBody(FFType.sm, weight: .semibold))
                        .foregroundStyle(theme.color(.deep))
                    Spacer()
                    Text("\(doneCount) of \(tier.totalDays) days")
                        .font(ffBody(FFType.sm, weight: .bold))
                        .foregroundStyle(theme.color(.phaseLuteal))
                }
                HStack(spacing: 3) {
                    ForEach(1...tier.totalDays, id: \.self) { d in
                        Capsule()
                            .fill(theme.color(isDone(planDay: d) ? .phaseLuteal : .surface))
                            .frame(height: 6)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: plan switcher — manual both ways, history always kept

    private var planSwitchCard: some View {
        FFCard(variant: .outline) {
            VStack(alignment: .leading, spacing: FFSpace.s2) {
                Text(tier == .starter ? "Loving it?" : "Want a lighter touch?")
                    .font(ffBody(FFType.md, weight: .semibold))
                    .foregroundStyle(theme.color(.deep))
                Text(tier == .starter
                     ? "You're on the 3-day starter. When it's working for you, the full 14-day plan goes deeper — same idea, two weeks of it."
                     : "You're on the full 14-day plan. The 3-day starter keeps just the essentials.")
                    .font(ffBody(FFType.sm))
                    .foregroundStyle(theme.color(.muted))
                    .lineSpacing(2)
                FFButton(tier == .starter ? "Switch to the full 14-day plan" : "Back to the 3-day starter",
                         style: .soft, size: .sm,
                         icon: tier == .starter ? "arrow.up.right" : "arrow.uturn.backward") {
                    store.fullStretchPlan.toggle()
                }
                Text("Switching never erases anything — every stretch you've logged stays.")
                    .font(ffBody(FFType.xs2))
                    .foregroundStyle(theme.color(.muted))
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
            return "Gentle knees-to-chest and child's pose can still ease cramps today. The plan picks back up before your next period — the schedule is below."
        }
        if daysUntil == nil {
            return "Log a couple of cycles and the plan will time itself to the days before your period."
        }
        if let start = date(forPlanDay: 1) {
            return "The \(tier.label.lowercased()) starts around \(start.formatted(.dateTime.month().day())). The schedule is below."
        }
        return "It runs in the days before your period. The schedule is below."
    }

    // MARK: schedule (per-tier, expandable, with done-state)

    private var scheduleCard: some View {
        FFCard {
            VStack(alignment: .leading, spacing: FFSpace.s2) {
                Text(tier == .starter ? "The 3 days" : "The 14 days")
                    .font(ffBody(FFType.md, weight: .semibold)).foregroundStyle(theme.color(.deep))
                VStack(spacing: 0) {
                    ForEach(StretchPlan.days(for: tier)) { day in
                        scheduleRow(day)
                        if day.id != StretchPlan.days(for: tier).last?.id {
                            Rectangle().fill(theme.color(.line)).frame(height: 1)
                        }
                    }
                }
            }
        }
    }

    private func scheduleRow(_ day: StretchDay) -> some View {
        let planDay = StretchPlan.planDay(day, tier: tier)
        let isTodayRow = todaySession?.daysBeforePeriod == day.daysBeforePeriod
        let expanded = expandedDay == planDay
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(FFMotion.fast) { expandedDay = expanded ? nil : planDay }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: isDone(planDay: planDay) ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18))
                        .foregroundStyle(theme.color(isDone(planDay: planDay) ? .good : .line))
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 6) {
                            Text("Day \(planDay)")
                                .font(ffBody(FFType.sm, weight: .bold))
                                .foregroundStyle(theme.color(isTodayRow ? .primaryStrong : .deep))
                            if isTodayRow {
                                Text("today")
                                    .font(ffBody(FFType.xs2, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 7).padding(.vertical, 2)
                                    .background(theme.color(.primaryStrong), in: Capsule())
                            }
                            if let d = date(forPlanDay: planDay) {
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
            .accessibilityLabel("Day \(planDay), \(day.focus), \(day.minutes) minutes")
            .accessibilityHint(expanded ? "Collapses the moves" : "Shows the moves")

            if expanded {
                VStack(alignment: .leading, spacing: FFSpace.s2) {
                    ForEach(day.moves) { m in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: m.icon)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(theme.color(.phaseLuteal))
                                .frame(width: 22)
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
                }
                .padding(.leading, 34)
                .padding(.bottom, FFSpace.s3)
                .transition(.opacity)
            }
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
