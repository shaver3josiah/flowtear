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

const K = {
  state: "flowtear.rewards.v1",
  backup: "flowtear.rewards.v1.backup",
};

// Ten flowers of rising rarity. `emoji` is carried for parity with the Swift
// catalog; the web shop draws its own inline blooms (see garden.js).
export const FLOWERS = [
  { id: "daisy",     emoji: "🌼", name: "Daisy",     price: 100,  rarity: "Common" },
  { id: "tulip",     emoji: "🌷", name: "Tulip",     price: 250,  rarity: "Common" },
  { id: "blossom",   emoji: "🌸", name: "Blossom",   price: 500,  rarity: "Sweet" },
  { id: "camellia",  emoji: "💮", name: "Camellia",  price: 800,  rarity: "Sweet" },
  { id: "rosette",   emoji: "🏵️", name: "Rosette",   price: 1200, rarity: "Lovely" },
  { id: "rose",      emoji: "🌹", name: "Rose",      price: 1800, rarity: "Lovely" },
  { id: "hibiscus",  emoji: "🌺", name: "Hibiscus",  price: 2600, rarity: "Rare" },
  { id: "sunflower", emoji: "🌻", name: "Sunflower", price: 3600, rarity: "Rare" },
  { id: "lotus",     emoji: "🪷", name: "Lotus",     price: 5000, rarity: "Precious" },
  { id: "bouquet",   emoji: "🌹", name: "Red rose bouquet", price: 7500, rarity: "Precious" },
];

export const PRICES = {
  posey: 10000,
  theme: 600,          // pink, peony, soft, light (cherry/rose/dark are free)
  accent: 1500,
  colorStudio: 4000,
  sound: 1200,
  starterGift: 100,    // exactly a Daisy — her first unlock
};

export const FREE_THEMES = ["cherry", "rose", "dark"];
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
    this.soundUnlocked = false;
    this.tutorialSeen = false;
    this.activeSticker = null;        // flower id or "posey"
    this.stickerX = 0.78;             // normalized offsets around the Today ring
    this.stickerY = -0.72;
    this._subs = new Set();
    this._load();
  }

  // ---- subscription (drives React re-renders) ----
  subscribe(fn) { this._subs.add(fn); return () => this._subs.delete(fn); }
  _notify() { this._subs.forEach((f) => f()); }

  // ---- catalog ----
  get catalog() { return FLOWERS; }
  flower(id) { return FLOWERS.find((f) => f.id === id) || null; }

  // The emoji for the sticker she has equipped (Posey shows as her bloom).
  get activeStickerEmoji() {
    if (!this.activeSticker) return null;
    if (this.activeSticker === "posey") return "🌸";
    return this.flower(this.activeSticker)?.emoji ?? null;
  }

  // First open of the Stretch tab: mark the tutorial seen and gift exactly
  // enough petals for the Daisy, once ever.
  completeTutorialWithGift() {
    if (this.tutorialSeen) return;
    this.tutorialSeen = true;
    this._earn(PRICES.starterGift);
  }

  // The celebration chime, if she owns it. WebAudio stands in for the iOS system
  // sound; audio is a nicety, so a failure here never breaks a purchase.
  playCelebrationIfOwned() {
    if (!this.soundUnlocked) return;
    try {
      const Ctx = window.AudioContext || window.webkitAudioContext;
      if (!Ctx) return;
      const ac = new Ctx();
      const o = ac.createOscillator();
      const g = ac.createGain();
      o.type = "sine";
      o.frequency.value = 880;
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
  awardPose(alreadyDone, total, multiplier) {
    let pts = 15;
    if (alreadyDone >= 1) pts += 5;                 // consecutive bonus
    if (alreadyDone + 1 === total) pts += 10;       // whole-day bonus
    const amount = pts * multiplier;
    this._earn(amount);
    return amount;
  }

  // Symmetric take-back when a pose is UNchecked, so toggling can't farm points.
  revokePose(remainingDone, total, wasFullDay, multiplier) {
    let pts = 15;
    if (remainingDone >= 1) pts += 5;
    if (wasFullDay) pts += 10;
    this.balance = Math.max(0, this.balance - pts * multiplier);
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

  buySound() {
    if (this.soundUnlocked || !this.canAfford(PRICES.sound)) return false;
    this.balance -= PRICES.sound;
    this.soundUnlocked = true;
    this.playCelebrationIfOwned();
    this._save();
    this._notify();
    return true;
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

  // ---- persistence (own blob + backup — never touches cycle data) ----
  // Sets serialize as arrays, matching Swift's JSONEncoder(Set) output so the
  // saved blob is byte-shape-compatible across platforms.
  _save() {
    if (typeof localStorage === "undefined") return; // Node import / SSR: in-memory only
    const blob = {
      balance: this.balance,
      lifetime: this.lifetime,
      guidedSeen: [...this.guidedSeen],
      ownedFlowers: [...this.ownedFlowers],
      ownedThemes: [...this.ownedThemes],
      accentUnlocked: this.accentUnlocked,
      colorStudioUnlocked: this.colorStudioUnlocked,
      poseyOwned: this.poseyOwned,
      activeSticker: this.activeSticker,
      soundUnlocked: this.soundUnlocked,
      tutorialSeen: this.tutorialSeen,
      stickerX: this.stickerX,
      stickerY: this.stickerY,
    };
    const prev = localStorage.getItem(K.state);
    if (prev != null) localStorage.setItem(K.backup, prev);
    localStorage.setItem(K.state, JSON.stringify(blob));
  }

  _load() {
    if (typeof localStorage === "undefined") return;
    for (const key of [K.state, K.backup]) {
      const data = localStorage.getItem(key);
      if (!data) continue;
      try {
        const b = JSON.parse(data);
        this.balance = b.balance ?? 0;
        this.lifetime = b.lifetime ?? 0;
        this.guidedSeen = new Set(b.guidedSeen ?? []);
        this.ownedFlowers = new Set(b.ownedFlowers ?? []);
        this.ownedThemes = new Set(b.ownedThemes ?? []);
        this.accentUnlocked = !!b.accentUnlocked;
        this.colorStudioUnlocked = !!b.colorStudioUnlocked;
        this.poseyOwned = !!b.poseyOwned;
        this.activeSticker = b.activeSticker ?? null;
        this.soundUnlocked = !!b.soundUnlocked;
        this.tutorialSeen = !!b.tutorialSeen;
        this.stickerX = b.stickerX ?? 0.78;
        this.stickerY = b.stickerY ?? -0.72;
        return;
      } catch { /* corrupt blob — try the backup next */ }
    }
  }
}

// Module singleton — one shared garden across every open of the shop. The
// constructor's _load() is guarded, so importing this module never touches
// window/localStorage (safe under `node --check` and a bare Node import).
export const rewards = new RewardsStore();
export default rewards;
