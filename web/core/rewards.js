// The stretch-garden petal economy — a port of App/Core/RewardsStore.swift.
// Its OWN localStorage blob (with a backup copy kept before every write), kept
// entirely separate from the cycle history so spending never touches her logs.
// Lifetime only ever climbs; balance is what she spends. The keys mirror the
// Swift UserDefaults keys EXACTLY ("flowtear.rewards.v1" + ".backup") so the web
// build and the iOS build read the same saved garden.
//
// EARNING (multiplier applies to everything earned that day):
//   pose checked off            15
//   each pose after the first   +5
//   every pose in the day done  +10
//   first-ever guided pose      +30 (once per pose)
//   multiplier: Anytime x1 · 3-day starter x2 · full 14-day x4
//   flower lands on the period arc  +5 (once per calendar day)
//
// LOCK-INS: a missed plan day costs 5 petals, charged once per day. Lifetime is
// never touched. Days missed while her plan is paused are excused, not billed.

const K = {
  state: "flowtear.rewards.v1",
  backup: "flowtear.rewards.v1.backup",
};

// Ten flowers of rising rarity. Hand-drawn (never emoji — the DS forbids them in
// product UI); the web shop draws its own inline blooms, see garden.js.
export const FLOWERS = [
  { id: "daisy",     name: "Daisy",     price: 100,  rarity: "Common" },
  { id: "tulip",     name: "Tulip",     price: 250,  rarity: "Common" },
  { id: "blossom",   name: "Blossom",   price: 500,  rarity: "Sweet" },
  { id: "camellia",  name: "Camellia",  price: 800,  rarity: "Sweet" },
  { id: "rosette",   name: "Rosette",   price: 1200, rarity: "Lovely" },
  { id: "rose",      name: "Rose",      price: 1800, rarity: "Lovely" },
  { id: "hibiscus",  name: "Hibiscus",  price: 2600, rarity: "Rare" },
  { id: "sunflower", name: "Sunflower", price: 3600, rarity: "Rare" },
  { id: "lotus",     name: "Lotus",     price: 5000, rarity: "Precious" },
  { id: "bouquet",   name: "Red rose bouquet", price: 7500, rarity: "Precious" },
];

// Elegant little chimes — each a different mood of "well done". `systemID` is the
// iOS AudioServices sound the native app plays; the web has no such shelf, so
// `freq` is the WebAudio stand-in that keeps the three audibly distinct.
export const SOUNDS = [
  { id: "swoosh",   name: "Petal swoosh",  systemID: 1001, price: 800,  freq: 660 },
  { id: "songbird", name: "Songbird",      systemID: 1016, price: 1200, freq: 1046 },
  { id: "crystal",  name: "Crystal chime", systemID: 1025, price: 1600, freq: 880 },
];

export const PRICES = {
  posey: 10000,
  theme: 600,          // pink, peony, soft, light (cherry/rose/dark/midnight are free)
  accent: 1500,
  colorStudio: 4000,
  sound: 1200,         // legacy single-chime price; per-sound prices live in SOUNDS
  starterGift: 100,    // exactly a Daisy — her first unlock
};

// Both dark palettes stay free — dark is the house default, so choosing
// between the two dark moods must never sit behind a paywall of petals.
export const FREE_THEMES = ["cherry", "rose", "dark", "midnight"];
// The paid palettes, per the Swift comment on themePrice.
export const PAID_THEMES = ["pink", "peony", "soft", "light"];

