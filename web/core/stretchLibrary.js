// Cramp-ease stretch plan — a faithful ES-module port of App/Core/StretchLibrary.swift.
// Pure data + logic: NO window / DOM / React references at import time, so it loads
// in Node and the browser identically. The plan/move data is kept byte-for-byte with
// the Swift source (evidence notes, cues, holds, seconds, icons, minutes).
//
// A gentle 14-day (luteal-phase) routine for the two weeks before the period.
// Evidence (verified via PubMed) lives in the notes below; this is preventive
// wellness guidance, not medical advice.

import { addDays, startOfDay } from "./dates.js";
import { stretching } from "./phaseResearch.js";

// ---- shapes ----------------------------------------------------------------

// StretchMove — id = name + hold (matches Swift StretchMove.id). Defaults mirror
// Swift: seconds 45 (guided-timer length), icon "figure.flexibility".
function move(name, hold, cue, { seconds = 45, icon = "figure.flexibility" } = {}) {
  return { name, hold, cue, seconds, icon, id: name + hold };
}

// StretchDay — id = daysBeforePeriod (14 = plan start … 1 = day before the period).
function day(daysBeforePeriod, focus, minutes, moves) {
  return { daysBeforePeriod, focus, minutes, moves, id: daysBeforePeriod };
}

// ---- tiers -----------------------------------------------------------------
// Three modes of the same evidence base. Trio is the no-schedule anytime session
// (no lock-in, no pressure); starter (the default) is a 3-day plan on the three
// days before the period; full is the complete 14-day routine. Switching modes is
// presentation only — completions are stored per calendar date, so history
// survives any number of switches, in both directions.
export const TOTAL_DAYS = 14;

// multiplier = points multiplier for the mode; locksIn modes charge 5 petals for
// a missed plan day (StretchTier in StretchLibrary.swift).
export const TIERS = {
  trio: { key: "trio", totalDays: 0, label: "Core trio", multiplier: 1, locksIn: false },
  starter: { key: "starter", totalDays: 3, label: "3-day starter", multiplier: 2, locksIn: true },
  full: { key: "full", totalDays: 14, label: "Full 14-day", multiplier: 4, locksIn: true },
};

// The store's `stretchTier` raw string -> a tier object. Unknown values fall back
// to starter, mirroring `StretchTier(rawValue:) ?? .starter`.
export const tierFor = (raw) => TIERS[raw] ?? TIERS.starter;

// ---- reusable cues (mirror the private StretchMove constants in Swift) -------
const breathing = move("Diaphragmatic breathing", "5–6 slow breaths",
  "Lie back, one hand on your belly. Breathe into it slowly, with long easy exhales.",
  { seconds: 60, icon: "wind" });
const pelvicTilts = move("Pelvic tilts", "10–12 reps",
  "On your back, knees bent. Gently flatten then arch your low back with your breath.",
  { seconds: 60, icon: "figure.core.training" });
const catCow = move("Cat-Cow", "45–60s flowing",
  "On all fours, alternate arching and rounding your spine, moving with your breath.",
  { seconds: 60, icon: "figure.flexibility" });
const childs = move("Child's pose", "45–60s",
  "Knees wide, sit back toward your heels, forehead down, arms long. Breathe into your back.",
  { seconds: 60, icon: "figure.cooldown" });
const knees = move("Knees-to-chest", "30–40s",
  "Hug both knees to your chest and let your low back soften. Rock side to side if it feels good.",
  { seconds: 40, icon: "figure.rolling" });
const cobra = move("Cobra (gentle)", "20–25s × 3",
  "Face down, press up low and easy through your arms. Keep it pain-free, shoulders down.",
  { seconds: 75, icon: "figure.flexibility" });
const fish = move("Supported Fish", "20–25s × 2",
  "Lie back over a rolled towel under your upper back, chest open. Skip if it strains your neck.",
  { seconds: 50, icon: "figure.flexibility" });
const restfulBreath = move("Constructive rest", "2 min",
  "Lie down, knees bent, feet wide, and just breathe. Let your belly and hips go heavy.",
  { seconds: 120, icon: "wind" });

// ---- the 3-day starter -----------------------------------------------------
export const starterDays = [
  day(3, "The core trio", 10, [catCow, cobra, fish, childs]),
  day(2, "Belly & pelvic", 8, [
    pelvicTilts, knees,
    move("Standing side stretch", "20s each side",
      "Reach one arm overhead and lean gently away, both sides.", { seconds: 40 }),
    childs,
  ]),
  day(1, "Gentle relief & breath", 6, [breathing, knees, childs]),
];

