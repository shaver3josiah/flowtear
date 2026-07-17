// The settings sheet — a port of App/Components/ThemeEditorSheet.swift. Pick a
// full palette preset, lay a custom accent color over it, recolor nearly
// everything in the Color Studio, then her gentle reminders and the privacy
// lock. Cycle-phase and flow colors stay fixed — they carry meaning.
//
// The shell owns the active preset (data-theme on <html>, via nav.theme /
// nav.setTheme). The accent + studio overrides ride ON TOP as inline custom
// properties on <html>, which beat the [data-theme] rules in tokens.css — the
// same merge order as Swift's Theme.buildTokens (preset -> accent -> studio).
// applyStoredTheming() runs at import so the overrides are on before first
// paint (app.js imports every screen eagerly); call it from the shell instead if
// screens ever load lazily.
//
// Persistence keys match Swift's UserDefaults exactly:
//   flowtear.theme.accent    "#RRGGBB"          Theme.accentKey
//   flowtear.theme.studio    { token: "#RRGGBB" } Theme.studioKey
//   flowtear.petalsOnRing    bool (default on)
//   flowtear.quiet           bool (default off) — rewards.js reads it before
//                            playing a celebration sound

import { rewards, PRICES } from "../core/rewards.js";
import * as remind from "../core/reminders.js";
import * as appLock from "../core/appLock.js";

const { useState, useEffect } = window.React;

const ACCENT_KEY = "flowtear.theme.accent";
const STUDIO_KEY = "flowtear.theme.studio";
const PETALS_KEY = "flowtear.petalsOnRing";
const QUIET_KEY = "flowtear.quiet";
const PRESET_KEY = "flowtear.theme.preset";   // Theme.presetKey — the shell owns writes

// Every preset Theme.swift ships, in Swift's order (Theme.presetNames): the
// dark family first — Plum Night is the house default — then the lights.
// Ownership is NOT encoded here; it's asked of rewards.themeOwned() live.
const PRESETS = [
  { id: "dark", label: "Plum Night" },
  { id: "midnight", label: "Midnight" },
  { id: "cherry", label: "Cherry" },
  { id: "pink", label: "Pink" },
  { id: "rose", label: "Rose" },
  { id: "peony", label: "Peony" },
  { id: "soft", label: "Soft" },
  { id: "light", label: "Light" },
];

// Theme.darkPresets — the accent ramp scales differently on a dark scheme.
const DARK_PRESETS = ["dark", "midnight"];

// Swift's Theme.studioTokens (Tok raw value) -> the CSS custom property + label.
const STUDIO_TOKENS = [
  ["bg", "--bg", "Background"],
  ["surface", "--surface", "Cards"],
  ["surfaceSoft", "--surface-soft", "Soft fills"],
  ["surface2", "--surface-2", "Accent panels"],
  ["text", "--text", "Text"],
  ["muted", "--muted", "Soft text"],
  ["line", "--line", "Hairlines"],
  ["flowerCenter", "--flower-center", "Gold accents"],
  ["good", "--good", "Success green"],
  ["phaseLuteal", "--phase-luteal", "Stretch lavender"],
];

// ---- storage ----

function read(key) {
  try { return typeof localStorage === "undefined" ? null : localStorage.getItem(key); }
  catch { return null; }
}
function write(key, value) {
  try {
    if (typeof localStorage === "undefined") return;
    if (value == null) localStorage.removeItem(key);
    else localStorage.setItem(key, value);
  } catch { /* private mode — it just won't stick */ }
}
const readPetals = () => read(PETALS_KEY) !== "false";   // Swift's @AppStorage default: true
const readQuiet = () => read(QUIET_KEY) === "true";      // Swift's @AppStorage default: false
const readStudio = () => { try { return JSON.parse(read(STUDIO_KEY) || "{}") || {}; } catch { return {}; } };

// ---- the custom-accent ramp (a port of Theme.accentRamp) ----
// Derive primary / primaryStrong / deep from one picked color, scaled by
// scheme. On light: strong is darker, deep darker still (contrast on white).
// On dark: strong is brighter, deep light (contrast on near-black).