export class RewardsStore {
  constructor() {
    this.balance = 0;
    this.lifetime = 0;
    this.guidedSeen = new Set();      // move names ever guided
    this.ownedFlowers = new Set();
    this.ownedThemes = new Set();
    this.accentUnlocked = false;
    this.colorStudioUnlocked = false;
    this.poseyOwned = false;
    this.ownedSounds = new Set();
    this.activeSound = null;
    this.penalizedDays = new Set();   // lock-in misses already charged
    this.periodLandDays = new Set();  // ring-landing bonuses already paid
    // Per-day stack of pose awards actually paid (newest last) — the ledger
    // revokePose refunds from, so award/refund stay symmetric across tier switches.
    this.poseAwardLog = {};           // { "YYYY-MM-DD": [amounts] }
    this.tutorialSeen = false;
    this.activeSticker = null;        // flower id or "posey"
    // Where her plucked sticker rests near the Today ring (offsets from the ring
    // center in units of the ring's track radius, so ~-1.4…1.4).
    this.stickerX = 0.78;
    this.stickerY = -0.72;
    this.stickerAngle = -0.9;         // resting angle on the ring (radians)
    this.stickerMode = "ring";        // "ring" (riding it) or "free" (plucked off)
    this._subs = new Set();
    this._load();
  }

  // ---- subscription (drives React re-renders) ----
  subscribe(fn) { this._subs.add(fn); return () => this._subs.delete(fn); }
  _notify() { this._subs.forEach((f) => f()); }

  // ---- catalog ----
  get catalog() { return FLOWERS; }
  flower(id) { return FLOWERS.find((f) => f.id === id) || null; }
  sound(id) { return SOUNDS.find((s) => s.id === id) || null; }

  // First open of the Stretch tab: mark the tutorial seen and gift exactly
  // enough petals for the Daisy, once ever.
  completeTutorialWithGift() {
    if (this.tutorialSeen) return;
    this.tutorialSeen = true;
    this._earn(PRICES.starterGift);
  }

  // Her chosen celebration sound, if she owns one. Quiet mode (pencil settings)
  // silences every celebration without touching which sound she owns or picked.
  playCelebrationIfOwned() {
    if (this._quiet()) return;
    const s = this.activeSound ? this.sound(this.activeSound) : null;
    if (s) this._play(s);
  }

  // Same key as Swift's @AppStorage("flowtear.quiet"); same tolerant bool read
  // as reminders.js. Read per call, never at import (Node-safe).
  _quiet() {
    try {
      if (typeof localStorage === "undefined") return false;
      const v = localStorage.getItem("flowtear.quiet");
      return v === "true" || v === '"true"' || v === "1";
    } catch { return false; }
  }

  soundOwned(id) { return this.ownedSounds.has(id); }

  // WebAudio stands in for the iOS system sounds; audio is a nicety, so a
  // failure here never breaks a purchase.
  _play(s) {
    try {
      const Ctx = typeof window === "undefined" ? null : (window.AudioContext || window.webkitAudioContext);
      if (!Ctx) return;
      const ac = new Ctx();
      const o = ac.createOscillator();
      const g = ac.createGain();
      o.type = "sine";
      o.frequency.value = s.freq;
      g.gain.setValueAtTime(0.0001, ac.currentTime);
      g.gain.exponentialRampToValueAtTime(0.18, ac.currentTime + 0.02);
      g.gain.exponentialRampToValueAtTime(0.0001, ac.currentTime + 0.34);
      o.connect(g).connect(ac.destination);
      o.start();
      o.stop(ac.currentTime + 0.35);
    } catch { /* ponytail: audio is optional garnish, never fatal */ }
  }

  // ---- earning ----

  // Points for checking ON a pose. Returns the points awarded (to celebrate).
  // Each award is also pushed onto the day's ledger so a later uncheck refunds
  // EXACTLY what was paid — even if she switches plan tiers in between.
  awardPose(dateKey, alreadyDone, total, multiplier) {
    let pts = 15;
    if (alreadyDone >= 1) pts += 5;                 // consecutive bonus
    if (alreadyDone + 1 === total) pts += 10;       // whole-day bonus
    const amount = pts * multiplier;
    (this.poseAwardLog[dateKey] ??= []).push(amount);
    this._earn(amount);
    return amount;
  }

