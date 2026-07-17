// Pure cycle-prediction math — a faithful port of App/Core/CycleEngine.swift.
// No DOM, no storage: same inputs -> same outputs as Swift, verified by
// contracts/cycle-vectors.json (npm run check:parity).
//
// Inputs are `periodDays` (Date[] of real bleeding days — light/medium/heavy;
// the store already excludes spotting), `today`, and settings.

import { startOfDay, daysBetween, addDays, isSameDay } from "./dates.js";

const round = (x) => Math.round(x); // positive lengths only; matches Swift .rounded()

// Collapse logged bleeding-days into period *start* dates. Consecutive or
// near-consecutive days are one period; a gap larger than `maxGap` empty days
// starts a new one. Returns starts ascending, deduped to day granularity.
export function periodStarts(periodDays, maxGap = 1) {
  const days = uniqSortedDays(periodDays);
  if (days.length === 0) return [];
  const starts = [days[0]];
  let prev = days[0];
  for (const day of days.slice(1)) {
    const gap = daysBetween(prev, day);
    if (gap > maxGap + 1) starts.push(day); // >maxGap empty days => new period
    prev = day;
  }
  return starts;
}

// Average of the most recent `recent` cycle lengths (gaps between starts).
export function averageCycleLength(starts, recent = 6, fallback) {
  if (starts.length < 2) return fallback;
  const sorted = [...starts].sort((a, b) => a - b);
  const gaps = [];
  for (let i = 1; i < sorted.length; i++) {
    const d = daysBetween(sorted[i - 1], sorted[i]);
    if (d > 0) gaps.push(d);
  }
  if (gaps.length === 0) return fallback;
  const window = gaps.slice(-recent);
  return round(window.reduce((a, b) => a + b, 0) / window.length);
}

// Average logged period length (contiguous bleeding-day runs).
export function averagePeriodLength(periodDays, fallback) {
  const days = uniqSortedDays(periodDays);
  if (days.length === 0) return fallback;
  const runs = [];
  let run = 1;
  for (let i = 1; i < days.length; i++) {
    const gap = daysBetween(days[i - 1], days[i]);
    if (gap === 1) run += 1;
    else { runs.push(run); run = 1; }
  }
  runs.push(run);
  return round(runs.reduce((a, b) => a + b, 0) / runs.length);
}

export function predict(periodDays, today, settings) {
  today = startOfDay(today);
  const starts = periodStarts(periodDays);
  // Her override wins over the logged averages when she's locked it in — BOTH
  // numbers, or the period stepper would be a placebo for anyone with logged
  // flow (CycleEngine.swift:78).
  const locked = settings.lockCycleLength ?? false;
  const avgCycle = locked
    ? settings.defaultCycleLength
    : averageCycleLength(starts, 6, settings.defaultCycleLength);
  const avgPeriod = locked
    ? settings.defaultPeriodLength
    : averagePeriodLength(periodDays, settings.defaultPeriodLength);

  const last = starts.length ? starts[starts.length - 1] : null;
  if (!last) {
    // No history yet — nothing to predict.
    return {
      averageCycleLength: avgCycle, averagePeriodLength: avgPeriod,
      lastPeriodStart: null, nextPeriodStart: null, ovulationDate: null,
      fertileStart: null, fertileEnd: null, cycleDay: null, phase: null,
      daysUntilNextPeriod: null, hasHistory: false,
    };
  }

  const next = addDays(last, avgCycle);
  const ovulation = addDays(next, -settings.lutealPhaseLength);
  // Fertile window: sperm survives ~5d before ovulation, egg ~1d after.
  const fertileStart = addDays(ovulation, -5);
  const fertileEnd = addDays(ovulation, 1);

  const cycleDay = daysBetween(last, today) + 1;
  const daysUntil = daysBetween(today, next);

  const phase = phaseOf({ today, periodLength: avgPeriod, fertileStart, fertileEnd, ovulation, cycleStart: last });

  return {
    averageCycleLength: avgCycle, averagePeriodLength: avgPeriod,
    lastPeriodStart: last, nextPeriodStart: next, ovulationDate: ovulation,
    fertileStart, fertileEnd,
    cycleDay: Math.max(cycleDay, 1), phase, daysUntilNextPeriod: daysUntil,
    hasHistory: true,
  };
}

function phaseOf({ today, periodLength, fertileStart, fertileEnd, ovulation, cycleStart }) {
  const periodEnd = addDays(cycleStart, periodLength - 1);
  if (today <= periodEnd) return "menstrual";
  if (isSameDay(today, ovulation)) return "ovulation";
  if (today >= fertileStart && today <= fertileEnd) return "fertile";
  if (today > fertileEnd) return "luteal";
  return "follicular";
}

function uniqSortedDays(dates) {
  const seen = new Set();
  const out = [];
  for (const d of dates) {
    const s = startOfDay(d);
    const t = s.getTime();
    if (!seen.has(t)) { seen.add(t); out.push(s); }
  }
  return out.sort((a, b) => a - b);
}
