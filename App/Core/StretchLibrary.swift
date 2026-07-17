import Foundation

// Cramp-ease stretch plan — a gentle 14-day (luteal-phase) routine timed to the
// two weeks before the period. Content is evidence-based and framed honestly:
// this is preventive wellness guidance, not medical advice or a painkiller.
//
// Evidence (all verified via PubMed):
//  • Cochrane 2019 (Armour, Ee et al., CD004142) — exercise lowered dysmenorrhea
//    pain (~25 mm on a 100 mm scale), though the trials were small/low-certainty.
//  • Rakhshaee 2011 (PMID 21514190) — Cobra, Cat & Fish poses in the luteal phase
//    reduced cramp intensity and duration.
//  • Motahari-Tabari 2017 (PMC5187401) — ~10 min of belly/pelvic stretching worked
//    about as well as mefenamic acid (an NSAID) for cramp pain.
//  • Zheng 2024 network meta-analysis (PMID 39550537) — benefit builds over 4–8 wk.
//  Dosing (30s holds, ~3x/week) follows the flexibility-dose research popularized by
//  David Thurin ("Stay Flexy") — Ingram et al. 2025 Sports Med (PMID 39614059). That
//  study is about flexibility, NOT cramps; the pain relief comes from the trials above.

struct StretchMove: Identifiable {
    let name: String
    let hold: String    // display string, e.g. "20s × 3", "60s flowing"
    let cue: String
    var seconds: Int = 45              // guided-session timer length for this move
    var icon: String = "figure.flexibility"   // SF Symbol visual anchor
    var id: String { name + hold }
}

struct StretchDay: Identifiable {
    let daysBeforePeriod: Int   // 14 (start) … 1 (day before period)
    let focus: String
    let minutes: Int
    let moves: [StretchMove]
    var id: Int { daysBeforePeriod }
    /// 1…14 — how far into the plan this day is.
    var planDay: Int { 15 - daysBeforePeriod }
}

// Two tiers of the same evidence base. Starter (default) is a 3-day plan on the
// three days before the period — the lowest-commitment version that still hits
// the core belly/pelvic work. Full is the complete 14-day luteal routine.
// Switching tiers is presentation only: completions are stored per calendar
// date, so history survives any number of switches, in both directions.
enum StretchTier: String {
    case trio, starter, full
    var totalDays: Int {
        switch self { case .trio: 0; case .starter: 3; case .full: 14 }
    }
    var label: String {
        switch self { case .trio: "Core trio"; case .starter: "3-day starter"; case .full: "Full 14-day" }
    }
    var multiplier: Int {
        switch self { case .trio: 1; case .starter: 2; case .full: 4 }
    }
    /// Lock-in modes charge 5 petals for a missed plan day.
    var locksIn: Bool { self != .trio }
}

enum StretchPlan {
    static let totalDays = 14

    static func days(for tier: StretchTier) -> [StretchDay] {
        tier == .starter ? starterDays : days
    }

    /// The session for a given days-until-period on a tier, or nil if outside
    /// that tier's window.
    static func session(daysUntilPeriod n: Int, tier: StretchTier) -> StretchDay? {
        days(for: tier).first { $0.daysBeforePeriod == n }
    }

    /// 1-based "Day N of the plan" for a session within a tier.
    static func planDay(_ day: StretchDay, tier: StretchTier) -> Int {
        tier.totalDays + 1 - day.daysBeforePeriod
    }

    /// The calendar date for a 1-based plan day. Anchored so the window ends
    /// the day before the predicted period when a prediction exists; otherwise
    /// the window simply STARTS today (the plan starts when she does). Either
    /// way every plan day maps to a real date, so every schedule checkbox is
    /// always live — a nil here is what once left whole plans' checkboxes dead.
    /// Pure and covered by StretchPlanTests; completions are stored per
    /// calendar date, so remapping (e.g. a prediction appearing later) never
    /// loses history.
    static func date(forPlanDay planDay: Int, tier: StretchTier,
                     nextPeriodStart: Date?, today: Date,
                     cal: Calendar = .current) -> Date? {
        let start: Date?
        if let next = nextPeriodStart {
            start = cal.date(byAdding: .day, value: -tier.totalDays, to: next)
        } else {
            start = cal.startOfDay(for: today)
        }
        guard let start else { return nil }
        return cal.date(byAdding: .day, value: planDay - 1, to: start)
    }

