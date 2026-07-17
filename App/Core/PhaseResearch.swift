import Foundation

// PhaseResearch — a short, research-grounded report for each experience the
// cycle brings, written warm and plain. Every report was drafted against the
// published evidence (systematic reviews, RCTs, physiology references) and
// then adversarially reviewed for over-claiming, medical-advice framing, and
// tone before landing here. Population claims stay hedged; nothing diagnoses;
// fertility info is never framed as contraception (see the product guardrails).
struct PhaseReport {
    let title: String
    let body: String
    let tips: [String]
    let evidenceNote: String
}

enum PhaseResearch {
    /// The report for a cycle position. The last week before the period gets
    /// its own premenstrual report — that experience is distinct from the
    /// early-luteal calm, and it's the one she's most likely to look up.
    static func report(for phase: CyclePhase, day: Int, cycleLength: Int) -> PhaseReport {
        switch phase {
        case .menstrual:           return menstrual
        case .follicular:          return follicular
        case .fertile, .ovulation: return ovulation
        case .luteal:              return day > cycleLength - 7 ? premenstrual : luteal
        }
    }

    static let menstrual = PhaseReport(
        title: "Your body in these first days",
        body: "These first days, your estrogen and progesterone sit at their lowest, and your uterus releases prostaglandins, the compounds that help it contract and shed its lining. Those same prostaglandins are why cramps, fatigue, and a heavier need for sleep often show up now; for most people, this is simply part of how a cycle works. Many people find real comfort in a heating pad. Systematic reviews suggest continuous low-level heat can meaningfully ease cramps. Gentle movement seems to help too: studies of stretching, yoga, and light aerobic activity point toward less menstrual pain over time. Since you lose a little iron with your flow, iron-rich foods and steady hydration may help you feel steadier. If over-the-counter anti-inflammatories are part of your routine, many people find they work best taken early rather than after pain peaks. A pharmacist or clinician can help you decide what's right for you. And if cramps regularly overwhelm these comforts, that's worth bringing to a clinician; ongoing severe pain deserves care, not just coping.",
        tips: ["Try a heating pad: steady low heat is well studied for cramps.",
               "Move gently: stretching, yoga, or a short walk.",
               "Eat iron-rich foods and sip water steadily.",
               "Pain relievers tend to work best taken early. Ask your pharmacist."],
        evidenceNote: "Based on systematic reviews of heat therapy, stretching, and exercise for menstrual pain, plus well-established cycle physiology."
    )

    static let follicular = PhaseReport(
        title: "Your rising-energy week",
        body: "Now that your period has wound down, your estrogen is steadily rising, and many people feel the shift. Energy often climbs, mood tends to steady, and some notice clearer skin as this phase unfolds. Rising estrogen also nudges up serotonin, which may be part of why motivation and mental clarity can feel easier to reach right now. This is a common window for planning-heavy or focus-demanding tasks to feel more doable, so it can be a nice time to start something new. Some research suggests strength and training gains respond especially well in this phase, though the findings are genuinely mixed and vary a lot from person to person, so treat it as a gentle nudge toward movement you enjoy rather than a rule. Every cycle is a little different, so the most useful thing is to notice what is actually true for your own body this week and lean into the momentum when it is there.",
        tips: ["Front-load planning, launches, and big decisions this week.",
               "Lean into strength or higher-intensity workouts you enjoy.",
               "Ride the energy, but rest whenever your body asks.",
               "Track how you actually feel; your pattern may differ."],
        evidenceNote: "Based on well-established cycle physiology and resistance-training reviews whose findings on follicular-phase strength gains remain mixed."
    )

    static let ovulation = PhaseReport(
        title: "Your fertile window this week",
        body: "Around now, roughly days 12 to 16, your estrogen is peaking and your body is preparing to release an egg. A short surge of luteinizing hormone (LH) triggers ovulation itself, usually within a day or two. You might notice cervical mucus turning clear, stretchy, and slippery, a bit like raw egg white; that's a normal sign of high estrogen. Some people feel a brief one-sided ache low in the belly, called mittelschmerz. Research suggests roughly 2 in 5 people who menstruate notice it at some point, and it typically passes on its own. Many also report feeling more energetic, social, and clear-headed around this window, which fits the rise in estrogen. Just after ovulation, your basal temperature usually nudges up by half a degree to a degree Fahrenheit (about 0.3–0.5 °C) as progesterone rises. These are helpful signals for knowing your own body, not a reliable way to prevent pregnancy.",
        tips: ["Clear, egg-white mucus signals your most fertile days.",
               "A brief one-sided ache around ovulation is called mittelschmerz.",
               "Basal temperature rises slightly after ovulation, not before.",
               "Lean into higher energy and plan social things now."],
        evidenceNote: "Based on well-established reproductive physiology plus replicated studies of mood and sociability shifts across the menstrual cycle."
    )