  // Symmetric take-back when a pose is UNchecked: pop the day's last recorded
  // award (awards depend only on the checked COUNT, so a stack refunds the
  // right amount in every toggle order — no farming, no unfair drain). Days
  // checked before the ledger existed fall back to recomputing. Known,
  // accepted ceiling: the refund clamps at a zero balance, so spending
  // everything and then uncheck/recheck can mint back what the clamp ate —
  // she'd only be gaming herself, and never loses petals to it.
  revokePose(dateKey, remainingDone, total, wasFullDay, multiplier) {
    let refund;
    const log = this.poseAwardLog[dateKey];
    if (log && log.length > 0) {
      refund = log.pop();
      if (log.length === 0) delete this.poseAwardLog[dateKey];
    } else {
      let pts = 15;
      if (remainingDone >= 1) pts += 5;
      if (wasFullDay) pts += 10;
      refund = pts * multiplier;
    }
    this.balance = Math.max(0, this.balance - refund);
    this._save();
    this._notify();
  }

  // First-ever guided run of a pose: +30 (once per pose, ever).
  awardGuidedFirstTime(moveName, multiplier) {
    if (this.guidedSeen.has(moveName)) return 0;
    this.guidedSeen.add(moveName);
    const amount = 30 * multiplier;
    this._earn(amount);
    return amount;
  }

  // Easter egg: her flower settled on the period arc of the ring — +5, at most
  // once per calendar day.
  awardPeriodLanding(dateKey) {
    if (this.periodLandDays.has(dateKey)) return false;
    this.periodLandDays.add(dateKey);
    this._earn(5);
    return true;
  }

  // Lock-in: −5 petals for a missed plan day, charged at most once per day.
  // Lifetime is untouched — only the spendable balance feels it.
  penalizeMissedDay(dateKey) {
    if (this.penalizedDays.has(dateKey)) return false;
    this.penalizedDays.add(dateKey);
    this.balance = Math.max(0, this.balance - 5);
    this._save();
    this._notify();
    return true;
  }

  // Pause amnesty: mark a missed day handled WITHOUT charging it, so days
  // skipped while her plan is paused can never be billed later.
  excuseMissedDay(dateKey) {
    if (this.penalizedDays.has(dateKey)) return;
    this.penalizedDays.add(dateKey);
    this._save();
    this._notify();
  }

  _earn(amount) {
    this.balance += amount;
    this.lifetime += amount;
    this._save();
    this._notify();
  }

  // ---- spending ----
  canAfford(price) { return this.balance >= price; }

  owned(id) {
    if (id === "posey") return this.poseyOwned;
    return this.ownedFlowers.has(id);
  }

  buyFlower(id) {
    const f = this.flower(id);
    if (!f || this.ownedFlowers.has(id) || !this.canAfford(f.price)) return false;
    this.balance -= f.price;
    this.ownedFlowers.add(id);
    if (this.activeSticker == null) this.activeSticker = id;
    this._save();
    this._notify();
    return true;
  }

  buyPosey() {
    if (this.poseyOwned || !this.canAfford(PRICES.posey)) return false;
    this.balance -= PRICES.posey;
    this.poseyOwned = true;
    this.activeSticker = "posey";
    this._save();
    this._notify();
    return true;
  }

  themeOwned(name) {
    return FREE_THEMES.includes(name) || this.ownedThemes.has(name);
  }

  buyTheme(name) {
    if (this.themeOwned(name) || !this.canAfford(PRICES.theme)) return false;
    this.balance -= PRICES.theme;
    this.ownedThemes.add(name);
    this._save();
    this._notify();
    return true;
  }

  buyAccent() {
    if (this.accentUnlocked || !this.canAfford(PRICES.accent)) return false;
    this.balance -= PRICES.accent;
    this.accentUnlocked = true;
    this._save();
    this._notify();
    return true;
  }

  buySoundItem(id) {
    const s = this.sound(id);
    if (!s || this.ownedSounds.has(id) || !this.canAfford(s.price)) return false;
    this.balance -= s.price;
    this.ownedSounds.add(id);
    this.activeSound = id;
    if (!this._quiet()) this._play(s);   // hear it at once (unless quiet mode)
    this._save();
    this._notify();
    return true;
  }

  // Wear / take off a sound she owns; re-tapping the active one silences it.
  useSound(id) {
    if (!this.ownedSounds.has(id)) return;
    this.activeSound = this.activeSound === id ? null : id;
    this._save();
    this._notify();
    this.playCelebrationIfOwned();
  }

