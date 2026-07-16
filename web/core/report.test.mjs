// Self-check for the CSV builder. Run: node web/core/report.test.mjs
// Expectations are hand-written from CycleReport.swift's csv(store:) — column
// order, the quoted moods/symptoms/note fields, "" escaping, %.2f °F, and the
// dateKey sort. A broken port fails loudly here.
import assert from "node:assert";
import { csv, CSV_HEADER, CSV_FILENAME } from "./report.js";

const store = {
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
  '2026-06-01,,,,yes,"","",,""',
  '2026-06-02,medium,creamy,98.33,,"happy; sad","cramps",yes,"she said ""ow"""',
]);

assert.equal(CSV_HEADER, "date,flow,discharge,temp_f,temp_skipped,moods,symptoms,stretch_done,note");
assert.equal(CSV_FILENAME, "uncorked-cycle-data.csv");
assert.equal(csv({ logsSnapshot: [] }), CSV_HEADER); // header-only, never empty

console.log("report.test.mjs ok");
