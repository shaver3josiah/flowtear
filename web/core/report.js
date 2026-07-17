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
    if (last < 21) out.push(`Your last cycle ran ${last} days. Most run 21 to 35, so that one was short.`);
    if (last > 35) out.push(`Your last cycle ran ${last} days, a little past the usual 21 to 35. One long cycle is common. A pattern of them is worth raising at a visit.`);
    if (gaps.length >= 3) {
      const prior = gaps.slice(0, -1);
      const avgPrior = prior.reduce((a, b) => a + b, 0) / prior.length;
      const drift = Math.abs(last - avgPrior);
      if (drift >= 7) out.push(`Your last cycle was about ${Math.round(drift)} days off your usual rhythm.`);
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
    out.push(`One recent period lasted ${maxRecentRun} days. Bleeding past 7 days is something a clinician would want to hear about.`);
  }

  // Overdue right now.
  const d = store.prediction(today).daysUntilNextPeriod;
  if (d != null && d < -3) out.push(`Your period is running ${Math.abs(d)} days later than expected.`);

  return out;
}

/**
 * The full shareable text report, written the way a good nurse would talk you
 * through it: plain sentences, the numbers first, then anything worth bringing
 * up, and honest about what an estimate is.
 */
export function text(store, today = new Date()) {
  const p = store.prediction(today);
  const lines = [];
  lines.push(`CYCLE SUMMARY, prepared ${mediumDate(today)}`);
  lines.push("-".repeat(30));

  lines.push("");
  lines.push("THE NUMBERS");
  if (p.hasHistory) {
    lines.push(`Average cycle: ${p.averageCycleLength} days. Average period: ${p.averagePeriodLength} days.`);
    if (p.lastPeriodStart) lines.push(`The last period started ${mediumDate(p.lastPeriodStart)}.`);
    if (p.nextPeriodStart) lines.push(`The next one is expected around ${mediumDate(p.nextPeriodStart)}. That date is an estimate.`);
    const starts = periodStarts(store.periodDays).sort(ascending).slice(-6);
    if (starts.length >= 2) {
      const gaps = [];
      for (let i = 1; i < starts.length; i++) gaps.push(String(daysBetween(starts[i - 1], starts[i])));
      lines.push(`Recent cycle lengths: ${gaps.join(", ")} days.`);
    }
  } else {
    lines.push("There isn't enough logged yet for cycle statistics. A month or two of notes will fill this in.");
  }

  const notes = flags(store, today);
  lines.push("");
  lines.push("FOR YOUR VISIT");
  if (notes.length === 0) {
    lines.push("Nothing out of the ordinary in the recent notes. Things look steady.");
  } else {
    for (const n of notes) lines.push(`• ${n}`);
  }
  lines.push("");
  lines.push("Prepared from the daily logs in this cycle tracker. These are estimates to talk over with a clinician, not a diagnosis.");
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