  buyColorStudio() {
    if (this.colorStudioUnlocked || !this.canAfford(PRICES.colorStudio)) return false;
    this.balance -= PRICES.colorStudio;
    this.colorStudioUnlocked = true;
    this._save();
    this._notify();
    return true;
  }

  // Equip / unequip a sticker (flower id or "posey"); re-tapping the worn one
  // takes it off. Mirrors the Swift `activeSticker` toggle in the shop.
  equip(id) {
    this.activeSticker = this.activeSticker === id ? null : id;
    this._save();
    this._notify();
  }

  setStickerPosition(x, y) {
    this.stickerX = x;
    this.stickerY = y;
    this._save();
    this._notify();
  }

  setStickerAngle(a) {
    this.stickerAngle = a;
    this._save();
    this._notify();
  }

  setStickerMode(mode) {
    this.stickerMode = mode;
    this._save();
    this._notify();
  }

  // ---- persistence (own blob + backup — never touches cycle data) ----
  // Sets serialize as arrays, matching Swift's JSONEncoder(Set) output so the
  // saved blob is byte-shape-compatible across platforms. `soundUnlocked` is
  // written as false forever: it is the legacy single-chime flag, kept in the
  // blob only so an older iOS build can still decode it.
  // The persisted shape — Swift's makeBlob(). Also what backupData() exports.
  _blob() {
    return {
      balance: this.balance,
      lifetime: this.lifetime,
      guidedSeen: [...this.guidedSeen],
      ownedFlowers: [...this.ownedFlowers],
      ownedThemes: [...this.ownedThemes],
      accentUnlocked: this.accentUnlocked,
      colorStudioUnlocked: this.colorStudioUnlocked,
      poseyOwned: this.poseyOwned,
      activeSticker: this.activeSticker,
      soundUnlocked: false,
      tutorialSeen: this.tutorialSeen,
      stickerX: this.stickerX,
      stickerY: this.stickerY,
      ownedSounds: [...this.ownedSounds],
      activeSound: this.activeSound,
      penalizedDays: [...this.penalizedDays],
      stickerAngle: this.stickerAngle,
      periodLandDays: [...this.periodLandDays],
      stickerMode: this.stickerMode,
      poseAwardLog: this.poseAwardLog,
    };
  }

  _save() {
    if (typeof localStorage === "undefined") return; // Node import / SSR: in-memory only
    const prev = localStorage.getItem(K.state);
    if (prev != null) localStorage.setItem(K.backup, prev);
    localStorage.setItem(K.state, JSON.stringify(this._blob()));
  }

  _load() {
    if (typeof localStorage === "undefined") return;
    for (const key of [K.state, K.backup]) {
      const data = localStorage.getItem(key);
      if (!data) continue;
      try {
        this._hydrate(JSON.parse(data));
        return;
      } catch { /* corrupt blob — try the backup next */ }
    }
  }

  // Split out so the round-trip self-check can exercise decoding + migration
  // without a localStorage.
  _hydrate(b) {
    this.balance = b.balance ?? 0;
    this.lifetime = b.lifetime ?? 0;
    this.guidedSeen = new Set(b.guidedSeen ?? []);
    this.ownedFlowers = new Set(b.ownedFlowers ?? []);
    this.ownedThemes = new Set(b.ownedThemes ?? []);
    this.accentUnlocked = !!b.accentUnlocked;
    this.colorStudioUnlocked = !!b.colorStudioUnlocked;
    this.poseyOwned = !!b.poseyOwned;
    this.activeSticker = b.activeSticker ?? null;
    this.tutorialSeen = !!b.tutorialSeen;
    this.stickerX = b.stickerX ?? 0.78;
    this.stickerY = b.stickerY ?? -0.72;
    this.ownedSounds = new Set(b.ownedSounds ?? []);
    this.activeSound = b.activeSound ?? null;
    this.penalizedDays = new Set(b.penalizedDays ?? []);
    this.stickerAngle = b.stickerAngle ?? -0.9;
    this.periodLandDays = new Set(b.periodLandDays ?? []);
    this.stickerMode = b.stickerMode ?? "ring";
    this.poseAwardLog = b.poseAwardLog ?? {};
    // Migrate the old single-chime unlock into the crystal chime.
    if (b.soundUnlocked === true && this.ownedSounds.size === 0) {
      this.ownedSounds.add("crystal");
      if (this.activeSound == null) this.activeSound = "crystal";
    }
  }

