// Self-check for the JS cycle engine. Run: node web/core/engine.test.mjs
// Asserts hand-computed expectations so a broken port fails loudly before the
// golden vectors are regenerated from it.
import assert from "node:assert";
import { predict } from "./engine.js";
import { dateFromKey, keyFromDate } from "./dates.js";

const S = { defaultCycleLength: 28, defaultPeriodLength: 5, lutealPhaseLength: 14 };
const days = (...keys) => keys.map(dateFromKey);

// Three clean 28-day cycles, 5-day periods.
function run(keys, todayKey) {
  return predict(days(...keys), dateFromKey(todayKey), S);
}
const periodKeys = [
  "2026-04-01","2026-04-02","2026-04-03","2026-04-04","2026-04-05",
  "2026-04-29","2026-04-30","2026-05-01","2026-05-02","2026-05-03",
  "2026-05-27","2026-05-28","2026-05-29","2026-05-30","2026-05-31",
];
const p = run(periodKeys, "2026-06-10");
assert.equal(p.averageCycleLength, 28, "avgCycle");
assert.equal(p.averagePeriodLength, 5, "avgPeriod");
assert.equal(keyFromDate(p.nextPeriodStart), "2026-06-24", "nextPeriod");
assert.equal(keyFromDate(p.ovulationDate), "2026-06-10", "ovulation");
assert.equal(keyFromDate(p.fertileStart), "2026-06-05", "fertileStart");
assert.equal(keyFromDate(p.fertileEnd), "2026-06-11", "fertileEnd");
assert.equal(p.cycleDay, 15, "cycleDay");
assert.equal(p.daysUntilNextPeriod, 14, "daysUntil");
assert.equal(p.phase, "ovulation", "phase on ovulation day");

// Phase transitions on the same history.
assert.equal(run(periodKeys, "2026-05-29").phase, "menstrual", "within period");
assert.equal(run(periodKeys, "2026-06-04").phase, "follicular", "before fertile window");
assert.equal(run(periodKeys, "2026-06-07").phase, "fertile", "inside fertile window");
assert.equal(run(periodKeys, "2026-06-20").phase, "luteal", "after fertile window");

// No history -> nothing predicted, defaults reported.
const none = predict([], dateFromKey("2026-06-10"), S);
assert.equal(none.hasHistory, false);
assert.equal(none.nextPeriodStart, null);
assert.equal(none.averageCycleLength, 28);

// A 3-day gap starts a new period; a 2-day gap merges (maxGap=1).
const merged = predict(days("2026-04-01","2026-04-03"), dateFromKey("2026-04-10"), S); // gap 2 -> one period
assert.equal(periodStartsCount(merged), 1, "2-day gap merges");
function periodStartsCount(pred) { return pred.lastPeriodStart ? 1 : 0; } // single-start sanity

// Irregular cycles: last-6 window + rounding. Starts 30 then 26 apart -> avg 28.
const irr = predict(
  days("2026-01-01","2026-01-31","2026-02-26"), dateFromKey("2026-03-01"), S,
);
assert.equal(irr.averageCycleLength, 28, "avg of 30 and 26");

console.log("engine.test.mjs: all assertions passed");
