// FFBackup on the web — a port of App/Core/Backup.swift. One portable file for
// everything she's made here: cycle history, settings, and the whole petal
// garden. Plain JSON with the two stores' own persisted blobs inside.
//
// CROSS-PLATFORM WIRE FORMAT — must match Swift's JSONEncoder exactly, so a
// backup written on Android restores on iOS and vice versa:
//   { "version": 1, "exportedAt": "<ISO-8601>", "cycle": "<base64>", "rewards": "<base64>" }
// Swift encodes the inner `Data` fields as BASE64 STRINGS (JSONEncoder's Data
// default) and dates as .iso8601. We do the same via btoa/atob over UTF-8.
//
// All-or-nothing restore: BOTH payloads are validated before EITHER store is
// touched, so a corrupt or half-truncated file can never leave the two sides
// inconsistent.

import { CycleStore } from "./store.js";
import { RewardsStore } from "./rewards.js";

export const BACKUP_VERSION = 1;

// UTF-8-safe base64 (btoa alone chokes on non-Latin1 — notes can hold anything).
const b64encode = (text) => {
  const bytes = new TextEncoder().encode(text);
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin);
};
const b64decode = (b64) => {
  const bin = atob(b64);
  const bytes = Uint8Array.from(bin, (c) => c.charCodeAt(0));
  return new TextDecoder().decode(bytes);
};

/// The backup file's name for today — same shape Swift's makeFile builds.
export function backupFilename(now = new Date()) {
  const y = now.getFullYear();
  const m = String(now.getMonth() + 1).padStart(2, "0");
  const d = String(now.getDate()).padStart(2, "0");
  return `Uncorked-backup-${y}-${m}-${d}.json`;
}

/// Serialize both stores into the portable backup JSON. Built AT CALL TIME so
/// what she saves is always current (Backup.swift's ShareItem promise).
export function makeBackup(store, rewards) {
  return JSON.stringify({
    version: BACKUP_VERSION,
    exportedAt: new Date().toISOString(),
    cycle: b64encode(store.backupData()),
    rewards: b64encode(rewards.backupData()),
  });
}

/// Restore both stores from a backup file's text — all-or-nothing. Returns
/// false (and changes nothing) on any invalid/corrupt input.
export function restoreBackup(text, store, rewards) {
  let file;
  try { file = JSON.parse(text); } catch { return false; }
  if (!file || typeof file.cycle !== "string" || typeof file.rewards !== "string") return false;
  let cycleText, rewardsText;
  try {
    cycleText = b64decode(file.cycle);
    rewardsText = b64decode(file.rewards);
  } catch { return false; }
  if (!CycleStore.isValidBackup(cycleText) || !RewardsStore.isValidBackup(rewardsText)) return false;
  return store.restore(cycleText) && rewards.restore(rewardsText);
}
