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
    let hold: String    // e.g. "20s × 3", "60s flowing"
    let cue: String
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

enum StretchPlan {
    static let totalDays = 14

    /// The session for a given days-until-period, or nil if outside the window.
    static func session(daysUntilPeriod n: Int) -> StretchDay? {
        days.first { $0.daysBeforePeriod == n }
    }

    static let summary =
        "A gentle 14-day routine for the two weeks before your period. Across the research, "
        + "low-intensity stretching and yoga can meaningfully ease period cramps — but it's "
        + "preventive, not a quick fix. Benefits build over a few weeks, so give it two cycles."

    static let evidenceNote =
        "Why it may help: a Cochrane review found exercise lowered cramp pain; a 2011 trial of "
        + "Cobra, Cat and Fish poses and a 2017 trial where ~10 minutes of belly-and-pelvic "
        + "stretching worked about as well as an anti-inflammatory both point the same way. "
        + "The evidence is promising but from small studies — think \u{201C}may help,\u{201D} not a cure."

    static let dosingNote =
        "The 30-second holds and ~3 fuller sessions a week follow the stretching-dose research "
        + "popularized by David Thurin (\u{201C}Stay Flexy\u{201D}) — a 2025 meta-analysis on how to "
        + "stretch effectively. That one is about flexibility, not cramps; the cramp relief comes "
        + "from the cycle studies above."

    static let disclaimer =
        "This is wellness guidance, not medical advice. It's for typical period cramps — if your "
        + "pain is new, severe, or different than usual, please see a clinician."

    static let contraindications = [
        "Possibly pregnant? This plan runs when pregnancy is possible — skip the deep belly stretches (Cobra, Fish) and check with a clinician first.",
        "Stay gentle: only ever a mild sense of stretch, never sharp pain. Breathe slowly, especially on the exhale.",
        "Skip Fish pose with neck problems or blood-pressure concerns; skip Cobra after abdominal or pelvic surgery, a hernia, or significant back pain.",
        "New, severe, or unusual pain — or a known condition your doctor has restricted exercise for — means check first, don't push through.",
    ]

    // Standard cues, reused across days.
    private static let breathing = StretchMove(name: "Diaphragmatic breathing", hold: "5–6 slow breaths",
        cue: "Lie back, one hand on your belly. Breathe into it slowly, with long easy exhales.")
    private static let pelvicTilts = StretchMove(name: "Pelvic tilts", hold: "10–12 reps",
        cue: "On your back, knees bent. Gently flatten then arch your low back with your breath.")
    private static let catCow = StretchMove(name: "Cat-Cow", hold: "45–60s flowing",
        cue: "On all fours, alternate arching and rounding your spine, moving with your breath.")
    private static let childs = StretchMove(name: "Child's pose", hold: "45–60s",
        cue: "Knees wide, sit back toward your heels, forehead down, arms long. Breathe into your back.")
    private static let knees = StretchMove(name: "Knees-to-chest", hold: "30–40s",
        cue: "Hug both knees to your chest and let your low back soften. Rock side to side if it feels good.")
    private static let cobra = StretchMove(name: "Cobra (gentle)", hold: "20–25s × 3",
        cue: "Face down, press up low and easy through your arms. Keep it pain-free — shoulders down.")
    private static let fish = StretchMove(name: "Supported Fish", hold: "20–25s × 2",
        cue: "Lie back over a rolled towel under your upper back, chest open. Skip if it strains your neck.")
    private static let restfulBreath = StretchMove(name: "Constructive rest", hold: "2 min",
        cue: "Lie down, knees bent, feet wide, and just breathe. Let your belly and hips go heavy.")

    static let days: [StretchDay] = [
        StretchDay(daysBeforePeriod: 14, focus: "Foundations & breath", minutes: 8,
                   moves: [breathing, pelvicTilts, catCow, childs]),
        StretchDay(daysBeforePeriod: 13, focus: "Light mobility", minutes: 5,
                   moves: [catCow, knees, childs]),
        StretchDay(daysBeforePeriod: 12, focus: "Core session — the luteal trio", minutes: 12,
                   moves: [catCow, cobra, fish, pelvicTilts, childs]),
        StretchDay(daysBeforePeriod: 11, focus: "Light — hips & low back", minutes: 6,
                   moves: [
                    StretchMove(name: "Butterfly / adductor", hold: "40s", cue: "Sit, soles together, let your knees ease down. Hinge gently forward from the hips."),
                    StretchMove(name: "Supine figure-4", hold: "30s each side", cue: "On your back, ankle over the opposite knee, draw the thigh toward you."),
                    knees]),
        StretchDay(daysBeforePeriod: 10, focus: "Core session — belly & pelvic", minutes: 13,
                   moves: [
                    StretchMove(name: "Standing warm-up", hold: "2–3 min", cue: "March in place and reach side to side to warm up."),
                    StretchMove(name: "Standing side stretch", hold: "20s each side", cue: "Reach one arm overhead and lean gently away."),
                    pelvicTilts, knees, childs]),
        StretchDay(daysBeforePeriod: 9, focus: "Restorative & breath", minutes: 5,
                   moves: [childs, restfulBreath]),
        StretchDay(daysBeforePeriod: 8, focus: "Core session — full routine", minutes: 14,
                   moves: [catCow, cobra, fish,
                    StretchMove(name: "Standing side stretch", hold: "20s each side", cue: "Reach overhead and lean gently away, both sides."),
                    pelvicTilts, childs]),
        StretchDay(daysBeforePeriod: 7, focus: "Light — hamstrings & low back", minutes: 7,
                   moves: [
                    StretchMove(name: "Supine hamstring stretch", hold: "30s each side", cue: "On your back, raise one leg, hold behind the thigh or use a strap."),
                    knees, childs]),
        StretchDay(daysBeforePeriod: 6, focus: "Core session — Cobra/Cat/Fish", minutes: 12,
                   moves: [catCow, cobra, fish, childs]),
        StretchDay(daysBeforePeriod: 5, focus: "Restorative — gentle twists", minutes: 6,
                   moves: [catCow,
                    StretchMove(name: "Supine gentle twist", hold: "30s each side", cue: "On your back, drop bent knees to one side, gaze the other way."),
                    childs]),
        StretchDay(daysBeforePeriod: 4, focus: "Core session — gentler", minutes: 11,
                   moves: [
                    StretchMove(name: "Standing warm-up", hold: "2 min", cue: "March and reach to warm up."),
                    StretchMove(name: "Standing side stretch", hold: "20s each side", cue: "Reach overhead, lean gently."),
                    pelvicTilts, knees, childs]),
        StretchDay(daysBeforePeriod: 3, focus: "Gentle relief", minutes: 6,
                   moves: [catCow, knees, childs]),
        StretchDay(daysBeforePeriod: 2, focus: "Gentle relief & breath", minutes: 6,
                   moves: [restfulBreath, knees, childs]),
        StretchDay(daysBeforePeriod: 1, focus: "Very gentle — optional", minutes: 5,
                   moves: [breathing, knees, childs]),
    ]
}