// ---- the full 14-day plan --------------------------------------------------
export const fullDays = [
  day(14, "Foundations & breath", 8, [breathing, pelvicTilts, catCow, childs]),
  day(13, "Light mobility", 5, [catCow, knees, childs]),
  day(12, "Core session: the luteal trio", 12, [catCow, cobra, fish, pelvicTilts, childs]),
  day(11, "Light: hips & low back", 6, [
    move("Butterfly / adductor", "40s",
      "Sit, soles together, let your knees ease down. Hinge gently forward from the hips."),
    move("Supine figure-4", "30s each side",
      "On your back, ankle over the opposite knee, draw the thigh toward you.", { seconds: 60 }),
    knees,
  ]),
  day(10, "Core session: belly & pelvic", 13, [
    move("Standing warm-up", "2–3 min", "March in place and reach side to side to warm up.",
      { seconds: 150, icon: "figure.walk" }),
    move("Standing side stretch", "20s each side",
      "Reach one arm overhead and lean gently away.", { seconds: 40 }),
    pelvicTilts, knees, childs,
  ]),
  day(9, "Restorative & breath", 5, [childs, restfulBreath]),
  day(8, "Core session: full routine", 14, [
    catCow, cobra, fish,
    move("Standing side stretch", "20s each side",
      "Reach overhead and lean gently away, both sides.", { seconds: 40 }),
    pelvicTilts, childs,
  ]),
  day(7, "Light: hamstrings & low back", 7, [
    move("Supine hamstring stretch", "30s each side",
      "On your back, raise one leg, hold behind the thigh or use a strap.", { seconds: 60 }),
    knees, childs,
  ]),
  day(6, "Core session: Cobra/Cat/Fish", 12, [catCow, cobra, fish, childs]),
  day(5, "Restorative: gentle twists", 6, [
    catCow,
    move("Supine gentle twist", "30s each side",
      "On your back, drop bent knees to one side, gaze the other way.",
      { seconds: 60, icon: "figure.cooldown" }),
    childs,
  ]),
  day(4, "Core session: gentler", 11, [
    move("Standing warm-up", "2 min", "March and reach to warm up.",
      { seconds: 120, icon: "figure.walk" }),
    move("Standing side stretch", "20s each side", "Reach overhead, lean gently.", { seconds: 40 }),
    pelvicTilts, knees, childs,
  ]),
  day(3, "Gentle relief", 6, [catCow, knees, childs]),
  day(2, "Gentle relief & breath", 6, [restfulBreath, knees, childs]),
  day(1, "Very gentle, optional", 5, [breathing, knees, childs]),
];

// ---- lookups ---------------------------------------------------------------
// Mirrors Swift's `StretchPlan.days(for:)`: only starter swaps the list (trio has
// no schedule of its own, so it never asks).
export function daysFor(tier) { return tier.key === "starter" ? starterDays : fullDays; }

// The session for a given days-until-period on a tier, or null if outside the window.
export function session(daysUntilPeriod, tier) {
  return daysFor(tier).find((d) => d.daysBeforePeriod === daysUntilPeriod) ?? null;
}

// 1-based "Day N of the plan" for a session within a tier.
export function planDay(d, tier) { return tier.totalDays + 1 - d.daysBeforePeriod; }

// The calendar date for a 1-based plan day. Anchored so the window ends the day
// before the predicted period when a prediction exists; otherwise the window
// simply STARTS today (the plan starts when she does). Either way every plan day
// maps to a real date, so every schedule checkbox is always live — a null here
// is what once left whole plans' checkboxes dead. Pure and pinned by the
// self-check below (mirrors StretchPlan.date(forPlanDay:) + StretchPlanTests);
// completions are stored per calendar date, so remapping (e.g. a prediction
// appearing later) never loses history.
export function dateForPlanDay(planDayN, tier, nextPeriodStart, today) {
  const start = nextPeriodStart
    ? addDays(nextPeriodStart, -tier.totalDays)
    : startOfDay(today);
  return addDays(start, planDayN - 1);
}

// Off-schedule fallback so checking off stretches is always available — and the
// whole of the trio mode.
export const anytimeSession = starterDays[0];

