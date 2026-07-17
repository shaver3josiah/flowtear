// Generate contracts/cycle-vectors.json — the golden input->output vectors for
// the cycle predictor. Run: npm run gen:vectors  (after an intentional change to
// the algorithm). Both engines (engine.js and CycleEngine.swift) must reproduce
// these; check:parity verifies the JS side, and the iOS side should validate the
// same file in its test target.
import { writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { predict } from "../web/core/engine.js";
import { dateFromKey, keyFromDate } from "../web/core/dates.js";

const S = { defaultCycleLength: 28, defaultPeriodLength: 5, lutealPhaseLength: 14 };

// Named scenarios: period-day keys + the "today" they're evaluated at.
const SCENARIOS = {
  noHistory: { periodKeys: [], today: "2026-06-10" },
  singlePeriod: { periodKeys: ["2026-05-01", "2026-05-02", "2026-05-03", "2026-05-04", "2026-05-05"], today: "2026-05-20" },
  threeCleanCycles: {
    periodKeys: [
      "2026-04-01", "2026-04-02", "2026-04-03", "2026-04-04", "2026-04-05",
      "2026-04-29", "2026-04-30", "2026-05-01", "2026-05-02", "2026-05-03",
      "2026-05-27", "2026-05-28", "2026-05-29", "2026-05-30", "2026-05-31",
    ],
    today: "2026-06-10",
  },
  irregular: { periodKeys: ["2026-01-01", "2026-01-31", "2026-02-26", "2026-03-30"], today: "2026-04-05" },
  twoDayGapMerges: { periodKeys: ["2026-03-01", "2026-03-03", "2026-03-31"], today: "2026-04-02" },
  midCycleToday: {
    periodKeys: ["2026-02-01", "2026-02-02", "2026-02-03", "2026-03-01", "2026-03-02", "2026-03-03"],
    today: "2026-03-14",
  },
  // lockCycleLength: her 30/6 beats the logged 28/3 averages (contracts v1.2.0).
  lockedCycleLength: {
    periodKeys: ["2026-02-01", "2026-02-02", "2026-02-03", "2026-03-01", "2026-03-02", "2026-03-03"],
    today: "2026-03-14",
    settings: { defaultCycleLength: 30, defaultPeriodLength: 6, lutealPhaseLength: 14, lockCycleLength: true },
  },
};

const isoOrNull = (d) => (d ? keyFromDate(d) : null);

const vectors = {};
for (const [name, s] of Object.entries(SCENARIOS)) {
  const settings = s.settings ?? S;
  const p = predict(s.periodKeys.map(dateFromKey), dateFromKey(s.today), settings);
  vectors[name] = {
    input: { periodKeys: s.periodKeys, today: s.today, settings },
    expect: {
      averageCycleLength: p.averageCycleLength,
      averagePeriodLength: p.averagePeriodLength,
      lastPeriodStart: isoOrNull(p.lastPeriodStart),
      nextPeriodStart: isoOrNull(p.nextPeriodStart),
      ovulationDate: isoOrNull(p.ovulationDate),
      fertileStart: isoOrNull(p.fertileStart),
      fertileEnd: isoOrNull(p.fertileEnd),
      cycleDay: p.cycleDay,
      phase: p.phase,
      daysUntilNextPeriod: p.daysUntilNextPeriod,
      hasHistory: p.hasHistory,
    },
  };
}

const out = {
  meta: {
    generatedFrom: "web/core/engine.js",
    note: "Golden vectors for the cycle predictor. Do not hand-edit — run `npm run gen:vectors`.",
  },
  settings: S,
  vectors,
};

const dir = dirname(fileURLToPath(import.meta.url));
const path = join(dir, "..", "contracts", "cycle-vectors.json");
writeFileSync(path, JSON.stringify(out, null, 2) + "\n");
console.log(`Wrote ${path} (${Object.keys(vectors).length} scenarios)`);
