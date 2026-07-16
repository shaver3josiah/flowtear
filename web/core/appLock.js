// AppLock on the web — a port of App/Components/AppLock.swift over
// @aparajita/capacitor-biometric-auth. Optional privacy lock, off by default;
// toggled in the settings sheet. When on, the garden hides behind her
// fingerprint / face unlock / screen lock on cold launch and whenever the app
// has been backgrounded. If the phone has no biometrics AND no screen lock,
// there is nothing to lock behind, so the gate quietly stands down.
//
// KEY — "flowtear.appLock", identical to the Swift UserDefaults key.
//
// ── SHELL API ────────────────────────────────────────────────────────────────
// This module owns the state + the prompt; web/app.js owns the curtain UI.
//
//   isEnabled()      -> bool             she switched the lock on
//   setEnabled(on)   -> Promise<bool>    persists; resolves FALSE if it refused
//                                        (no biometrics/screen lock, or no bridge)
//                                        — nothing is stored on a false
//   isLocked()       -> bool             true on first read when the lock is on
//                                        (cold launch starts locked, like Swift)
//   lock()           -> void             call when the app leaves the foreground
//   unlock()         -> Promise<bool>    runs the prompt; false = cancelled/failed
//                                        (also false while a prompt is in flight)
//   subscribe(fn)    -> () => void       fn() fires on every lock/unlock/toggle
//   isAvailable()    -> Promise<bool>    biometrics enrolled, or a screen lock set
//
// Suggested wiring (mirrors AppLockGate's scenePhase logic):
//   const off = appLock.subscribe(rerender);
//   document.addEventListener("visibilitychange", () => {
//     if (document.hidden) { if (appLock.isEnabled()) appLock.lock(); }
//     else if (appLock.isLocked() && !parked) appLock.unlock().then(ok => parked = !ok);
//   });
//   if (appLock.isLocked()) appLock.unlock().then(ok => parked = !ok);
// Park on an "Unlock" button when unlock() resolves false instead of
// re-prompting in a loop — the system prompt itself flips visibility. Render the
// curtain above everything and aria-hide the content while isLocked().
//
// NO BRIDGE (a plain desktop browser) — isAvailable() resolves false,
// setEnabled(true) refuses, unlock() opens the garden rather than trapping her
// behind a prompt that can't run. Nothing throws.
//
// This module touches `window` only when called, never at import time.

import { available as bridgeAvailable, call as bridgeCall } from "./capacitor.js";

const PLUGIN = "BiometricAuthNative";

export const APP_LOCK_KEY = "flowtear.appLock";

let locked = null;          // lazily seeded from storage on first isLocked()
let authInFlight = false;
const subs = new Set();

// ---- storage ----

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

// ---- the Capacitor bridge ----
// Hoisted to core/capacitor.js now that a third plugin consumer (core/share.js)
// showed up. See that file for why Capacitor.Plugins is never populated here.

const hasPlugin = () => bridgeAvailable(PLUGIN);
const call = (method, options = {}) => bridgeCall(PLUGIN, method, options);

/// CheckBiometryResult, or null when there's no bridge / the call failed.
async function checkBiometry() {
  if (!hasPlugin()) return null;
  try { return await call("checkBiometry"); } catch { return null; }
}

// ---- state ----

export function subscribe(fn) {
  subs.add(fn);
  return () => subs.delete(fn);
}
function notify() { subs.forEach((f) => f()); }

export function isEnabled() {
  const v = read(APP_LOCK_KEY);
  return v === "true" || v === '"true"' || v === "1";
}

/// True when biometry is enrolled or the device has a PIN/pattern/password —
/// i.e. when there is something to lock behind. Matches Swift's
/// LAContext.canEvaluatePolicy(.deviceOwnerAuthentication) gate.
export async function isAvailable() {
  const b = await checkBiometry();
  return !!b && (!!b.isAvailable || !!b.deviceIsSecure);
}

/// Persist the toggle. Enabling FAILS HONESTLY (resolves false, stores nothing)
/// when there's nothing to lock behind — the switch never claims a lock the
/// phone can't enforce.
export async function setEnabled(on) {
  if (on && !(await isAvailable())) return false;
  write(APP_LOCK_KEY, on ? "true" : "false");
  if (!on) locked = false;
  notify();
  return true;
}

export function isLocked() {
  if (locked === null) locked = isEnabled();   // cold launch starts locked
  return locked;
}

export function lock() {
  if (!isEnabled()) return;
  locked = true;
  notify();
}

function setUnlocked() {
  locked = false;
  notify();
}

/// Run the biometric / device-credential prompt. Resolves true when the garden
/// should open — including when there's nothing to lock behind (Swift's "no
/// device passcode, nothing to lock behind" path).
export async function unlock() {
  if (authInFlight) return false;
  const b = await checkBiometry();
  if (!b || !(b.isAvailable || b.deviceIsSecure)) {
    setUnlocked();
    return true;
  }
  authInFlight = true;
  try {
    await call("internalAuthenticate", {
      reason: "Unlock your cycle data",
      androidTitle: "Your garden is private",
      androidSubtitle: "Unlock with your fingerprint, face or screen lock",
      cancelTitle: "Cancel",
      allowDeviceCredential: true,   // = Swift's .deviceOwnerAuthentication
    });
    setUnlocked();
    return true;
  } catch {
    return false;                    // cancelled or failed — park on the curtain
  } finally {
    authInFlight = false;
  }
}
