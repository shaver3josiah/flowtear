// Self-check for the CSV builder. Run: node web/core/report.test.mjs
// Expectations are hand-written from CycleReport.swift's csv(store:) — column
// order, the quoted moods/symptoms/note fields, "" escaping, %.2f °F, and the
// dateKey sort. A broken port fails loudly here.
import assert from "node:assert";
import { csv, flags, text, CSV_HEADER, CSV_FILENAME } from "./report.js";

// A phaseSnapshot stub keyed by dateKey — csv() places the columns; the engine's
// own snapshot math is tested in engine.test.mjs, so here we only pin the wiring.
const snaps = {
  "2026-06-01": { phase: null, day: null },
  "2026-06-02": { phase: "menstrual", day: 2 },
};
const store = {
  phaseSnapshot: (d) => snaps[
    `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`
  ] ?? { phase: null, day: null },
  logsSnapshot: [
    // Deliberately out of order — Swift sorts by dateKey.
    {
      dateKey: "2026-06-02", flow: "medium", discharge: "creamy", temperatureC: 36.85,
      moods: ["sad", "happy"], symptoms: ["cramps"], note: 'she said "ow"',
      tempSkipped: null, stretchDone: true, stretchMovesDone: null,
    },
    {
      dateKey: "2026-06-01", flow: null, discharge: null, temperatureC: null,
      moods: [], symptoms: [], note: "",
      tempSkipped: true, stretchDone: null, stretchMovesDone: null,
    },
  ],
};

assert.deepEqual(csv(store).split("\n"), [
  CSV_HEADER,
  // date,cycle_day,phase,flow,discharge,temp_f,temp_skipped,moods,symptoms,stretch_done,note
  '2026-06-01,,,,,,yes,"","",,""',
  '2026-06-02,2,menstrual,medium,creamy,98.33,,"happy; sad","cramps",yes,"she said ""ow"""',
]);

assert.equal(CSV_HEADER, "date,cycle_day,phase,flow,discharge,temp_f,temp_skipped,moods,symptoms,stretch_done,note");
assert.equal(CSV_FILENAME, "uncorked-cycle-data.csv");
assert.equal(csv({ logsSnapshot: [] }), CSV_HEADER); // header-only, never empty

// Super heavy flow in the last ~month raises exactly one flag, pluralized by count.
const heavyStore = (keys) => ({
  periodDays: [],
  prediction: () => ({ hasHistory: false, daysUntilNextPeriod: null }),
  logsSnapshot: keys.map((dateKey) => ({ dateKey, flow: "superHeavy", moods: [], symptoms: [] })),
});
const todayRef = new Date(2026, 5, 20); // Jun 20 2026
const oneHeavy = flags(heavyStore(["2026-06-18"]), todayRef);
assert.ok(oneHeavy.includes("Super heavy flow on 1 day this month. If that's new for you, mention it at a visit."),
  "one super-heavy day => singular 'day'");
const twoHeavy = flags(heavyStore(["2026-06-17", "2026-06-18"]), todayRef);
assert.ok(twoHeavy.some((f) => f.startsWith("Super heavy flow on 2 days this month")),
  "two super-heavy days => plural 'days'");
// A super-heavy day older than 35 days is out of the window.
const oldHeavy = flags(heavyStore(["2026-04-01"]), todayRef);
assert.ok(!oldHeavy.some((f) => f.startsWith("Super heavy flow")),
  "super-heavy older than ~35 days does not flag");

// The shared report — nurse voice, and zero em-dashes (v0.1.7 swept them out of
// the copy, so one creeping back in is a regression).
const empty = { logsSnapshot: [], periodDays: [], prediction: () => ({ hasHistory: false }) };
const summary = text(empty, new Date(2026, 5, 2));
assert.equal(summary.split("\n")[0], "CYCLE SUMMARY, prepared Jun 2, 2026");
assert.ok(summary.includes("THE NUMBERS") && summary.includes("FOR YOUR VISIT"));
assert.ok(!summary.includes("—"), "the report copy must carry no em-dashes");

console.log("report.test.mjs ok");