// Best day's pose points on a mode: 15·m + 5·(m−1) + 10 = 20m + 5, times the
// multiplier (StretchCoachView.maxDailyPoints). Drives the mode chooser previews.
export function maxDailyPoints(tier) {
  const sessions = tier.key === "trio" ? [anytimeSession] : daysFor(tier);
  const m = sessions.reduce((n, d) => Math.max(n, d.moves.length), 0);
  return (20 * m + 5) * tier.multiplier;
}

// ---- copy blocks (verbatim from Swift) -------------------------------------
export const summary =
  "A gentle 14-day routine for the two weeks before your period. Across the research, " +
  "low-intensity stretching and yoga can meaningfully ease period cramps, but it's " +
  "preventive, not a quick fix. Benefits build over a few weeks, so give it two cycles.";

// The readable short report shown before the citations. ponytail: this is
// PhaseResearch.stretching.body — the web HAS that port now (it didn't when this
// prose was first copied here), so re-export the one copy rather than keep a
// second that every copy sweep has to find twice. Both modules are pure.
export const stretchingReport = stretching.body;

export const evidenceNote =
  "Why it may help: a Cochrane review found exercise lowered cramp pain; a 2011 trial of " +
  "Cobra, Cat and Fish poses and a 2017 trial where ~10 minutes of belly-and-pelvic " +
  "stretching worked about as well as an anti-inflammatory both point the same way. " +
  "The evidence is promising but from small studies. Think “may help,” not a cure.";

export const dosingNote =
  "The 30-second holds and ~3 fuller sessions a week follow the stretching-dose research " +
  "popularized by David Thurin (“Stay Flexy”): a 2025 meta-analysis on how to " +
  "stretch effectively. That one is about flexibility, not cramps; the cramp relief comes " +
  "from the cycle studies above.";

export const disclaimer =
  "This is wellness guidance, not medical advice. It's for typical period cramps. If your " +
  "pain is new, severe, or different than usual, please see a clinician.";

export const contraindications = [
  "Possibly pregnant? This plan runs when pregnancy is possible, so skip the deep belly stretches (Cobra, Fish) and check with a clinician first.",
  "Stay gentle: only ever a mild sense of stretch, never sharp pain. Breathe slowly, especially on the exhale.",
  "Skip Fish pose with neck problems or blood-pressure concerns; skip Cobra after abdominal or pelvic surgery, a hernia, or significant back pain.",
  "New, severe, or unusual pain (or a known condition your doctor has restricted exercise for) means check first, don't push through.",
];

// ---- pose figures ----------------------------------------------------------
// Best-effort mapping from a move's display name to a pose kind (mirrors
// PoseKind.from in App/Components/PoseFigure.swift).
export function poseKind(name) {
  const n = name.toLowerCase();
  if (n.includes("cat")) return "allFours";
  if (n.includes("cobra")) return "cobra";
  if (n.includes("child")) return "childsPose";
  if (n.includes("knees-to-chest") || n.includes("knees to chest")) return "kneesToChest";
  if (n.includes("fish")) return "fish";
  if (n.includes("pelvic")) return "pelvicTilt";
  if (n.includes("butterfly") || n.includes("adductor")) return "butterfly";
  if (n.includes("side stretch")) return "sideStretch";
  if (n.includes("twist")) return "twist";
  if (n.includes("hamstring") || n.includes("figure-4")) return "hamstring";
  return null;
}

