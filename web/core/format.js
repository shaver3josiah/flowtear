// Copy + date formatting helpers. Voice mirrors the Flowtier design-system readme:
// warm, second-person, sentence case, no emoji. Keep new strings in that voice.
import { label } from "./models.js";
import { daysBetween, startOfDay } from "./dates.js";

const WEEKDAYS = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
const MONTHS = ["January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December"];
const MONTHS_SHORT = MONTHS.map((m) => m.slice(0, 3));
const WEEKDAYS_SHORT = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

export const weekday = (d) => WEEKDAYS[startOfDay(d).getDay()];
export const monthName = (d) => MONTHS[startOfDay(d).getMonth()];
export const monthShort = (i) => MONTHS_SHORT[i];
export const weekdayShort = (d) => WEEKDAYS_SHORT[startOfDay(d).getDay()];

// "Monday, July 13"
export const longDate = (d) => `${weekday(d)}, ${monthName(d)} ${startOfDay(d).getDate()}`;
// "Fri, Jul 29"
export const shortDate = (d) => `${weekdayShort(d)}, ${MONTHS_SHORT[d.getMonth()]} ${startOfDay(d).getDate()}`;

export function greeting(d = new Date()) {
  const h = new Date(d).getHours();
  const part = h < 12 ? "morning" : h < 18 ? "afternoon" : "evening";
  return `Good ${part}, love`;
}

// n days from today, worded gently. daysBetween(today, target).
export function daysPhrase(n) {
  if (n == null) return "";
  if (n === 0) return "today";
  if (n === 1) return "tomorrow";
  if (n === -1) return "yesterday";
  if (n > 1) return `in ${n} days`;
  return `${Math.abs(n)} days ago`;
}

export const phaseLabel = (p) => (p ? label(p) : "");
export const flowLabel = label;
export const moodLabel = label;
export const symptomLabel = label;
export const dischargeLabel = label;

export function daysUntil(today, target) {
  if (!target) return null;
  return daysBetween(today, target);
}

// °C stored -> shown in °F to one decimal (matches the sample seed, which is °F).
export const cToF = (c) => (c == null ? null : (c * 9) / 5 + 32);
export const fToC = (f) => (f == null ? null : ((f - 32) * 5) / 9);