  // ---- backup & restore (the whole garden, portable) ----
  // Mirrors RewardsStore.backupData/isValidBackup/restore(from:). The web needs
  // no `hydrated` guard: _hydrate assigns plain fields (no didSet observers),
  // so nothing can rotate a half-restored blob into the .backup slot.

  /// The whole garden as one JSON string — the same shape the store persists.
  backupData() {
    return JSON.stringify(this._blob());
  }

  /// True when `text` is a decodable garden backup — checked WITHOUT touching
  /// the store, so a combined restore can be all-or-nothing across stores.
  /// The required keys mirror the Swift Blob's non-optional fields.
  static isValidBackup(text) {
    try {
      const b = JSON.parse(text);
      return typeof b.balance === "number" && typeof b.lifetime === "number"
        && Array.isArray(b.guidedSeen) && Array.isArray(b.ownedFlowers)
        && Array.isArray(b.ownedThemes)
        && typeof b.accentUnlocked === "boolean"
        && typeof b.colorStudioUnlocked === "boolean"
        && typeof b.poseyOwned === "boolean";
    } catch { return false; }
  }

  /// Replace the whole garden from a backup blob. Validates before touching
  /// anything; returns false (and changes nothing) if the data won't decode.
  restore(text) {
    if (!RewardsStore.isValidBackup(text)) return false;
    this._hydrate(JSON.parse(text));
    this._save();
    this._notify();
    return true;
  }
}

// Module singleton — one shared garden across every open of the shop. The
// constructor's _load() is guarded, so importing this module never touches
// window/localStorage (safe under `node --check` and a bare Node import).
export const rewards = new RewardsStore();
export default rewards;

