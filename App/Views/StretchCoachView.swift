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
    @State private var showShare = false
    @State private var showTutorial = false
    @State private var celebrationToken = 0
    @State private var lastAward = 0
    @State private var penaltyCharged = 0
    @State private var planExpanded = false
    @State private var burstToken = 0
    @State private var dayBurstToken = 0
    @State private var expandedDay: Int? = nil

    private var today: Date { Date() }
    private var p: CyclePrediction { store.prediction() }
    private var tier: StretchTier { StretchTier(rawValue: store.stretchTierRaw) ?? .starter }
    private var daysUntil: Int? { p.daysUntilNextPeriod }
    private var todaySession: StretchDay? {
        if tier == .trio { return anytimeSession }   // the trio is every day's session
        guard let d = daysUntil, d >= 1, d <= tier.totalDays else { return nil }
        return StretchPlan.session(daysUntilPeriod: d, tier: tier)
    }
    /// Off-schedule fallback so checking off stretches is always available.
    private var anytimeSession: StretchDay { StretchPlan.starterDays[0] }
    private var activeSession: StretchDay { todaySession ?? anytimeSession }
    /// Points multiplier: anytime x1, 3-day starter x2, full 14-day x4.
    private var multiplier: Int { (tier == .trio || todaySession == nil) ? 1 : tier.multiplier }

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
                planBar
                CoachFlower(message: coachLine, celebrateToken: celebrationToken, lastAward: lastAward)
                SampleBanner()
                if let s = todaySession {
                    todayCard(s, heading: tier == .trio
                        ? "TODAY · THE CORE TRIO"
                        : "TODAY · DAY \(StretchPlan.planDay(s, tier: tier)) OF \(tier.totalDays)")
                    if tier != .trio { progressStrip }
                    if penaltyCharged > 0 { penaltyNote }
                } else {
                    outOfWindowCard
                    // Stretching is never locked: any day, she can run and check
                    // off a session — it logs to today like any other.
                    todayCard(anytimeSession, heading: "ANYTIME SESSION · NO SCHEDULE NEEDED")
                }
                if tier != .trio { scheduleCard }
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
        .sheet(isPresented: $showShare) { ShareCardView() }
        .sheet(isPresented: $showTutorial) {
            StretchTutorialView(onClaim: { showShop = true })
        }
        .onAppear {
            if !rewards.tutorialSeen { showTutorial = true }
            applyLockInPenalties()
        }
    }

    /// Lock-in accounting: past plan days in this window she didn't stretch cost
    /// 5 petals each, charged once ever per day. Trio never penalizes.
    private func applyLockInPenalties() {
        guard tier.locksIn, tier.totalDays > 0 else { return }
        let startOfToday = Calendar.current.startOfDay(for: today)
        var charged = 0
        for d in 1...tier.totalDays {
            guard let date = date(forPlanDay: d), date < startOfToday else { continue }
            if !store.stretchDone(on: date),
               rewards.penalizeMissedDay(store.key(for: date)) {
                charged += 1
            }
        }
        penaltyCharged = charged
    }

    private var penaltyNote: some View {
        Text("\(penaltyCharged * 5) petals drifted off for missed days — today's a fresh bloom.")
            .font(ffBody(FFType.xs))
            .foregroundStyle(theme.color(.muted))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // Her plan, right at the top: collapsed it names the current mode; tapping
    // expands the three previews; picking one selects it and folds back up.
    private var planBar: some View {
        VStack(alignment: .leading, spacing: FFSpace.s2) {
            Button {
                withAnimation(FFMotion.fast) { planExpanded.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Text("PLAN")
                        .font(ffBody(FFType.xs2, weight: .bold)).tracking(0.8)
                        .foregroundStyle(theme.color(.muted))
                    Text(tier.label)
                        .font(ffBody(FFType.sm, weight: .bold))
                        .foregroundStyle(theme.color(.deep))
                    Text("×\(tier.multiplier)")
                        .font(ffBody(FFType.xs2, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6).padding(.vertical, 1)
                        .background(theme.color(.phaseLuteal), in: Capsule())
                    Spacer(minLength: 4)
                    Text("up to \(maxDailyPoints(tier))/day")
                        .font(ffBody(FFType.xs, weight: .bold))
                        .foregroundStyle(theme.color(.deep))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(theme.color(.muted))
                        .rotationEffect(.degrees(planExpanded ? 180 : 0))
                }
                .padding(.horizontal, 14).padding(.vertical, 11)
                .background(theme.color(.surface), in: RoundedRectangle(cornerRadius: FFRadius.md, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: FFRadius.md, style: .continuous)
                    .strokeBorder(theme.color(.line), lineWidth: 1))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Current plan: \(tier.label)")
            .accessibilityHint(planExpanded ? "Collapses the plan choices" : "Shows the plan choices")

            if planExpanded {
                modeRow(.trio,    note: "Any day, no schedule, no pressure")
                modeRow(.starter, note: "The 3 days before your period · −5 a missed day")
                modeRow(.full,    note: "The full two weeks · −5 a missed day")
                Text("Switching keeps every point and completion.")
                    .font(ffBody(FFType.xs2))
                    .foregroundStyle(theme.color(.muted))
            }
        }
    }

    private func modeRow(_ t: StretchTier, note: String) -> some View {
        let selected = tier == t
        return Button {
            withAnimation(FFMotion.fast) {
                store.stretchTierRaw = t.rawValue
                planExpanded = false
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 17))
                    .foregroundStyle(theme.color(selected ? .primaryStrong : .line))
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text(t.label)
                            .font(ffBody(FFType.sm, weight: .bold))
                            .foregroundStyle(theme.color(.deep))
                        Text("×\(t.multiplier)")
                            .font(ffBody(FFType.xs2, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6).padding(.vertical, 1)
                            .background(theme.color(.phaseLuteal), in: Capsule())
                    }
                    Text(note)
                        .font(ffBody(FFType.xs))
                        .foregroundStyle(theme.color(.muted))
                }
                Spacer(minLength: 4)
                Text("up to \(maxDailyPoints(t))/day")
                    .font(ffBody(FFType.xs, weight: .bold))
                    .foregroundStyle(theme.color(.deep))
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(theme.color(selected ? .surfaceSoft : .surface),
                        in: RoundedRectangle(cornerRadius: FFRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: FFRadius.md, style: .continuous)
                    .strokeBorder(selected ? theme.color(.primaryStrong) : theme.color(.line),
                                  lineWidth: selected ? 1.5 : 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(t.label), \(note), up to \(maxDailyPoints(t)) points a day")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    /// Best day's pose points on a tier: 15·m + 5·(m−1) + 10, times the multiplier.
    private func maxDailyPoints(_ t: StretchTier) -> Int {
        let sessions = t == .trio ? [anytimeSession] : StretchPlan.days(for: t)
        let m = sessions.map { $0.moves.count }.max() ?? 0
        return (20 * m + 5) * t.multiplier
    }

    // Points pill + the shop, with the RULES in the top-right corner.
    private var gardenHeader: some View {
        HStack(spacing: FFSpace.s2) {
            PointsPill(action: { showShop = true })
            Spacer(minLength: 0)
            FFIconButton("bag") { showShop = true }
                .accessibilityLabel("Garden shop")
            FFIconButton("square.and.arrow.up") { showShare = true }
                .accessibilityLabel("Share your garden")
            FFIconButton("book") { showRules = true }
                .accessibilityLabel("How points and unlocks work")
        }
    }

    private var sessionFinishTitle: String {
        if tier != .trio, let s = todaySession {
            return "Day \(StretchPlan.planDay(s, tier: tier)) done"
        }
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
                lastAward = rewards.awardPose(alreadyDone: doneBefore, total: session.moves.count,
                                              multiplier: multiplier)
                burstToken += 1                      // checking ON celebrates
                celebrationToken += 1                // Posey gets watered
            } else {
                rewards.revokePose(remainingDone: max(doneBefore - 1, 0),
                                   total: session.moves.count,
                                   wasFullDay: wasFullDay, multiplier: multiplier)
            }
            if completedDay {
                dayBurstToken += 1                   // finishing the set celebrates louder
                rewards.playCelebrationIfOwned()
            }
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: checked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(theme.color(checked ? .good : .line))
                    .padding(.top, 1)
                PoseFigure(move: m, size: 24, color: theme.color(.phaseLuteal))
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
            HStack(spacing: 10) {
                dayCheckbox(planDay: planDay)
                Button {
                    withAnimation(FFMotion.fast) { expandedDay = expanded ? nil : planDay }
                } label: {
                HStack(spacing: 10) {
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
                .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Day \(planDay), \(day.focus), \(day.minutes) minutes")
                .accessibilityHint(expanded ? "Collapses the moves" : "Shows the moves")
            }
            .padding(.vertical, 9)

            if expanded, isTodayRow {
                // Today's moves are the real thing — check them off right here.
                VStack(alignment: .leading, spacing: FFSpace.s2) {
                    ForEach(Array(day.moves.enumerated()), id: \.element.id) { i, m in
                        moveCheckRow(m, index: i,
                                     checked: store.stretchMovesDone(on: today).contains(i),
                                     session: day)
                    }
                }
                .padding(.leading, 34)
                .padding(.bottom, FFSpace.s3)
                .transition(.opacity)
            } else if expanded {
                VStack(alignment: .leading, spacing: FFSpace.s2) {
                    ForEach(day.moves) { m in
                        HStack(alignment: .top, spacing: 10) {
                            PoseFigure(move: m, size: 24, color: theme.color(.phaseLuteal))
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

    // The day's own checkbox — tappable for today and past plan days; future
    // days wait their turn. Completing rings her chime and bursts.
    private func dayCheckbox(planDay: Int) -> some View {
        let done = isDone(planDay: planDay)
        let dayDate = date(forPlanDay: planDay)
        let tappable = dayDate.map { $0 <= today } ?? false
        return Button {
            guard let d = dayDate else { return }
            let finishing = !store.stretchDone(on: d)
            store.setStretchDone(finishing, on: d)
            if finishing {
                dayBurstToken += 1
                rewards.playCelebrationIfOwned()
            }
        } label: {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20))
                .foregroundStyle(theme.color(done ? .good : (tappable ? .muted : .line)))
                .frame(width: FFSpace.tapMin - 14, height: FFSpace.tapMin - 4)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!tappable)
        .accessibilityLabel(done ? "Day \(planDay) done" : "Mark day \(planDay) done")
        .accessibilityAddTraits(done ? .isSelected : [])
    }

    // MARK: evidence + safety

    private var evidenceCard: some View {
        FFCard {
            DisclosureGroup {
                evidenceBody.padding(.top, FFSpace.s2)
            } label: {
                Text("Why this may help")
                    .font(ffBody(FFType.md, weight: .semibold)).foregroundStyle(theme.color(.deep))
            }
            .tint(theme.color(.primaryStrong))
        }
    }

    private var evidenceBody: some View {
        VStack(alignment: .leading, spacing: 8) {
                Text(StretchPlan.evidenceNote)
                    .font(ffBody(FFType.sm)).foregroundStyle(theme.color(.text)).lineSpacing(3)
                Text(StretchPlan.dosingNote)
                    .font(ffBody(FFType.xs)).foregroundStyle(theme.color(.muted)).lineSpacing(2)
                Text(StretchPlan.disclaimer)
                    .font(ffBody(FFType.xs, weight: .medium)).foregroundStyle(theme.color(.muted)).lineSpacing(2)
        }
    }

    private var safetyCard: some View {
        FFCard(variant: .outline) {
            DisclosureGroup {
                safetyBody.padding(.top, FFSpace.s2)
            } label: {
                Label("Before you start", systemImage: "exclamationmark.circle")
                    .font(ffBody(FFType.md, weight: .semibold)).foregroundStyle(theme.color(.deep))
            }
            .tint(theme.color(.primaryStrong))
        }
    }

    private var safetyBody: some View {
        VStack(alignment: .leading, spacing: 8) {
                ForEach(StretchPlan.contraindications, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Circle().fill(theme.color(.primary)).frame(width: 5, height: 5).padding(.top, 6)
                        Text(item).font(ffBody(FFType.sm)).foregroundStyle(theme.color(.text)).lineSpacing(2)
                    }
                }
        }
    }
}