// Each pose is drawn in a 0…1 unit space (ground ≈ y 0.88), ported directly from
// PoseShape.path in Swift. head = [cx, cy, r] (stroked circle); paths = SVG "d"
// strings (M/L lines, M…Q…quad curves). Screens render these as inline <svg>.
export const POSE_SHAPES = {
  allFours: {
    head: [0.16, 0.44, 0.09],
    paths: ["M0.24 0.48 Q0.5 0.22 0.78 0.52", "M0.26 0.5 L0.26 0.88",
      "M0.74 0.54 L0.74 0.88", "M0.74 0.88 L0.92 0.88"],
  },
  cobra: {
    head: [0.2, 0.3, 0.09],
    paths: ["M0.26 0.38 Q0.34 0.62 0.62 0.82", "M0.62 0.82 L0.95 0.86", "M0.3 0.44 L0.3 0.84"],
  },
  childsPose: {
    head: [0.24, 0.62, 0.09],
    paths: ["M0.3 0.66 Q0.52 0.36 0.72 0.62", "M0.72 0.62 L0.72 0.88",
      "M0.72 0.88 L0.52 0.88", "M0.22 0.7 L0.05 0.82"],
  },
  kneesToChest: {
    head: [0.14, 0.66, 0.09],
    paths: ["M0.2 0.72 L0.55 0.78", "M0.55 0.78 Q0.72 0.55 0.5 0.42",
      "M0.5 0.42 Q0.38 0.38 0.34 0.52", "M0.9 0.86 L0.06 0.86"],
  },
  fish: {
    head: [0.2, 0.62, 0.09],
    paths: ["M0.26 0.6 Q0.4 0.36 0.6 0.74", "M0.6 0.74 L0.92 0.78", "M0.9 0.88 L0.06 0.88"],
  },
  pelvicTilt: {
    head: [0.12, 0.72, 0.09],
    paths: ["M0.18 0.76 L0.6 0.8", "M0.6 0.8 L0.74 0.5",
      "M0.74 0.5 L0.82 0.86", "M0.92 0.88 L0.05 0.88"],
  },
  butterfly: {
    head: [0.5, 0.2, 0.09],
    paths: ["M0.5 0.28 L0.5 0.62", "M0.5 0.62 Q0.2 0.6 0.24 0.86",
      "M0.5 0.62 Q0.8 0.6 0.76 0.86", "M0.24 0.86 L0.76 0.86"],
  },
  sideStretch: {
    head: [0.55, 0.16, 0.09],
    paths: ["M0.55 0.24 Q0.6 0.44 0.48 0.62", "M0.48 0.62 L0.42 0.9",
      "M0.56 0.62 L0.62 0.9", "M0.55 0.26 Q0.4 0.08 0.28 0.1"],
  },
  twist: {
    head: [0.14, 0.6, 0.09],
    paths: ["M0.2 0.66 L0.56 0.7", "M0.56 0.7 L0.78 0.52",
      "M0.78 0.52 L0.7 0.34", "M0.9 0.86 L0.06 0.86"],
  },
  hamstring: {
    head: [0.14, 0.72, 0.09],
    paths: ["M0.2 0.76 L0.62 0.8", "M0.62 0.8 L0.66 0.28",
      "M0.62 0.8 L0.9 0.84", "M0.94 0.88 L0.06 0.88"],
  },
};

