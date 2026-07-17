// Domain vocabulary — a 1:1 mirror of App/Core/CycleModels.swift.
// Kept dead simple so the web and Swift enums stay obviously in sync.
// If you add a case here, add it in CycleModels.swift too (and bump contracts).

export const FLOW = ["spotting", "light", "medium", "heavy", "superHeavy"];
// Relative bleeding weight, also the y-value on the monthly flow chart.
// CRITICAL: cycle math only counts weight >= 2 (light and up). Spotting (1)
// logs + shows on the calendar but must never open a period start — see
// store.periodDays and CycleStore.swift:120-128.
export const FLOW_WEIGHT = { spotting: 1, light: 2, medium: 3, heavy: 4, superHeavy: 5 };

export const MOODS = ["happy", "calm", "sensitive", "sad", "irritable", "anxious", "energized", "tired"];

export const SYMPTOMS = [
  "cramps", "headache", "bloating", "tenderBreasts", "backache", "fatigue",
  "acne", "cravings", "nausea", "insomnia", "diarrhea", "constipation",
];

// Cervical fluid, ordered dry -> egg-white (the fertility signal).
export const DISCHARGE = ["dry", "sticky", "creamy", "watery", "eggWhite"];

export const PHASES = ["menstrual", "follicular", "fertile", "ovulation", "luteal"];

const SPECIAL_LABELS = { tenderBreasts: "Tender breasts", eggWhite: "Egg white", superHeavy: "Super heavy" };
export const label = (raw) =>
  SPECIAL_LABELS[raw] ?? (raw ? raw[0].toUpperCase() + raw.slice(1) : "");

// Defaults used until enough history exists (CycleSettings).
export const DEFAULT_SETTINGS = {
  defaultCycleLength: 28,
  defaultPeriodLength: 5,
  lutealPhaseLength: 14, // ovulation ≈ nextPeriod − luteal
  // When true, predictions use HER numbers (defaultCycleLength/PeriodLength)
  // instead of the logged averages — for thin or irregular history she knows
  // better than the math does. Nullable so old persisted blobs keep decoding.
  lockCycleLength: false,
};

// An empty DayLog for `dateKey`. Mirrors DayLog's fields; Sets are arrays in JSON
// (Swift encodes Set<Enum> as a JSON array of rawValues — same on the wire).
export function emptyLog(dateKey) {
  return {
    dateKey,
    flow: null,
    moods: [],
    symptoms: [],
    note: "",
    temperatureC: null,
    stretchDone: null,
    discharge: null,
    tempSkipped: null,
    stretchMovesDone: null, // array of move indices, or null
  };
}

// Matches DayLog.isEmpty exactly — an empty log is deleted, not stored.
export function isEmptyLog(l) {
  return (
    l.flow == null &&
    (l.moods?.length ?? 0) === 0 &&
    (l.symptoms?.length ?? 0) === 0 &&
    (!l.note || l.note.length === 0) &&
    l.temperatureC == null &&
    (l.stretchDone ?? false) === false &&
    l.discharge == null &&
    (l.tempSkipped ?? false) === false &&
    (l.stretchMovesDone?.length ?? 0) === 0
  );
}

export const isPeriod = (l) => l.flow != null;