    /// The session for a given days-until-period, or nil if outside the window.
    static func session(daysUntilPeriod n: Int) -> StretchDay? {
        days.first { $0.daysBeforePeriod == n }
    }

    // The 3-day starter: the highest-value sessions, compressed. Day 1 is the
    // trial-backed trio, day 2 the belly/pelvic set, day 3 gentle relief.
    static let starterDays: [StretchDay] = [
        StretchDay(daysBeforePeriod: 3, focus: "The core trio", minutes: 10,
                   moves: [catCow, cobra, fish, childs]),
        StretchDay(daysBeforePeriod: 2, focus: "Belly & pelvic", minutes: 8,
                   moves: [pelvicTilts, knees,
                    StretchMove(name: "Standing side stretch", hold: "20s each side",
                                cue: "Reach one arm overhead and lean gently away, both sides.", seconds: 40),
                    childs]),
        StretchDay(daysBeforePeriod: 1, focus: "Gentle relief & breath", minutes: 6,
                   moves: [breathing, knees, childs]),
    ]

    static let summary =
        "A gentle 14-day routine for the two weeks before your period. Across the research, "
        + "low-intensity stretching and yoga can meaningfully ease period cramps, but it's "
        + "preventive, not a quick fix. Benefits build over a few weeks, so give it two cycles."

    static let evidenceNote =
        "Why it may help: a Cochrane review found exercise lowered cramp pain; a 2011 trial of "
        + "Cobra, Cat and Fish poses and a 2017 trial where ~10 minutes of belly-and-pelvic "
        + "stretching worked about as well as an anti-inflammatory both point the same way. "
        + "The evidence is promising but from small studies. Think \u{201C}may help,\u{201D} not a cure."

    static let dosingNote =
        "The 30-second holds and ~3 fuller sessions a week follow the stretching-dose research "
        + "popularized by David Thurin (\u{201C}Stay Flexy\u{201D}): a 2025 meta-analysis on how to "
        + "stretch effectively. That one is about flexibility, not cramps; the cramp relief comes "
        + "from the cycle studies above."

    static let disclaimer =
        "This is wellness guidance, not medical advice. It's for typical period cramps. If your "
        + "pain is new, severe, or different than usual, please see a clinician."

    static let contraindications = [
        "Possibly pregnant? This plan runs when pregnancy is possible, so skip the deep belly stretches (Cobra, Fish) and check with a clinician first.",
        "Stay gentle: only ever a mild sense of stretch, never sharp pain. Breathe slowly, especially on the exhale.",
        "Skip Fish pose with neck problems or blood-pressure concerns; skip Cobra after abdominal or pelvic surgery, a hernia, or significant back pain.",
        "New, severe, or unusual pain (or a known condition your doctor has restricted exercise for) means check first, don't push through.",
    ]

    // Standard cues, reused across days.
    private static let breathing = StretchMove(name: "Diaphragmatic breathing", hold: "5–6 slow breaths",
        cue: "Lie back, one hand on your belly. Breathe into it slowly, with long easy exhales.",
        seconds: 60, icon: "wind")
    private static let pelvicTilts = StretchMove(name: "Pelvic tilts", hold: "10–12 reps",
        cue: "On your back, knees bent. Gently flatten then arch your low back with your breath.",
        seconds: 60, icon: "figure.core.training")
    private static let catCow = StretchMove(name: "Cat-Cow", hold: "45–60s flowing",
        cue: "On all fours, alternate arching and rounding your spine, moving with your breath.",
        seconds: 60, icon: "figure.flexibility")
    private static let childs = StretchMove(name: "Child's pose", hold: "45–60s",
        cue: "Knees wide, sit back toward your heels, forehead down, arms long. Breathe into your back.",
        seconds: 60, icon: "figure.cooldown")
    private static let knees = StretchMove(name: "Knees-to-chest", hold: "30–40s",
        cue: "Hug both knees to your chest and let your low back soften. Rock side to side if it feels good.",
        seconds: 40, icon: "figure.rolling")
    private static let cobra = StretchMove(name: "Cobra (gentle)", hold: "20–25s × 3",
        cue: "Face down, press up low and easy through your arms. Keep it pain-free, shoulders down.",
        seconds: 75, icon: "figure.flexibility")
    private static let fish = StretchMove(name: "Supported Fish", hold: "20–25s × 2",
        cue: "Lie back over a rolled towel under your upper back, chest open. Skip if it strains your neck.",
        seconds: 50, icon: "figure.flexibility")
    private static let restfulBreath = StretchMove(name: "Constructive rest", hold: "2 min",
        cue: "Lie down, knees bent, feet wide, and just breathe. Let your belly and hips go heavy.",
        seconds: 120, icon: "wind")