// ---- self-check: `node web/core/rewards.js` (silent in the browser) ----
// Mirrors Tests/RewardsStoreTests.swift: the pose-award ledger must refund
// exactly what was paid (in any toggle order, across tier switches), penalties
// must charge a day at most once ever, and the whole garden must survive a
// backup → restore round trip.
if (import.meta.main) {
  const assert = (await import("node:assert")).default;
  const r = new RewardsStore();
  r.awardPose("2026-07-16", 0, 4, 2);         // 15 × 2
  r.awardPose("2026-07-16", 1, 4, 2);         // (15+5) × 2
  assert.equal(r.balance, 70, "earning");
  assert.equal(r.lifetime, 70, "lifetime");

  // LEDGER: tier switched ×2 → ×4 between check and uncheck — the refunds are
  // the ×2 amounts actually paid (40 then 30), never the ×4 recomputation.
  {
    const l = new RewardsStore();
    assert.equal(l.awardPose("2026-07-16", 0, 3, 2), 30, "first pose pays 15 × 2");
    assert.equal(l.awardPose("2026-07-16", 1, 3, 2), 40, "second pose pays (15+5) × 2");
    assert.equal(l.balance, 70, "ledger balance");
    l.revokePose("2026-07-16", 1, 3, false, 4);
    assert.equal(l.balance, 30, "refund is the recorded 40, not ×4");
    l.revokePose("2026-07-16", 0, 3, false, 4);
    assert.equal(l.balance, 0, "refund is the recorded 30, not ×4");
    assert.equal(l.poseAwardLog["2026-07-16"], undefined, "drained day leaves the ledger");

    // Days checked before the ledger existed have no entries — revoke falls
    // back to recomputing from the passed state instead of refunding 0.
    l.awardPeriodLanding("2026-07-01");        // +5 so there's balance to take
    assert.equal(l.balance, 5, "ring landing seeds the fallback check");
    l.revokePose("2026-07-15", 0, 3, false, 1);
    assert.equal(l.balance, 0, "pre-ledger day recomputes 15, clamped at zero");
  }

  // ACTIVATION ANCHOR (rewards-side contract): the plan accounting excuses
  // every day before the plan was chosen via excuseMissedDay — excusing never
  // charges, and permanently blocks a later penalize for that day.
  {
    const a = new RewardsStore();
    a._earn(20);
    a.excuseMissedDay("2026-07-01");           // a pre-activation day
    assert.equal(a.balance, 20, "anchored day is excused free of charge");
    assert.equal(a.penalizeMissedDay("2026-07-01"), false, "and can never be billed later");
    assert.equal(a.balance, 20, "not even after a re-run of the accounting");
  }

  // BACKUP round trip: the ledger survives, so refunds stay exact even after
  // she moves to a new phone.
  {
    const src = new RewardsStore();
    src.awardPose("2026-07-16", 0, 3, 2);
    src.awardPose("2026-07-16", 1, 3, 2);
    const blob = src.backupData();
    assert.equal(RewardsStore.isValidBackup(blob), true, "own backup validates");
    assert.equal(RewardsStore.isValidBackup("{nope"), false, "garbage rejected");
    assert.equal(RewardsStore.isValidBackup('{"a":1}'), false, "wrong shape rejected");

    const fresh = new RewardsStore();
    assert.equal(fresh.balance, 0, "fresh store proves the restore does the work");
    assert.equal(fresh.restore("{corrupt"), false, "corrupt restore refuses");
    assert.equal(fresh.balance, 0, "and changes nothing");
    assert.equal(fresh.restore(blob), true, "valid restore succeeds");
    assert.equal(fresh.balance, 70, "restored balance");
    fresh.revokePose("2026-07-16", 1, 3, false, 1);
    assert.equal(fresh.balance, 30, "restored ledger refunds the recorded 40, newest first");
  }

  assert.equal(r.buySoundItem("crystal"), false, "cannot afford the crystal chime");
  r._earn(1600 - r.balance);
  assert.equal(r.buySoundItem("crystal"), true, "buys the crystal chime");
  assert.equal(r.activeSound, "crystal", "new sound becomes active");
  assert.equal(r.balance, 0, "price left the balance");
  assert.equal(r.lifetime, 1600, "spending never touches lifetime");
  assert.equal(r.buySoundItem("crystal"), false, "never bought twice");

  r._earn(10);
  assert.equal(r.penalizeMissedDay("2026-07-15"), true, "lock-in charges once");
  assert.equal(r.penalizeMissedDay("2026-07-15"), false, "and only once");
  assert.equal(r.balance, 5, "−5 petals");
  assert.equal(r.lifetime, 1610, "penalty never touches lifetime");
  r.excuseMissedDay("2026-07-14");
  assert.equal(r.penalizeMissedDay("2026-07-14"), false, "an excused day can't be billed later");
  assert.equal(r.balance, 5, "amnesty costs nothing");

  assert.equal(r.awardPeriodLanding("2026-07-16"), true, "ring landing pays");
  assert.equal(r.awardPeriodLanding("2026-07-16"), false, "once per day");
  assert.equal(r.balance, 10, "+5 petals");

  // Legacy blob → the crystal chime, and a full round-trip of the new fields.
  const legacy = new RewardsStore();
  legacy._hydrate({ balance: 40, soundUnlocked: true, ownedFlowers: ["daisy"] });
  assert.deepEqual([...legacy.ownedSounds], ["crystal"], "legacy chime migrates");
  assert.equal(legacy.activeSound, "crystal", "and plays");
  assert.equal(legacy.stickerMode, "ring", "sticker defaults");
  assert.equal(legacy.stickerAngle, -0.9, "sticker angle default");

  const back = new RewardsStore();
  back._hydrate(JSON.parse(r.backupData()));
  assert.equal(back.balance, r.balance, "round-trip balance");
  assert.deepEqual([...back.penalizedDays].sort(), ["2026-07-14", "2026-07-15"], "round-trip lock-in days");
  assert.deepEqual([...back.ownedSounds], ["crystal"], "round-trip sounds");
  console.log("rewards.js self-check ok");
}
