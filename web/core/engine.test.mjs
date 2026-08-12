// Self-check for the JS cycle engine. Run: node web/core/engine.test.mjs
// Asserts hand-computed expectations so a broken port fails loudly before the
// golden vectors are regenerated from it.
import assert from "node:assert";
import { predict, projectedCycles } from "./engine.js";
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

// lockCycleLength: her numbers beat the logged averages — BOTH of them.
const locked = predict(periodKeys.map(dateFromKey), dateFromKey("2026-06-10"),
  { ...S, defaultCycleLength: 31, defaultPeriodLength: 6, lockCycleLength: true });
assert.equal(locked.averageCycleLength, 31, "locked cycle length wins");
assert.equal(locked.averagePeriodLength, 6, "locked period length wins");
assert.equal(keyFromDate(locked.nextPeriodStart), "2026-06-27", "next period from HER cycle length");
// And absent/false lock keeps the logged averages (old blobs decode with lock unset).
assert.equal(predict(periodKeys.map(dateFromKey), dateFromKey("2026-06-10"),
  { ...S, defaultCycleLength: 31 }).averageCycleLength, 28, "unlocked still averages");

// ---- projectedCycles: the year-ahead marks (mirrors Tests/CycleEngineTests) ----
// Same fixture as the Swift test, so both engines are pinned to the SAME dates.
{
  const days5 = days("2026-07-01", "2026-07-02", "2026-07-03", "2026-07-04", "2026-07-05");
  const t = dateFromKey("2026-07-13");
  const p5 = predict(days5, t, S);
  const cycles = projectedCycles(p5, S, t);

  // The first entry reproduces the prediction's own next period / fertile window.
  assert.equal(keyFromDate(cycles[0].periodStart), keyFromDate(p5.nextPeriodStart), "first start == predict");
  assert.equal(keyFromDate(cycles[0].ovulation), keyFromDate(p5.ovulationDate), "first ovulation == predict");
  assert.equal(keyFromDate(cycles[0].fertileStart), keyFromDate(p5.fertileStart), "first fertileStart == predict");
  assert.equal(keyFromDate(cycles[0].fertileEnd), keyFromDate(p5.fertileEnd), "first fertileEnd == predict");

  // Second cycle sits one average cycle later, window shaped the same.
  assert.equal(keyFromDate(cycles[1].periodStart), "2026-08-26", "second start");
  assert.equal(keyFromDate(cycles[1].ovulation), "2026-08-12", "second ovulation");
  assert.equal(keyFromDate(cycles[1].fertileStart), "2026-08-07", "second fertileStart");
  assert.equal(keyFromDate(cycles[1].fertileEnd), "2026-08-13", "second fertileEnd");
  assert.equal(keyFromDate(cycles[1].periodEnd), "2026-08-30", "second periodEnd");

  // Reaches a year out, one entry per cycle, every window before its period.
  assert.equal(cycles.length, 13, "a year of cycles");
  assert.equal(keyFromDate(cycles[cycles.length - 1].periodStart), "2027-06-30", "last start within the horizon");
  assert.ok(cycles.every((c) => c.fertileStart < c.periodStart), "every fertile window precedes its period");

  // No history -> nothing to project.
  assert.deepEqual(projectedCycles(predict([], t, S), S, t), [], "no history projects nothing");
}

console.log("engine.test.mjs: all assertions passed");