const clamp01 = (n) => Math.min(Math.max(n, 0), 1);

function parseHex(hex) {
  const s = String(hex || "").trim().replace(/^#/, "");
  if (!/^[0-9a-fA-F]{6}$/.test(s)) return null;
  const v = parseInt(s, 16);
  return { r: ((v >> 16) & 255) / 255, g: ((v >> 8) & 255) / 255, b: (v & 255) / 255 };
}

function rgbToHsv({ r, g, b }) {
  const max = Math.max(r, g, b), min = Math.min(r, g, b), d = max - min;
  let h = 0;
  if (d) {
    if (max === r) h = ((g - b) / d) % 6;
    else if (max === g) h = (b - r) / d + 2;
    else h = (r - g) / d + 4;
    h /= 6;
    if (h < 0) h += 1;
  }
  return { h, s: max ? d / max : 0, v: max };
}

function hsvToHex(h, s, v) {
  const f = (n) => {
    const k = (n + h * 6) % 6;
    const c = v - v * s * Math.max(0, Math.min(k, 4 - k, 1));
    return Math.round(clamp01(c) * 255).toString(16).padStart(2, "0").toUpperCase();
  };
  return `#${f(5)}${f(3)}${f(1)}`;
}

function accentRamp(hex, dark) {
  const rgb = parseHex(hex);
  if (!rgb) return null;
  const { h, s, v } = rgbToHsv(rgb);
  const mk = (ss, vv) => hsvToHex(h, clamp01(ss), clamp01(vv));
  if (dark) {
    return {
      "--primary": mk(s * 0.95, Math.min(v * 1.05, 1)),
      "--primary-strong": mk(s * 0.90, Math.min(v * 1.18, 1)),
      "--deep": mk(Math.max(s * 0.55, 0.18), Math.max(v * 1.40, 0.82)),
    };
  }
  return {
    "--primary": mk(Math.min(s * 1.02, 1), v),
    "--primary-strong": mk(Math.min(s * 1.14, 1), v * 0.84),
    "--deep": mk(Math.min(s * 1.18, 1), Math.min(v * 0.55, 0.48)),
  };
}

/// Lay the saved accent + studio overrides onto <html>. Idempotent: it clears
/// what it set first, so it doubles as the reset. `preset` names the palette
/// the ramp is built for; when omitted it reads the live data-theme attribute
/// (falling back to the stored preset — at import time the shell hasn't set
/// the attribute yet).
export function applyStoredTheming(preset) {
  if (typeof document === "undefined") return;
  const root = document.documentElement;
  const active = preset || root.getAttribute("data-theme") || read(PRESET_KEY) || "dark";
  const ramp = accentRamp(read(ACCENT_KEY), DARK_PRESETS.includes(active));
  for (const cssVar of ["--primary", "--primary-strong", "--deep"]) {
    if (ramp) root.style.setProperty(cssVar, ramp[cssVar]);
    else root.style.removeProperty(cssVar);
  }
  const studio = readStudio();
  for (const [tok, cssVar] of STUDIO_TOKENS) {
    if (studio[tok]) root.style.setProperty(cssVar, studio[tok]);
    else root.style.removeProperty(cssVar);
  }
}

applyStoredTheming();

/// The live value of a CSS custom property, as an <input type="color"> wants it.
function currentColor(cssVar) {
  if (typeof document === "undefined") return "#000000";
  const v = getComputedStyle(document.documentElement).getPropertyValue(cssVar).trim();
  return /^#[0-9a-fA-F]{6}$/.test(v) ? v : "#000000";
}

// Re-render on any rewards change (unlocks are bought in the garden shop).
function useRewards() {
  const [, force] = useState(0);
  useEffect(() => rewards.subscribe(() => force((n) => n + 1)), []);
  return rewards;
}

export default function ThemeEditor({ ctx }) {
  const { html, ui, Icon, nav, store, today } = ctx;
  const { Card, Button, IconButton, Switch } = ui;
  const r = useRewards();

  const [petals, setPetals] = useState(readPetals);
  const [quiet, setQuiet] = useState(readQuiet);
  const [stretchOn, setStretchOn] = useState(remind.getStretchOn);
  const [stretchMinutes, setStretchMins] = useState(remind.getStretchMinutes);
  const [periodOn, setPeriodOn] = useState(remind.getPeriodOn);
  const [lockOn, setLockOn] = useState(appLock.isEnabled);
  const [lockAvailable, setLockAvailable] = useState(null);   // null = still asking
  const [, forcePaint] = useState(0);                          // color inputs re-read the vars

  const remindersAvailable = remind.isAvailable();

  useEffect(() => {
    let dead = false;
    appLock.isAvailable().then((ok) => { if (!dead) setLockAvailable(ok); });
    return () => { dead = true; };
  }, []);

  // Re-plan on every change, then re-read the switches: a declined permission
  // flips them back off and the UI must show that, not a lie.
  const replan = async (justEnabled) => {
    const next = store.prediction(today).nextPeriodStart;
    if (justEnabled) await remind.requestThenRefresh(next);
    else await remind.refresh(next);
    setStretchOn(remind.getStretchOn());
    setPeriodOn(remind.getPeriodOn());
  };

  const setTheming = (fn) => { fn(); applyStoredTheming(); forcePaint((n) => n + 1); };

  const sectionTitle = (t) => html`<div style=${{ fontSize: 16, fontWeight: 600, color: "var(--deep)" }}>${t}</div>`;
  const section = (title, ...children) => html`<div style=${{ display: "grid", gap: 12 }}>
    ${sectionTitle(title)}${children}
  </div>`;
  const note = (t) => html`<div style=${{ fontSize: 11, color: "var(--muted)", lineHeight: 1.5 }}>${t}</div>`;

  // A row of title + subtitle with a trailing control — Swift's HStack card body.
  const toggleRow = (title, subtitle, control) => html`<div style=${{ display: "flex", alignItems: "center", gap: 10 }}>
    <div style=${{ flex: 1, display: "grid", gap: 2 }}>
      <div style=${{ fontSize: 16, fontWeight: 600, color: "var(--text)" }}>${title}</div>
      <div style=${{ fontSize: 12, color: "var(--muted)", lineHeight: 1.4 }}>${subtitle}</div>
    </div>
    ${control}
  </div>`;

  // ---- palette ----
  // The swatch borrows the preset's own --primary by wearing its data-theme
  // attribute: tokens.css scopes the presets by attribute, not by :root only.
  const presetChip = (p) => {
    const selected = nav.theme === p.id;
    const owned = r.themeOwned(p.id);
    return html`<button key=${p.id}
      aria-pressed=${selected}
      aria-label=${`${p.label} palette${owned ? "" : `, locked, ${PRICES.theme} petals`}`}
      onClick=${() => {
        if (!owned) return nav.open("garden");
        nav.setTheme(p.id);
        applyStoredTheming(p.id);   // rebuild the accent ramp for the new scheme
      }}
      style=${{
        display: "flex", alignItems: "center", gap: 8, height: 44, padding: "0 12px",
        borderRadius: 16, cursor: "pointer", textAlign: "left",
        background: selected ? "var(--surface-soft)" : "var(--surface)",
        border: `${selected ? 1.5 : 1}px solid ${selected ? "var(--primary-strong)" : "var(--line)"}`,
      }}>
      <span data-theme=${p.id} style=${{
        width: 18, height: 18, borderRadius: 999, flex: "0 0 auto",
        background: "var(--primary)", border: "1px solid var(--line)",
      }} />
      <span style=${{ flex: 1, fontWeight: 600, fontSize: 13, color: selected ? "var(--deep)" : "var(--text)" }}>${p.label}</span>
      ${selected
        ? html`<${Icon} name="check" size=${12} color="var(--primary-strong)" />`
        : !owned && html`<span style=${{
            display: "inline-flex", alignItems: "center", gap: 3, fontSize: 11, fontWeight: 700,
            color: r.canAfford(PRICES.theme) ? "var(--deep)" : "var(--muted)",
          }}>
            <${Icon} name="sparkles" size=${11} color="var(--flower-center)" />${PRICES.theme}
          </span>`}
    </button>`;
  };

  // ---- your color ----
  const accentSection = () => {
    if (!r.accentUnlocked) {
      return section("Your color", html`<${Card} variant="outline">
        ${toggleRow(
          "Custom accent color",
          "Unlock with petal points from stretching",
          html`<button onClick=${() => nav.open("garden")} style=${{
            display: "inline-flex", alignItems: "center", gap: 4, padding: "6px 12px", borderRadius: 999,
            border: "none", background: "var(--surface-soft)", cursor: "pointer", fontWeight: 700, fontSize: 12,
            color: r.canAfford(PRICES.accent) ? "var(--deep)" : "var(--muted)",
          }}>
            <${Icon} name="sparkles" size=${12} color="var(--flower-center)" />${PRICES.accent}
          </button>`,
        )}
      </${Card}>`);
    }
    const saved = read(ACCENT_KEY);
    return section("Your color", html`<${Card}>
      <div style=${{ display: "grid", gap: 12 }}>
        ${toggleRow(
          "Accent",
          "Recolors buttons, highlights and the bloom",
          html`<input type="color" aria-label="Accent color"
            value=${saved && parseHex(saved) ? saved : currentColor("--primary")}
            onChange=${(e) => setTheming(() => write(ACCENT_KEY, e.target.value.toUpperCase()))}
            style=${{ width: 44, height: 44, padding: 0, border: "1px solid var(--line)", borderRadius: 12, background: "none", cursor: "pointer" }} />`,
        )}
        ${saved && html`<${Button} variant="ghost" size="sm" iconLeft=${html`<${Icon} name="arrow-left" size=${14} />`}
          onClick=${() => setTheming(() => write(ACCENT_KEY, null))}>Back to the palette's own color<//>`}
      </div>
    </${Card}>`);
  };

  // ---- color studio ----
  const studio = readStudio();
  const studioSection = () => !r.colorStudioUnlocked ? null : section("Color Studio", html`<${Card}>
    <div style=${{ display: "grid", gap: 8 }}>
      ${STUDIO_TOKENS.map(([tok, cssVar, label]) => html`<div key=${tok}
        style=${{ display: "flex", alignItems: "center", gap: 10 }}>
        <span style=${{ flex: 1, fontSize: 13, fontWeight: 500, color: "var(--text)" }}>${label}</span>
        <input type="color" aria-label=${label} value=${studio[tok] || currentColor(cssVar)}
          onChange=${(e) => setTheming(() => {
            write(STUDIO_KEY, JSON.stringify({ ...readStudio(), [tok]: e.target.value.toUpperCase() }));
          })}
          style=${{ width: 40, height: 32, padding: 0, border: "1px solid var(--line)", borderRadius: 10, background: "none", cursor: "pointer" }} />
      </div>`)}
      ${Object.keys(studio).length > 0 && html`<${Button} variant="ghost" size="sm"
        iconLeft=${html`<${Icon} name="arrow-left" size=${14} />`}
        onClick=${() => setTheming(() => write(STUDIO_KEY, null))}>Reset the studio<//>`}
    </div>
  </${Card}>`);

  // ---- reminders ----
  const hhmm = `${String(Math.floor(stretchMinutes / 60)).padStart(2, "0")}:${String(stretchMinutes % 60).padStart(2, "0")}`;

  const remindersSection = () => section("Gentle reminders", html`<${Card}>
    <div style=${{ display: "grid", gap: 12 }}>
      ${toggleRow(
        "Stretch nudge",
        "One soft daily reminder at your time",
        html`<${Switch} checked=${stretchOn} disabled=${!remindersAvailable}
          label="Daily stretch reminder"
          onChange=${(next) => { setStretchOn(next); remind.setStretchOn(next); replan(next); }} />`,
      )}
      ${stretchOn && html`<div style=${{ display: "flex", alignItems: "center", gap: 10 }}>
        <label for="remind-at" style=${{ flex: 1, fontSize: 13, fontWeight: 500, color: "var(--text)" }}>Remind me at</label>
        <input id="remind-at" type="time" value=${hhmm}
          onChange=${(e) => {
            const [h, m] = String(e.target.value || "").split(":").map(Number);
            if (!Number.isFinite(h) || !Number.isFinite(m)) return;
            const mins = h * 60 + m;
            setStretchMins(mins);
            remind.setStretchMinutes(mins);
            replan(false);
          }}
          style=${{
            font: "inherit", fontWeight: 600, color: "var(--deep)", background: "var(--surface-soft)",
            border: "1px solid var(--line)", borderRadius: 12, padding: "8px 10px",
          }} />
      </div>`}
      <div style=${{ height: 1, background: "var(--line)" }} />
      ${toggleRow(
        "Period heads-up",
        "A note two days before it's expected",
        html`<${Switch} checked=${periodOn} disabled=${!remindersAvailable}
          label="Period heads-up reminder"
          onChange=${(next) => { setPeriodOn(next); remind.setPeriodOn(next); replan(next); }} />`,
      )}
      ${note(remindersAvailable
        ? "Reminders are scheduled on this phone only. Nothing leaves it."
        : "Reminders need the app on your phone: this browser can't schedule them.")}
    </div>
  </${Card}>`);

  // ---- privacy ----
  const privacySection = () => section("Privacy", html`<${Card}>
    ${toggleRow(
      "Lock with biometrics",
      lockAvailable === false
        ? "This phone has no fingerprint, face unlock or screen lock set"
        : "Your garden opens only for you: your fingerprint, face or screen lock",
      html`<${Switch} checked=${lockOn} disabled=${lockAvailable !== true}
        label="Lock the app with biometrics"
        onChange=${async (next) => {
          const ok = await appLock.setEnabled(next);
          setLockOn(ok ? next : appLock.isEnabled());
        }} />`,
    )}
  </${Card}>`);

  return html`
    <div class="pad" style=${{ padding: "8px 18px 20px", display: "grid", gap: 24 }}>
      <div style=${{ display: "flex", alignItems: "flex-start", gap: 10 }}>
        <div style=${{ flex: 1, display: "grid", gap: 2 }}>
          <h2 style=${{ fontFamily: "var(--font-display)", fontSize: 22, fontWeight: 700, color: "var(--deep)", margin: 0 }}>Make it yours</h2>
          <div style=${{ fontSize: 13, color: "var(--muted)" }}>Pick a palette, then tint it any color you like.</div>
        </div>
        <${IconButton} label="Close" onClick=${nav.close}><${Icon} name="x" size=${18} /><//>
      </div>

      <${Button} variant="soft" block iconLeft=${html`<${Icon} name="gift" size=${16} />`}
        onClick=${() => nav.open("garden")}>Garden shop: spend your petal points<//>

      ${section("Palette", html`<div style=${{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(140px, 1fr))", gap: 12 }}>
        ${PRESETS.map(presetChip)}
      </div>`)}

      ${accentSection()}
      ${studioSection()}

      ${section("Little touches", html`<${Card}>
        <div style=${{ display: "grid", gap: 12 }}>
          ${toggleRow(
            "Falling petals",
            "Petals drift around your cycle ring on Today",
            html`<${Switch} checked=${petals} label="Falling petals around the cycle ring"
              onChange=${(next) => { setPetals(next); write(PETALS_KEY, next ? "true" : "false"); }} />`,
          )}
          <div style=${{ height: 1, background: "var(--line)" }} />
          ${toggleRow(
            "Quiet mode",
            "Celebration sounds stay silent. The sparkle stays",
            html`<${Switch} checked=${quiet} label="Quiet mode, silence celebration sounds"
              onChange=${(next) => { setQuiet(next); write(QUIET_KEY, next ? "true" : "false"); }} />`,
          )}
        </div>
      </${Card}>`)}

      ${remindersSection()}
      ${privacySection()}

      ${note("Period, fertile and phase colors never change. They mean something.")}
    </div>
  `;
}
