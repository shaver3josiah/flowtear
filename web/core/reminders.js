// FFReminders on the web — a port of App/Core/Reminders.swift over Capacitor's
// @capacitor/local-notifications. Opt-in local notifications, off by default:
// two gentle nudges — a daily stretch reminder at her chosen time, and a
// heads-up two days before the predicted period. Everything is scheduled
// on-device; nothing leaves the phone. Re-plan whenever settings change or the
// app comes to the front (so the period date tracks her latest logs).
//
// KEYS — identical to the Swift UserDefaults keys, so both builds read the same
// switches:
//   flowtear.remind.stretch         bool  "true" / "false"
//   flowtear.remind.stretchMinutes  int   minutes past midnight (default 18*60)
//   flowtear.remind.period          bool
//
// HONESTY — if she declined the OS permission (or revoked it later), the stored
// toggles flip back OFF, exactly like Swift: the switches never promise a
// reminder that can't fire. Re-read them after any refresh().
//
// NO BRIDGE (a plain desktop browser) — isAvailable() is false, every call is a
// quiet no-op and nothing throws. The settings sheet disables the switches.
//
// This module touches `window` only when called, never at import time.

import { available as bridgeAvailable, call as bridgeCall } from "./capacitor.js";

const PLUGIN = "LocalNotifications";

export const STRETCH_ON_KEY = "flowtear.remind.stretch";
export const STRETCH_MINUTES_KEY = "flowtear.remind.stretchMinutes";
export const PERIOD_ON_KEY = "flowtear.remind.period";

export const DEFAULT_STRETCH_MINUTES = 18 * 60; // 6pm, matching Swift

// Capacitor wants numeric ids where Swift uses strings ("flowtear.remind.*").
// Stable and ours alone — the app schedules nothing else.
const STRETCH_ID = 1001;
const PERIOD_ID = 1002;

// ---- storage (same tolerant bool read as web/core/store.js) ----

function read(key) {
  try {
    return typeof localStorage === "undefined" ? null : localStorage.getItem(key);
  } catch { return null; }
}
function write(key, value) {
  try {
    if (typeof localStorage !== "undefined") localStorage.setItem(key, value);
  } catch { /* private mode — the toggle just won't stick */ }
}
function readBool(key) {
  const v = read(key);
  return v === "true" || v === '"true"' || v === "1";
}

export function getStretchOn() { return readBool(STRETCH_ON_KEY); }
export function setStretchOn(on) { write(STRETCH_ON_KEY, on ? "true" : "false"); }

export function getPeriodOn() { return readBool(PERIOD_ON_KEY); }
export function setPeriodOn(on) { write(PERIOD_ON_KEY, on ? "true" : "false"); }

/// Minutes past midnight for the daily nudge (Swift default: 18*60).
export function getStretchMinutes() {
  const raw = read(STRETCH_MINUTES_KEY);
  if (raw == null || raw === "") return DEFAULT_STRETCH_MINUTES;  // Number(null) is 0 — midnight, not 6pm
  const n = Number(raw);
  return Number.isFinite(n) && n >= 0 && n < 24 * 60 ? n : DEFAULT_STRETCH_MINUTES;
}
export function setStretchMinutes(minutes) {
  write(STRETCH_MINUTES_KEY, String(Math.max(0, Math.min(24 * 60 - 1, Math.round(minutes)))));
}

// ---- the Capacitor bridge ----
// Hoisted to core/capacitor.js now that a third plugin consumer (core/share.js)
// showed up. See that file for why Capacitor.Plugins is never populated here.

/// True when local notifications can actually be scheduled here.
export function isAvailable() { return bridgeAvailable(PLUGIN); }

const call = (method, options = {}) => bridgeCall(PLUGIN, method, options);

// ---- planning ----

/// Re-plan both notifications from the current settings + the latest prediction.
/// Checks real permission first: if she declined (or revoked it in Android
/// settings), the stored toggles flip back OFF so the switches never lie.
export async function refresh(nextPeriodStart) {
  if (!isAvailable()) return;
  try {
    await call("cancel", { notifications: [{ id: STRETCH_ID }, { id: PERIOD_ID }] });
    const status = await call("checkPermissions");
    if (status?.display === "denied") {
      setStretchOn(false);
      setPeriodOn(false);
      return;
    }
    // 'prompt' / 'prompt-with-rationale' — never asked; requestThenRefresh() resolves it.
    if (status?.display !== "granted") return;
    await schedule(nextPeriodStart);
  } catch (e) {
    console.warn("Reminders: could not re-plan", e);
  }
}

async function schedule(nextPeriodStart) {
  const notifications = [];

  if (getStretchOn()) {
    const minutes = getStretchMinutes();
    notifications.push({
      id: STRETCH_ID,
      title: "A few gentle minutes, petal?",
      body: "Your stretches are ready — every pose grows the garden.",
      // `on` with hour+minute is Capacitor's daily calendar repeat — the same
      // shape as Swift's repeating UNCalendarNotificationTrigger.
      schedule: { on: { hour: Math.floor(minutes / 60), minute: minutes % 60 }, allowWhileIdle: true },
    });
  }

  if (getPeriodOn() && nextPeriodStart) {
    const fire = new Date(nextPeriodStart);
    fire.setDate(fire.getDate() - 2);
    fire.setHours(9, 0, 0, 0);
    if (fire.getTime() > Date.now()) {
      notifications.push({
        id: PERIOD_ID,
        title: "Your period is expected in 2 days",
        body: "A little heads-up so you can plan some extra kindness.",
        schedule: { at: fire, allowWhileIdle: true },
      });
    }
  }

  if (notifications.length) await call("schedule", { notifications });
}

/// Ask permission the first time a reminder is switched on, then re-plan.
/// If she declines, the toggles switch themselves back off — honest state.
export async function requestThenRefresh(nextPeriodStart) {
  if (!isAvailable()) return;
  let granted = false;
  try {
    granted = (await call("requestPermissions"))?.display === "granted";
  } catch (e) {
    console.warn("Reminders: permission request failed", e);
  }
  if (!granted) {
    setStretchOn(false);
    setPeriodOn(false);
  }
  await refresh(nextPeriodStart);
}
