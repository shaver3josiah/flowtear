// First-launch demo seed — a port of CycleStore.loadSampleData() (Swift:201-286).
// Three ~28-day cycles (starts at −74/−46/−18 days), 5-day periods, phase-patterned
// moods/symptoms/discharge, a biphasic basal-temperature curve, and luteal stretch
// sessions. Fully deterministic (no randomness) so it's stable across launches.

import { startOfDay, addDays, keyFromDate } from "./dates.js";
import { emptyLog } from "./models.js";

// Deterministic jitter — same integer math as Swift's j(offset, mod).
// offset ∈ [-90,0] so offset*2654435761 stays a safe integer (no overflow).
function j(offset, mod) {
  return Math.abs((offset * 2654435761) % Math.max(mod, 1));
}

export function buildSampleLogs() {
  const today = startOfDay(new Date());
  const out = {};
  const starts = [-74, -46, -18];
  const flows = ["medium", "heavy", "medium", "light", "spotting"];

  for (let offset = -90; offset <= 0; offset++) {
    const d = addDays(today, offset);
    if (d > today) continue;
    let start = null;
    for (const s of starts) if (s <= offset) start = s;
    if (start == null) continue;

    const cd = offset - start + 1; // 1-based cycle day
    const k = keyFromDate(d);
    const l = emptyLog(k);
    const moods = new Set();
    const symptoms = new Set();

    if (cd >= 1 && cd <= 5) l.flow = flows[cd - 1];

    // Symptoms by phase.
    if (cd >= 1 && cd <= 2) {
      symptoms.add("cramps"); symptoms.add("fatigue");
      if (j(offset, 3) === 0) symptoms.add("backache");
    } else if (cd >= 3 && cd <= 5) {
      if (j(offset, 2) === 0) symptoms.add("fatigue");
    } else if (cd >= 17 && cd <= 23) {
      if (j(offset, 3) !== 2) symptoms.add("bloating");
      if (j(offset, 2) === 0) symptoms.add("cravings");
      if (j(offset, 4) === 1) symptoms.add("tenderBreasts");
      if (j(offset, 5) === 2) symptoms.add("headache");
    } else if (cd >= 24 && cd <= 28) {
      symptoms.add("cramps");
      if (j(offset, 2) === 0) symptoms.add("bloating");
      if (j(offset, 3) === 1) symptoms.add("insomnia");
    } else {
      if (j(offset, 7) === 3) symptoms.add("acne");
    }

    // Moods by phase.
    if (cd >= 1 && cd <= 2) moods.add(j(offset, 2) === 0 ? "sad" : "tired");
    else if (cd >= 3 && cd <= 5) moods.add("calm");
    else if (cd >= 6 && cd <= 11) moods.add(j(offset, 2) === 0 ? "energized" : "happy");
    else if (cd >= 12 && cd <= 15) { moods.add("happy"); if (j(offset, 2) === 0) moods.add("energized"); }
    else if (cd >= 16 && cd <= 21) moods.add(j(offset, 3) === 0 ? "anxious" : "calm");
    else { moods.add(j(offset, 2) === 0 ? "irritable" : "sensitive"); if (j(offset, 3) === 1) moods.add("tired"); }

    // Discharge — dry after period, rising to egg-white at the fertile peak.
    if (cd >= 1 && cd <= 5) l.discharge = null;
    else if (cd >= 6 && cd <= 8) l.discharge = "dry";
    else if (cd >= 9 && cd <= 11) l.discharge = j(offset, 2) === 0 ? "sticky" : "creamy";
    else if (cd >= 12 && cd <= 13) l.discharge = "watery";
    else if (cd >= 14 && cd <= 15) l.discharge = "eggWhite";
    else if (cd >= 16 && cd <= 17) l.discharge = "creamy";
    else l.discharge = j(offset, 2) === 0 ? "sticky" : "dry";

    // Basal temperature (°F -> °C): ~97.3 follicular, ~+0.5 after ovulation (day 15).
    const baseF = cd <= 15 ? 97.3 : 97.9;
    const f = baseF + j(offset, 3) * 0.07;
    l.temperatureC = ((f - 32) * 5) / 9;

    // Stretch sessions through the luteal window (~2/3 of days done).
    if (cd >= 15 && j(offset, 3) !== 1) l.stretchDone = true;

    // Occasional notes.
    switch (j(offset, 11)) {
      case 0: if (cd <= 2) l.note = "Heat pack helped tonight."; break;
      case 1: if (cd >= 24) l.note = "Cramps eased after stretching."; break;
      case 2: if (cd >= 12 && cd <= 15) l.note = "Feeling great today."; break;
    }

    l.moods = [...moods];
    l.symptoms = [...symptoms];
    out[k] = l;
  }
  return out;
}
