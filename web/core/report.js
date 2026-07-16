// CycleReport — a faithful port of App/Core/CycleReport.swift: a pre-prepared,
// shareable plain-text summary of her recent cycles, gentle flags when something
// changed or looks worth mentioning, and the whole calendar as a CSV.
// Worded to hand to a partner or clinician; never diagnostic.
//
// Pure module: no DOM, no window, no storage. `store` only needs the three reads
// Swift's CycleStore gives it — periodDays, prediction(today), logsSnapshot — so
// a plain object works in Node (see report.test.mjs).

import { periodStarts } from "./engine.js";
import { startOfDay, daysBetween } from "./dates.js";
import { cToF, monthShort } from "./format.js";

// Swift's DateFormatter with dateStyle .medium — "Jul 16, 2026".
const mediumDate = (d) => `${monthShort(d.getMonth())} ${d.getDate()}, ${d.getFullYear()}`;

// Swift's Set(periodDays.map(startOfDay)).sorted().
const uniqSortedDays = (dates) =>
  [...new Set(dates.map((d) => startOfDay(d).getTime()))].sort((a, b) => a - b).map((t) => new Date(t));

const ascending = (a, b) => a - b;

/** Things worth noting right now (empty = all quiet). */
export function flags(store, today = new Date()) {
  const out = [];
  const starts = periodStarts(store.periodDays).sort(ascending);

  // Cycle-length signals need at least two completed cycles.
  if (starts.length >= 2) {
    const gaps = [];
    for (let i = 1; i < starts.length; i++) gaps.push(daysBetween(starts[i - 1], starts[i]));
    const last = gaps[gaps.length - 1];
    if (last < 21) out.push(`Your last cycle was ${last} days — shorter than the typical 21–35 range.`);
    if (last > 35) out.push(`Your last cycle was ${last} days — longer than the typical 21–35 range.`);
    if (gaps.length >= 3) {
      const prior = gaps.slice(0, -1);
      const avgPrior = prior.reduce((a, b) => a + b, 0) / prior.length;
      const drift = Math.abs(last - avgPrior);
      if (drift >= 7) out.push(`Your last cycle differed from your usual by about ${Math.round(drift)} days.`);
    }
  }

  // Long bleed: longest run of consecutive bleeding days > 7.
  const bleedDays = uniqSortedDays(store.periodDays);
  let run = 1;
  let maxRecentRun = 0;
  for (let i = 1; i < bleedDays.length; i++) {
    run = daysBetween(bleedDays[i - 1], bleedDays[i]) === 1 ? run + 1 : 1;
    maxRecentRun = Math.max(maxRecentRun, run);
  }
  if (maxRecentRun > 7) {
    out.push(`A recent period ran ${maxRecentRun} days — longer than 7 is worth mentioning to a clinician.`);
  }

  // Overdue right now.
  const d = store.prediction(today).daysUntilNextPeriod;
  if (d != null && d < -3) out.push(`Your period is currently ${Math.abs(d)} days later than predicted.`);

  return out;
}

/** The full shareable text report. */
export function text(store, today = new Date()) {
  const p = store.prediction(today);
  const lines = [];
  lines.push(`MY CYCLE REPORT — ${mediumDate(today)}`);
  lines.push("—".repeat(28));

  if (p.hasHistory) {
    lines.push(`Average cycle: ${p.averageCycleLength} days · average period: ${p.averagePeriodLength} days`);
    if (p.lastPeriodStart) lines.push(`Last period started: ${mediumDate(p.lastPeriodStart)}`);
    if (p.nextPeriodStart) lines.push(`Next period expected: ${mediumDate(p.nextPeriodStart)} (estimate)`);
    const starts = periodStarts(store.periodDays).sort(ascending).slice(-6);
    if (starts.length >= 2) {
      const gaps = [];
      for (let i = 1; i < starts.length; i++) gaps.push(String(daysBetween(starts[i - 1], starts[i])));
      lines.push(`Recent cycle lengths: ${gaps.join(", ")} days`);
    }
  } else {
    lines.push("Not enough period days logged yet for cycle statistics.");
  }

  const notes = flags(store, today);
  lines.push("");
  if (notes.length === 0) {
    lines.push("NOTES: nothing unusual in the recent data.");
  } else {
    lines.push("WORTH MENTIONING:");
    for (const n of notes) lines.push(`• ${n}`);
  }
  lines.push("");
  lines.push("From my Uncorked tracker. Estimates, not medical advice.");
  return lines.join("\n");
}

export const CSV_HEADER = "date,flow,discharge,temp_f,temp_skipped,moods,symptoms,stretch_done,note";
export const CSV_FILENAME = "uncorked-cycle-data.csv"; // same name Swift's csvFile() writes

/** The whole calendar's data as a spreadsheet (CSV). */
export function csv(store) {
  const rows = [CSV_HEADER];
  const byDate = [...store.logsSnapshot].sort((a, b) =>
    a.dateKey < b.dateKey ? -1 : a.dateKey > b.dateKey ? 1 : 0);
  for (const log of byDate) {
    const tempF = log.temperatureC == null ? "" : cToF(log.temperatureC).toFixed(2);
    const moods = [...(log.moods ?? [])].sort().join("; ");
    const symptoms = [...(log.symptoms ?? [])].sort().join("; ");
    const note = (log.note ?? "").replaceAll('"', '""');
    rows.push([
      log.dateKey,
      log.flow ?? "",
      log.discharge ?? "",
      tempF,
      log.tempSkipped === true ? "yes" : "",
      `"${moods}"`,
      `"${symptoms}"`,
      log.stretchDone === true ? "yes" : "",
      `"${note}"`,
    ].join(","));
  }
  return rows.join("\n");
}
