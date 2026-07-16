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
    @State private var burstToken = 0
    @State private var dayBurstToken = 0
    @State private var expandedDay: Int? = nil
    @State private var playingDay: StretchDay? = nil   // any schedule day, guided
    /// Life happens: while paused, missed plan days are excused, never charged.
    @AppStorage("flowtear.planPaused") private var planPaused = false
    /// When the current lock-in plan was (re)chosen, as a startOfDay timestamp.
    /// Penalties never reach behind this line — so switching tiers, the first
    /// prediction remapping the window into the past, or toggling tiers while
    /// paused can never retroactively bill days the plan wasn't active for.
    /// ("Switching keeps every point and completion" has to be TRUE.)
    @AppStorage("flowtear.planActivatedAt") private var planActivatedAt: Double = 0

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
        StretchPlan.date(forPlanDay: planDay, tier: tier,
                         nextPeriodStart: p.nextPeriodStart, today: today)
    }
    private func isDone(planDay: Int) -> Bool {
        guard let d = date(forPlanDay: planDay) else { return false }
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
        // Any day of the plan can be run guided, right from the schedule list.
        .fullScreenCover(item: $playingDay) { day in
            StretchSessionView(day: day,
                               finishTitle: day.daysBeforePeriod == todaySession?.daysBeforePeriod
                                   ? sessionFinishTitle : "Session done",
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
            // First time this screen ever runs the accounting, anchor the plan
            // to today — nothing before "she started" is ever chargeable.
            if planActivatedAt == 0 {
                planActivatedAt = Calendar.current.startOfDay(for: today).timeIntervalSinceReferenceDate
            }
            applyLockInPenalties()
        }
        // Pausing grants amnesty immediately; UNpausing forgives everything
        // missed up to that moment first (days that elapsed while paused must
        // never be billed), then normal accounting resumes.
        .onChange(of: planPaused) { wasPaused, isPaused in
            if wasPaused && !isPaused { excusePauseWindow() }
            applyLockInPenalties()
        }
    }

    /// Amnesty at unpause: every past, un-done plan day is excused for good —
    /// the plan only charges for days missed AFTER the pause lifts.
    private func excusePauseWindow() {
        guard tier.locksIn, tier.totalDays > 0 else { return }
        let startOfToday = Calendar.current.startOfDay(for: today)
        for d in 1...tier.totalDays {
            guard let date = date(forPlanDay: d), date < startOfToday else { continue }
            if !store.stretchDone(on: date) {
                rewards.excuseMissedDay(store.key(for: date))
            }
        }
    }

    /// Lock-in accounting: past plan days in this window she didn't stretch cost
    /// 5 petals each, charged once ever per day. Trio never penalizes; while the
    /// plan is PAUSED those days are excused for good instead of charged; days
    /// before the plan was activated are never chargeable at all.
    private func applyLockInPenalties() {
        guard tier.locksIn, tier.totalDays > 0 else { return }
        let startOfToday = Calendar.current.startOfDay(for: today)
        let activation = Date(timeIntervalSinceReferenceDate: planActivatedAt)
        var charged = 0
        for d in 1...tier.totalDays {
            guard let date = date(forPlanDay: d), date < startOfToday else { continue }
            guard !store.stretchDone(on: date) else { continue }
            if planPaused || date < activation {
                rewards.excuseMissedDay(store.key(for: date))
            } else if rewards.penalizeMissedDay(store.key(for: date)) {
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

    // Her plan, right at the top — all three choices visible all the time, one
    // tap to switch (no hidden menus to discover). The segments carry the name
    // and points multiplier; the line beneath explains the one she's on.
    private var planBar: some View {
        VStack(alignment: .leading, spacing: FFSpace.s2) {
            HStack {
                Text("YOUR PLAN")
                    .font(ffBody(FFType.xs2, weight: .bold)).tracking(0.8)
                    .foregroundStyle(theme.color(.muted))
                Spacer()
                if planPaused && tier.locksIn {
                    Text("paused")
                        .font(ffBody(FFType.xs2, weight: .bold))
                        .foregroundStyle(theme.color(.deep))
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(theme.color(.surfaceSoft), in: Capsule())
                }
            }

            HStack(spacing: 4) {
                planSegment(.trio,    name: "Anytime")
                planSegment(.starter, name: "3-day")
                planSegment(.full,    name: "14-day")
            }
            .padding(4)
            .background(theme.color(.surfaceSoft),
                        in: RoundedRectangle(cornerRadius: FFRadius.md, style: .continuous))

            HStack(alignment: .firstTextBaseline) {
                Text(planNote(tier))
                    .font(ffBody(FFType.xs))
                    .foregroundStyle(theme.color(.muted))
                Spacer(minLength: 8)
                Text("up to \(maxDailyPoints(tier))/day")
                    .font(ffBody(FFType.xs, weight: .bold))
                    .foregroundStyle(theme.color(.deep))
                    .layoutPriority(1)
            }

            if tier.locksIn {
                pauseRow
            }
            Text("Switching keeps every point and completion.")
                .font(ffBody(FFType.xs2))
                .foregroundStyle(theme.color(.muted))
        }
    }

    private func planNote(_ t: StretchTier) -> String {
        switch t {
        case .trio:    "Any day, no schedule, no pressure"
        case .starter: "The 3 days before your period · −5 a missed day"
        case .full:    "The full two weeks · −5 a missed day"
        }
    }

    private func planSegment(_ t: StretchTier, name: String) -> some View {
        let selected = tier == t
        return Button {
            guard t != tier else { return }
            // Re-anchor the accounting: a freshly chosen plan starts today, so
            // its window days in the past can never be billed retroactively.
            planActivatedAt = Calendar.current.startOfDay(for: today).timeIntervalSinceReferenceDate
            withAnimation(FFMotion.fast) { store.stretchTierRaw = t.rawValue }
        } label: {
            VStack(spacing: 1) {
                Text(name)
                    .font(ffBody(FFType.sm, weight: .bold))
                    .foregroundStyle(selected ? theme.color(.onPrimary) : theme.color(.text))
                    .lineLimit(1).minimumScaleFactor(0.85)
                Text("×\(t.multiplier) petals")
                    .font(ffBody(FFType.xs2, weight: .semibold))
                    .foregroundStyle(selected ? theme.color(.onPrimary) : theme.color(.muted))
                    .lineLimit(1).minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(
                selected ? theme.color(.primaryStrong) : .clear,
                in: RoundedRectangle(cornerRadius: FFRadius.sm, style: .continuous)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(planA11yLabel(t))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    /// Plain-prose plan description — no midpoints or minus glyphs for VoiceOver.
    private func planA11yLabel(_ t: StretchTier) -> String {
        let how = switch t {
        case .trio:    "any day, no schedule, no pressure"
        case .starter: "the 3 days before your period, 5 petals lost per missed day"
        case .full:    "the full two weeks before your period, 5 petals lost per missed day"
        }
        return "\(t.label), \(how), up to \(maxDailyPoints(t)) points a day"
    }

    // Her plan, her terms: pausing excuses missed days instead of charging them.
    private var pauseRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "pause.circle")
                .font(.system(size: 17))
                .foregroundStyle(theme.color(planPaused ? .primaryStrong : .muted))
            VStack(alignment: .leading, spacing: 1) {
                Text("Pause my plan")
                    .font(ffBody(FFType.sm, weight: .bold))
                    .foregroundStyle(theme.color(.deep))
                Text("Life happens — missed days cost nothing while paused")
                    .font(ffBody(FFType.xs))
                    .foregroundStyle(theme.color(.muted))
            }
            Spacer(minLength: 4)
            FFSwitch(isOn: $planPaused)
                .accessibilityLabel("Pause my plan")
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(theme.color(.surface), in: RoundedRectangle(cornerRadius: FFRadius.md, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: FFRadius.md, style: .continuous)
            .strokeBorder(theme.color(.line), lineWidth: 1))
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
                .glitterHint("gardenShop")
                .accessibilityLabel("Garden shop")
            FFIconButton("square.and.arrow.up") { showShare = true }
                .accessibilityLabel("Share your garden")
            FFIconButton("book") { showRules = true }
                .glitterHint("rules")
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
                lastAward = rewards.awardPose(dateKey: store.key(for: today),
                                              alreadyDone: doneBefore, total: session.moves.count,
                                              multiplier: multiplier)
                burstToken += 1                      // checking ON celebrates
                celebrationToken += 1                // Posey gets watered
            } else {
                rewards.revokePose(dateKey: store.key(for: today),
                                   remainingDone: max(doneBefore - 1, 0),
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
        // VoiceOver gets the hold time with the name; the coaching cue rides
        // as the (skippable) hint, so nothing sighted users see is lost.
        .accessibilityLabel("\(m.name), \(m.hold)")
        .accessibilityHint(m.cue)
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
                Text("Tap a day for its moves, run any session guided, and check off any day — even ahead of schedule.")
                    .font(ffBody(FFType.xs))
                    .foregroundStyle(theme.color(.muted))
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

    /// The full spoken row: VoiceOver hears the date and today-badge state the
    /// eyes get from the chips, so back-filling checkboxes stays navigable.
    private func scheduleRowLabel(planDay: Int, day: StretchDay, isTodayRow: Bool) -> String {
        var label = "Day \(planDay)"
        if isTodayRow { label += ", today" }
        if let d = date(forPlanDay: planDay) {
            label += ", \(d.formatted(.dateTime.month(.wide).day()))"
        }
        return label + ", \(day.focus), \(day.minutes) minutes"
    }

    private func scheduleRow(_ day: StretchDay) -> some View {
        let planDay = StretchPlan.planDay(day, tier: tier)
        // Today is decided by the DATE the row writes to, so the badge also
        // appears in the no-prediction fallback window (day 1 = today).
        let isTodayRow = date(forPlanDay: planDay).map { Calendar.current.isDateInToday($0) } ?? false
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
                                    .foregroundStyle(theme.color(.onPrimary))
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
                .frame(minHeight: FFSpace.tapMin)
                .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(scheduleRowLabel(planDay: planDay, day: day, isTodayRow: isTodayRow))
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
                    FFButton("Start guided session", style: .soft, size: .sm, icon: "play.fill") {
                        playingDay = day
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
                    // Off-schedule days still open the guided player — the whole
                    // system is hers to explore; completions log to today.
                    FFButton("Do this session now", style: .soft, size: .sm, icon: "play.fill") {
                        playingDay = day
                    }
                }
                .padding(.leading, 34)
                .padding(.bottom, FFSpace.s3)
                .transition(.opacity)
            }
        }
    }

    // The day's own checkbox — EVERY day is tappable: past days back-fill,
    // today counts, and future days can be done early (her plan, her pace).
    // Completing rings her chime and bursts.
    private func dayCheckbox(planDay: Int) -> some View {
        let done = isDone(planDay: planDay)
        return Button {
            guard let d = date(forPlanDay: planDay) else { return }
            let finishing = !store.stretchDone(on: d)
            store.setStretchDone(finishing, on: d)
            if finishing {
                dayBurstToken += 1
                rewards.playCelebrationIfOwned()
            }
        } label: {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20))
                .foregroundStyle(theme.color(done ? .good : .muted))
                // Full 44pt hit target — the glyph stays 20pt, only the
                // touchable area grows (and pulls clear of the expand button).
                .frame(width: FFSpace.tapMin, height: FFSpace.tapMin)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
                // The readable short report first, then the specific citations.
                Text(PhaseResearch.stretching.body)
                    .font(ffBody(FFType.sm)).foregroundStyle(theme.color(.text)).lineSpacing(3)
                Text(StretchPlan.evidenceNote)
                    .font(ffBody(FFType.xs)).foregroundStyle(theme.color(.muted)).lineSpacing(2)
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