// ponytail: one runnable check — `node web/core/stretchLibrary.js` asserts the plan
// shape. Guarded on process so importing in the browser never touches it.
if (typeof process !== "undefined" && process.argv && String(process.argv[1]).endsWith("stretchLibrary.js")) {
  const assert = (c, m) => { if (!c) throw new Error("stretchLibrary self-check: " + m); };
  assert(starterDays.length === 3, "starter has 3 days");
  assert(fullDays.length === 14, "full has 14 days");
  assert(planDay(starterDays[0], TIERS.starter) === 1, "starter day 1 -> planDay 1");
  assert(planDay(fullDays[fullDays.length - 1], TIERS.full) === 14, "full day 1-before -> planDay 14");
  assert(session(3, TIERS.starter)?.focus === "The core trio", "session(3, starter)");
  assert(session(14, TIERS.full)?.focus === "Foundations & breath", "session(14, full)");
  assert(session(9, TIERS.starter) === null, "starter has no day 9");
  assert(TIERS.trio.multiplier === 1 && TIERS.starter.multiplier === 2 && TIERS.full.multiplier === 4, "tier multipliers");
  assert(!TIERS.trio.locksIn && TIERS.starter.locksIn && TIERS.full.locksIn, "only scheduled tiers lock in");
  assert(tierFor("trio") === TIERS.trio && tierFor("full") === TIERS.full, "tierFor maps raw values");
  assert(tierFor(null) === TIERS.starter && tierFor("nonsense") === TIERS.starter, "tierFor falls back to starter");
  assert(daysFor(TIERS.starter) === starterDays && daysFor(TIERS.trio) === fullDays, "daysFor mirrors Swift days(for:)");
  assert(anytimeSession === starterDays[0], "the trio IS the anytime session");
  assert(maxDailyPoints(TIERS.trio) === 85, "trio previews 85/day");
  assert(maxDailyPoints(TIERS.starter) === 170, "starter previews 170/day");
  assert(maxDailyPoints(TIERS.full) === 500, "full previews 500/day");
  assert(poseKind("Cat-Cow") === "allFours" && poseKind("Supported Fish") === "fish", "poseKind mapping");
  assert(starterDays[0].moves[0].id === "Cat-Cow45–60s flowing", "move id = name+hold");

  // ---- plan-window math (mirrors Tests/StretchPlanTests.swift) ----
  const D = (y, m, d) => new Date(y, m - 1, d);
  const eq = (a, b) => a.getTime() === b.getTime();
  const next = D(2026, 8, 1), today16 = D(2026, 7, 16);
  // Anchored: the window ends the day before the predicted period.
  assert(eq(dateForPlanDay(1, TIERS.full, next, today16), D(2026, 7, 18)), "full day 1 -> Jul 18");
  assert(eq(dateForPlanDay(14, TIERS.full, next, today16), D(2026, 7, 31)), "full day 14 ends the day before the period");
  assert(eq(dateForPlanDay(1, TIERS.starter, next, today16), D(2026, 7, 29)), "starter day 1 -> Jul 29");
  assert(eq(dateForPlanDay(3, TIERS.starter, next, today16), D(2026, 7, 31)), "starter day 3 ends the day before the period");
  // The regression that broke the checkboxes: with no prediction every day must
  // STILL have a date, and the fallback window starts today — so no day ever
  // precedes today, and the lock-in penalty loop (which only charges dates
  // before today) is inert.
  for (const t of [TIERS.starter, TIERS.full]) {
    for (let n = 1; n <= t.totalDays; n++) {
      const date = dateForPlanDay(n, t, null, today16);
      assert(date instanceof Date && !Number.isNaN(date.getTime()), `plan day ${n} of ${t.label} lost its date`);
      assert(date >= today16, `fallback day ${n} of ${t.label} precedes today`);
    }
  }
  assert(eq(dateForPlanDay(1, TIERS.full, null, today16), D(2026, 7, 16)), "fallback window starts today");
  assert(eq(dateForPlanDay(14, TIERS.full, null, today16), D(2026, 7, 29)), "fallback day 14 = today + 13");
  // An afternoon "today" maps like midnight — time of day never shifts the window.
  assert(eq(dateForPlanDay(1, TIERS.full, null, new Date(2026, 6, 16, 14, 30)), D(2026, 7, 16)), "fallback ignores time of day");

  // planDay / session round-trips: the schedule labels and the per-day sessions
  // agree on both tiers, and day numbers are exactly 1...totalDays, each once.
  for (const t of [TIERS.starter, TIERS.full]) {
    const nums = daysFor(t).map((s) => planDay(s, t)).sort((a, b) => a - b);
    assert(nums.length === t.totalDays && nums.every((n, i) => n === i + 1), `plan days of ${t.label} are 1...${t.totalDays}`);
    for (const s of daysFor(t)) {
      assert(session(s.daysBeforePeriod, t)?.daysBeforePeriod === s.daysBeforePeriod, `session round-trip (${t.label})`);
    }
  }

  // The schedule's "today" row maps through daysUntilNextPeriod, so pin the two
  // engine behaviors StretchPlanTests also pins (dynamic import keeps the
  // browser bundle clear of the engine).
  const { predict } = await import("./engine.js");
  const { DEFAULT_SETTINGS } = await import("./models.js");
  // 14:30 on Jul 13 is still 16 calendar days before Jul 29, not 15 — a
  // truncation here would silently shift which row wears the "today" badge.
  const afternoon = new Date(2026, 6, 13, 14, 30);
  const periodDays = [1, 2, 3, 4].map((d) => D(2026, 7, d));
  const p = predict(periodDays, afternoon, DEFAULT_SETTINGS);
  assert(eq(p.nextPeriodStart, D(2026, 7, 29)), "prediction lands Jul 29");
  assert(p.daysUntilNextPeriod === 16, "daysUntilNextPeriod counts calendar days");
  // Her locked numbers must beat the logged averages — BOTH of them, or the
  // period stepper is a placebo for anyone with logged flow.
  const twoCycles = [];
  for (const start of [D(2026, 5, 1), D(2026, 5, 29)]) {
    for (let off = 0; off < 4; off++) twoCycles.push(addDays(start, off));
  }
  const locked = { ...DEFAULT_SETTINGS, defaultCycleLength: 31, defaultPeriodLength: 6, lockCycleLength: true };
  const pl = predict(twoCycles, D(2026, 6, 5), locked);
  assert(pl.averageCycleLength === 31 && pl.averagePeriodLength === 6, "locked lengths override the averages");
  assert(eq(pl.nextPeriodStart, D(2026, 6, 29)), "locked prediction = May 29 + 31");
  const pu = predict(twoCycles, D(2026, 6, 5), { ...locked, lockCycleLength: false });
  assert(pu.averageCycleLength === 28 && pu.averagePeriodLength === 4, "unlocking restores the averages");

  console.log("stretchLibrary self-check OK");
}