    static let luteal = PhaseReport(
        title: "Progesterone takes the lead",
        body: "After ovulation, your progesterone climbs and steers the next couple of weeks. That rise nudges your basal body temperature up half a degree to a degree Fahrenheit (about 0.3–0.5 °C). That's small, but enough that many people notice warmer, lighter sleep or a harder time drifting off later in the phase. Your appetite often picks up too. Research suggests your body may burn modestly more energy now (estimates vary a lot by method, roughly 90–300 extra calories a day), so feeling hungrier is a normal response, not a slip. Carb cravings are common and partly tied to a dip in serotonin. Leaning on complex carbs and magnesium-rich foods is a gentle way many people help steady mood and energy. You might feel more emotionally sensitive as your period nears. That's also common, and it usually eases once bleeding starts. This can be a good stretch to trade some high-intensity training for gentler movement when your body asks for it. Should low mood or symptoms feel severe or disruptive cycle after cycle, a clinician can help you sort out what's going on.",
        tips: ["Favor complex carbs over sugary snacks for steadier energy.",
               "Add magnesium-rich foods: leafy greens, nuts, seeds, dark chocolate.",
               "Keep your bedroom cool to ease warmer, lighter sleep.",
               "Swap some intense workouts for walking, yoga, or mobility."],
        evidenceNote: "Based on menstrual-cycle physiology research on progesterone, plus studies of luteal-phase energy expenditure, body-temperature shifts, sleep changes, and magnesium and carbohydrate effects on premenstrual symptoms."
    )

    static let premenstrual = PhaseReport(
        title: "The week before: what's real",
        body: "In the last few days before your period, both estrogen and progesterone are dropping, and for many people that hormonal shift seems to line up with what they feel as PMS. Estimates vary widely, but research suggests a large share of menstruating people notice premenstrual symptoms, most often bloating, breast tenderness, headaches, fatigue, irritability, low mood, or restless sleep. These usually ease once bleeding begins. Gentle movement seems to help: randomized trials of yoga and stretching for period pain and PMS have reported lower cramping and calmer mood, so a slow evening flow is worth trying. Sleep can turn lighter now, so a steady wind-down, a cool dark room, and easing off late caffeine may protect your rest. If the intensity disrupts your work, relationships, or sense of self month after month (a more intense pattern is sometimes named premenstrual dysphoric disorder, or PMDD), it's worth mentioning to a clinician, who may ask you to track a couple of cycles.",
        tips: ["Try a slow 10-minute stretch or yoga flow.",
               "Keep the bedroom cool, dark, and screen-free.",
               "Ease off caffeine and alcohol in the evening.",
               "Note symptoms across cycles to spot your patterns."],
        evidenceNote: "Based on randomized trials of yoga and stretching for menstrual pain and PMS, plus reviews of luteal-phase physiology and symptom prevalence."
    )

    /// The stretching story — surfaced on the Stretch coach's evidence card.
    static let stretching = PhaseReport(
        title: "Stretching and your cycle",
        body: "If cramps tend to visit you each cycle, gentle stretching may genuinely help. Randomized trials, including programs of simple active stretches done a few times a week, have found meaningful drops in menstrual pain intensity, and reviews pooling dozens of trials suggest most forms of movement, from stretching to yoga, ease period pain compared with doing nothing. Why might that be? Researchers think stretching may boost blood flow to your pelvic muscles, encourage your body's own endorphins, and nudge your nervous system toward its calmer, rest-and-digest mode, all of which could soften how cramps feel, though the exact mechanisms aren't fully settled. Benefits build over weeks of regular practice rather than one session, and results vary: many people notice a real difference, some notice little. Consistency matters more than intensity: a few relaxed minutes most days beats one long session. And if pain keeps disrupting your life despite these strategies, a clinician can help.",
        tips: ["Try 10 minutes of gentle stretching most days.",
               "Consistency beats intensity; benefits build over weeks.",
               "Focus on hips, lower back, and inner thighs.",
               "Pair stretches with slow breathing for extra calm."],
        evidenceNote: "Based on randomized controlled trials and meta-analyses of stretching, yoga, and exercise programs for primary dysmenorrhea."
    )
}
