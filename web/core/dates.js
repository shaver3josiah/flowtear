// Calendar helpers. Everything works on LOCAL-midnight dates and whole-day
// differences, mirroring Swift's Calendar.startOfDay / dateComponents([.day]).
// dateKeys are "yyyy-MM-dd" in the proleptic Gregorian calendar (en_US_POSIX),
// exactly like CycleStore.dateFmt, so keys round-trip identically to Swift.

const MS_DAY = 86400000;

export function startOfDay(d) {
  const x = new Date(d);
  x.setHours(0, 0, 0, 0);
  return x;
}

// Whole days from a -> b (b later => positive). Rounds to absorb DST 23/25h days,
// matching dateComponents([.day]).day which counts calendar-day boundaries.
export function daysBetween(a, b) {
  return Math.round((startOfDay(b) - startOfDay(a)) / MS_DAY);
}

export function addDays(d, n) {
  const x = startOfDay(d);
  x.setDate(x.getDate() + n);
  return x;
}

export function keyFromDate(d) {
  const x = startOfDay(d);
  const y = x.getFullYear();
  const m = String(x.getMonth() + 1).padStart(2, "0");
  const day = String(x.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

export function dateFromKey(key) {
  const [y, m, d] = key.split("-").map(Number);
  return new Date(y, m - 1, d, 0, 0, 0, 0); // local midnight
}

export const isSameDay = (a, b) => daysBetween(a, b) === 0;