    static let days: [StretchDay] = [
        StretchDay(daysBeforePeriod: 14, focus: "Foundations & breath", minutes: 8,
                   moves: [breathing, pelvicTilts, catCow, childs]),
        StretchDay(daysBeforePeriod: 13, focus: "Light mobility", minutes: 5,
                   moves: [catCow, knees, childs]),
        StretchDay(daysBeforePeriod: 12, focus: "Core session: the luteal trio", minutes: 12,
                   moves: [catCow, cobra, fish, pelvicTilts, childs]),
        StretchDay(daysBeforePeriod: 11, focus: "Light: hips & low back", minutes: 6,
                   moves: [
                    StretchMove(name: "Butterfly / adductor", hold: "40s", cue: "Sit, soles together, let your knees ease down. Hinge gently forward from the hips."),
                    StretchMove(name: "Supine figure-4", hold: "30s each side", cue: "On your back, ankle over the opposite knee, draw the thigh toward you.", seconds: 60),
                    knees]),
        StretchDay(daysBeforePeriod: 10, focus: "Core session: belly & pelvic", minutes: 13,
                   moves: [
                    StretchMove(name: "Standing warm-up", hold: "2–3 min", cue: "March in place and reach side to side to warm up.", seconds: 150, icon: "figure.walk"),
                    StretchMove(name: "Standing side stretch", hold: "20s each side", cue: "Reach one arm overhead and lean gently away.", seconds: 40),
                    pelvicTilts, knees, childs]),
        StretchDay(daysBeforePeriod: 9, focus: "Restorative & breath", minutes: 5,
                   moves: [childs, restfulBreath]),
        StretchDay(daysBeforePeriod: 8, focus: "Core session: full routine", minutes: 14,
                   moves: [catCow, cobra, fish,
                    StretchMove(name: "Standing side stretch", hold: "20s each side", cue: "Reach overhead and lean gently away, both sides.", seconds: 40),
                    pelvicTilts, childs]),
        StretchDay(daysBeforePeriod: 7, focus: "Light: hamstrings & low back", minutes: 7,
                   moves: [
                    StretchMove(name: "Supine hamstring stretch", hold: "30s each side", cue: "On your back, raise one leg, hold behind the thigh or use a strap.", seconds: 60),
                    knees, childs]),
        StretchDay(daysBeforePeriod: 6, focus: "Core session: Cobra/Cat/Fish", minutes: 12,
                   moves: [catCow, cobra, fish, childs]),
        StretchDay(daysBeforePeriod: 5, focus: "Restorative: gentle twists", minutes: 6,
                   moves: [catCow,
                    StretchMove(name: "Supine gentle twist", hold: "30s each side", cue: "On your back, drop bent knees to one side, gaze the other way.", seconds: 60, icon: "figure.cooldown"),
                    childs]),
        StretchDay(daysBeforePeriod: 4, focus: "Core session: gentler", minutes: 11,
                   moves: [
                    StretchMove(name: "Standing warm-up", hold: "2 min", cue: "March and reach to warm up.", seconds: 120, icon: "figure.walk"),
                    StretchMove(name: "Standing side stretch", hold: "20s each side", cue: "Reach overhead, lean gently.", seconds: 40),
                    pelvicTilts, knees, childs]),
        StretchDay(daysBeforePeriod: 3, focus: "Gentle relief", minutes: 6,
                   moves: [catCow, knees, childs]),
        StretchDay(daysBeforePeriod: 2, focus: "Gentle relief & breath", minutes: 6,
                   moves: [restfulBreath, knees, childs]),
        StretchDay(daysBeforePeriod: 1, focus: "Very gentle, optional", minutes: 5,
                   moves: [breathing, knees, childs]),
    ]
}
