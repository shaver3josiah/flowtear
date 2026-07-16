// Today — the home screen. Faithful port of App/Views/TodayView.swift:
// header (bloom + date + tips + theme pencil), the CycleRing hero with drifting
// petals and her pluckable ring sticker, the current phase badge (tap → phase
// sheet), a next-period line, a quick flow log with a one-tap "My period
// started" CTA when it's due (undo toast gives one gentle chance to take it
// back), a rotating teaser pane (stretch → insights → calendar), and the
// fertile window + basal-temperature card. Before her first confirmed period
// the ring still shows, as a labelled best guess. The vendored DS CycleRing
// can't be edited, so the Swift ring's jewelry pass (metal sheen, lapping
// glint, today glimmer) is an overlay sharing the ring's box — same pattern as
// RingSticker. All state reads/writes go through the store.
import { rewards } from "../core/rewards.js";
import { emptyLog } from "../core/models.js";
import { RingSticker, trackRadius } from "../components/ringSticker.js";
import { GlitterHint } from "../components/glitterHint.js";

const React = window.React;
const { useState, useEffect } = React;
const mhtml = window.htm.bind(React.createElement);

const reduceMotion = () =>
  typeof window.matchMedia === "function" &&
  window.matchMedia("(prefers-reduced-motion: reduce)").matches;

// This screen owns the ring-polish + toast keyframes; no build step folds them
// into the shared stylesheet (same pattern as glitterHint.js).
const STYLE_ID = "ft-today-css";
if (typeof document !== "undefined" && !document.getElementById(STYLE_ID)) {
  const el = document.createElement("style");
  el.id = STYLE_ID;
  el.textContent = [
    // RingGlint: one narrow highlight lapping the band every 9s (CycleRing.swift).
    "@keyframes ft-ring-glint { to { transform: rotate(360deg); } }",
    // TodayGlimmer: the gold halo breathes, the two twinkles alternate.
    "@keyframes ft-halo-breathe { from { transform: scale(.98); opacity: .95; } to { transform: scale(1.12); opacity: .55; } }",
    "@keyframes ft-twinkle-hi { from { opacity: .15; } to { opacity: 1; } }",
    "@keyframes ft-twinkle-lo { from { opacity: 1; } to { opacity: .2; } }",
    // Undo toast: move(edge: .top) + opacity (TodayView.swift).
    "@keyframes ft-toast-in { from { opacity: 0; transform: translate(-50%, -12px); } }",
  ].join("\n");
  document.head.appendChild(el);
}

// She can switch the drifting petals off in the pencil settings — same key and
// default-on reading as the theme editor writes (Swift: @AppStorage).
const PETALS_KEY = "flowtear.petalsOnRing";
const petalsOnRing = () => localStorage.getItem(PETALS_KEY) !== "false";

// Fraction of the ring covered by the bleed arc (day 1 → period length).
// TodayView.periodFraction (TodayView.swift:177).
const periodFraction = (p) =>
  Math.min(Math.max(p.averagePeriodLength, 0) / Math.max(p.averageCycleLength, 1), 1);

// Native TodayView.nextPeriodLine (TodayView.swift:176) — copy matched exactly.
function nextPeriodLine(d) {
  if (d == null) return "";
  if (d > 1) return `Your next period is in ${d} days`;
  if (d === 1) return "Your next period is tomorrow";
  if (d === 0) return "Your next period is expected today";
  const late = Math.abs(d);
  return `Your period is ${late} ${late === 1 ? "day" : "days"} late`;
}

const monthDay = (fmt, d) => `${fmt.monthShort(d.getMonth())} ${d.getDate()}`;

// A tap target that carries no button chrome (the child DS pill/ring is the look).
const bareBtn = { background: "none", border: "none", padding: 0, margin: 0, cursor: "pointer", font: "inherit", display: "block" };

// ---------------------------------------------------------------------------
// RingPolish — the CycleRing.swift jewelry pass, overlaid on the vendored DS
// ring (which we can't edit). Shares the ring's box and geometry (track at
// 84/200 of the size, 15/200 stroke), pointer-transparent and aria-hidden:
//   • metal sheen — the "single lamp" top-left wash masked to the band, so
//     track and arcs read as one polished piece (Swift strokes the same wash
//     over the track and each arc; one band-masked wash approximates that);
//   • RingGlint — a narrow white highlight lapping the band every ~9s,
//     mounted only when motion is allowed (Swift: if !reduceMotion);
//   • TodayGlimmer — a breathing gold halo + two alternating four-point
//     twinkles on the today marker, plus the gold→phase gradient center dot.
//     Reduce Motion keeps the halo and one lit twinkle, static.
// ---------------------------------------------------------------------------

// FFTwinkle (CycleRing.swift) — the same concave four-point star GlitterHint uses.
const Twinkle = ({ size, style }) => mhtml`
  <svg width=${size} height=${size} viewBox="0 0 10 10" aria-hidden="true"
    style=${{ position: "absolute", ...style }}>
    <path d="M5 0C5.6 3.2 6.8 4.4 10 5C6.8 5.6 5.6 6.8 5 10C4.4 6.8 3.2 5.6 0 5C3.2 4.4 4.4 3.2 5 0Z"
      fill="var(--flower-center)" />
  </svg>`;

function RingPolish({ size, day, cycleLength, phase }) {
  const k = size / 200;
  const r = trackRadius(size);
  const w = 15 * k; // the DS ring's stroke width
  const still = reduceMotion();

  // Mask that keeps a layer only on the drawn band.
  const band = `radial-gradient(circle, transparent ${r - w / 2 - 0.5}px, #000 ${r - w / 2}px, #000 ${r + w / 2}px, transparent ${r + w / 2 + 0.5}px)`;
  const banded = (extra) => ({
    position: "absolute", inset: 0, pointerEvents: "none",
    WebkitMaskImage: band, maskImage: band, ...extra,
  });

  // Today marker position — same polar math as the vendored knob.
  const a = ((((day - 0.5) / cycleLength) * 360 - 90) * Math.PI) / 180;
  const mx = size / 2 + r * Math.cos(a);
  const my = size / 2 + r * Math.sin(a);

  const d = w + 22 * k; // glimmer halo diameter (Swift: stroke + 22k)
  const haloBand = `radial-gradient(circle, transparent ${d / 2 - 3}px, #000 ${d / 2 - 2.5}px, #000 ${d / 2}px, transparent ${d / 2 + 0.5}px)`;
  const dot = 7 * k;    // marker center dot (Swift: 7k, gold→phase gradient on today)

  // ponytail: web theme presets have no dark mode, so the sheen's shadow end
  // is the Swift light value (.16); revisit if a dark preset lands.
  return mhtml`
    <div aria-hidden="true" style=${{ position: "absolute", inset: 0, pointerEvents: "none" }}>
      <div style=${banded({
        background: "linear-gradient(135deg, rgba(255,255,255,.38) 0%, rgba(255,255,255,.08) 35%, transparent 55%, rgba(0,0,0,.16) 100%)",
      })} />
      ${!still && mhtml`<div style=${banded({
        background: "conic-gradient(from 0deg, transparent 0% 42%, rgba(255,255,255,.22) 48%, rgba(255,255,255,.5) 50%, rgba(255,255,255,.22) 52%, transparent 58% 100%)",
        animation: "ft-ring-glint 9s linear infinite",
      })} />`}

      <div style=${{ position: "absolute", left: mx, top: my, width: 0, height: 0 }}>
        <div style=${{
          position: "absolute", left: -d / 2, top: -d / 2, width: d, height: d,
          borderRadius: "50%",
          background: "conic-gradient(from 0deg, transparent, var(--flower-center) 25%, transparent 50%, var(--flower-center) 75%, transparent)",
          WebkitMaskImage: haloBand, maskImage: haloBand,
          opacity: still ? 0.95 : undefined,
          animation: still ? "none" : "ft-halo-breathe 2.2s ease-in-out infinite alternate",
        }} />
        <${Twinkle} size=${7} style=${{
          left: -d * 0.42 - 3.5, top: -d * 0.34 - 3.5,
          opacity: 0.15,
          animation: still ? "none" : "ft-twinkle-hi 1.4s ease-in-out infinite alternate",
        }} />
        <${Twinkle} size=${5} style=${{
          left: d * 0.44 - 2.5, top: d * 0.28 - 2.5,
          opacity: 1,
          animation: still ? "none" : "ft-twinkle-lo 1.4s ease-in-out infinite alternate",
        }} />
        <div style=${{
          position: "absolute", left: -dot / 2, top: -dot / 2, width: dot, height: dot,
          borderRadius: "50%",
          background: `linear-gradient(135deg, var(--flower-center), var(--phase-${phase || "menstrual"}))`,
        }} />
      </div>
    </div>`;
}

export default function TodayScreen({ ctx }) {
  const { store, html, ui, Icon, fmt, today, nav } = ctx;
  const { Card, Button, FlowerMark, IconButton, PetalRain, CycleRing, PhaseBadge, FlowScale } = ui;

  const p = store.prediction(today);
  const flow = store.logFor(today)?.flow ?? null;
  const openPhase = () => nav.open("phase", { phase: p.phase });

  // Rotating bottom pane — a fresh nudge every ten seconds (TodayView.rotatingPane).
  const [pane, setPane] = useState(0);
  useEffect(() => {
    const t = setInterval(() => setPane((i) => (i + 1) % 3), 10000);
    return () => clearInterval(t);
  }, []);

  // Undo toast — one gentle chance to take a quick action back (TodayView.swift
  // UndoAction). role="status" speaks the message for AT; the web can't detect
  // a running screen reader, so everyone gets the 5s grace (Swift gives
  // VoiceOver 20s — no web equivalent of UIAccessibility.isVoiceOverRunning).
  const [undoToast, setUndoToast] = useState(null); // { id, message, undo }
  useEffect(() => {
    if (!undoToast) return;
    const t = setTimeout(() => setUndoToast(null), 5000);
    return () => clearTimeout(t);
  }, [undoToast]);

  const toast = undoToast && html`
    <div role="status" style=${{
      position: "fixed", top: "calc(env(safe-area-inset-top, 0px) + 10px)", left: "50%",
      transform: "translateX(-50%)", zIndex: 30,
      display: "flex", alignItems: "center", gap: 8, whiteSpace: "nowrap",
      padding: "4px 6px 4px 16px", borderRadius: 999,
      background: "var(--surface)", border: "1px solid var(--line)",
      boxShadow: "0 6px 10px var(--shadow)",
      animation: reduceMotion() ? "none" : "ft-toast-in var(--dur-base) var(--ease-signature)",
    }}>
      <span style=${{ fontSize: "var(--text-sm)", fontWeight: 500, color: "var(--text)" }}>${undoToast.message}</span>
      <button onClick=${() => { undoToast.undo(); setUndoToast(null); }}
        style=${{ ...bareBtn, minWidth: 44, minHeight: 44, fontSize: "var(--text-sm)", fontWeight: 700, color: "var(--primary-strong)" }}>
        Undo
      </button>
    </div>`;

  // One tap when it matters most: her period is due (or late) and nothing is
  // logged yet — no slider hunting on a crampy morning (TodayView.showPeriodCTA).
  const daysUntil = p.daysUntilNextPeriod;
  const showPeriodCTA = flow == null && daysUntil != null && daysUntil <= 2;
  const logPeriodStart = () => {
    const l = { ...(store.logFor(today) ?? emptyLog(store.key(today))), flow: "medium" };
    store.upsert(l);
    setUndoToast({
      id: Date.now(),
      message: "Logged a medium flow for today",
      // Swift's undo clears flow unconditionally (the CTA only shows when it
      // was empty); an all-empty log is dropped by upsert, as if never logged.
      undo: () => store.upsert({ ...(store.logFor(today) ?? emptyLog(store.key(today))), flow: null }),
    });
  };

  // The bloom is a double-tap easter egg (Swift: onTapGesture(count: 2)), but it
  // still answers a keyboard/AT activation — `e.detail === 0` is a click with no
  // mouse behind it, so the secret survives without stranding the button.
  const header = html`
    <div style=${{ display: "flex", alignItems: "center", gap: 11, marginBottom: 4 }}>
      <button style=${bareBtn} onDoubleClick=${() => nav.open("about")}
        onClick=${(e) => { if (e.detail === 0) nav.open("about"); }}
        aria-label="About Uncorked" title="About Uncorked">
        <${FlowerMark} size=${38} />
      </button>
      <div style=${{ display: "flex", flexDirection: "column", gap: 2 }}>
        <span style=${{ fontSize: "var(--text-xs)", color: "var(--muted)" }}>${fmt.greeting(today)}</span>
        <span style=${{ fontFamily: "var(--font-display)", fontWeight: 600, fontSize: "var(--text-xl)", color: "var(--deep)" }}>${fmt.longDate(today)}</span>
      </div>
      <div style=${{ flex: 1 }} />
      <button onClick=${() => nav.open("garden")} aria-label="Your garden and petal points"
        style=${{ display: "inline-flex", alignItems: "center", gap: 5, height: 34, padding: "0 12px",
          borderRadius: 999, background: "var(--surface-soft)", border: "none", cursor: "pointer",
          color: "var(--deep)", fontWeight: 700, marginRight: 8, fontVariantNumeric: "tabular-nums" }}>
        <${Icon} name="flower-2" size=${16} color="var(--primary-strong)" />
        ${rewards.balance}
      </button>
      <${GlitterHint} hintKey="tips">
        <${IconButton} label="Tips and hidden features" variant="soft" onClick=${() => nav.open("tips")}>
          <${Icon} name="sparkles" size=${18} />
        </${IconButton}>
      </${GlitterHint}>
      <${GlitterHint} hintKey="themeEditor">
        <${IconButton} label="Theme settings" variant="soft" onClick=${() => nav.open("theme")}>
          <${Icon} name="edit-3" size=${18} />
        </${IconButton}>
      </${GlitterHint}>
    </div>`;

  const sampleBanner = store.sampleActive ? html`
    <${Card} variant="soft" padding=${12}>
      <div style=${{ display: "flex", alignItems: "center", gap: 10 }}>
        <${Icon} name="sparkles" size=${18} color="var(--primary-strong)" />
        <span style=${{ fontSize: "var(--text-sm)", color: "var(--muted)" }}>Showing sample data so you can explore. Log your own day to make it yours.</span>
      </div>
    </${Card}>` : null;

  // The sticker shares the ring's box so its orbit center IS the ring's center,
  // and it rides the drawn track's exact radius — concentric, never offset.
  // RingPolish shares the same box for the Swift ring's sheen/glint/glimmer.
  const ring = (pred, size, onOpen) => {
    const cl = pred.averageCycleLength;
    const day = Math.min(Math.max(pred.cycleDay || 1, 1), cl);
    // On the tappable hero the center invites the tap, exactly like the Swift
    // readout ("tap for today's insight" — the web ring is always on today).
    // Label color is .deep for contrast, per the Swift centerReadout.
    const readout = onOpen ? html`
      <span style=${{ fontFamily: "var(--font-body)", fontWeight: 600, fontSize: "var(--text-xs)",
        letterSpacing: "var(--tracking-label)", textTransform: "uppercase", color: "var(--deep)" }}>${fmt.phaseLabel(pred.phase)}</span>
      <span style=${{ fontFamily: "var(--font-display)", fontWeight: 600, fontSize: size * 0.26,
        lineHeight: 1, color: "var(--deep)", margin: "2px 0" }}>${day}</span>
      <span style=${{ fontFamily: "var(--font-body)", fontSize: "var(--text-sm)", color: "var(--muted)" }}>tap for today's insight</span>` : null;
    const dial = html`<${CycleRing}
      cycleDay=${day}
      cycleLength=${cl}
      periodLength=${pred.averagePeriodLength}
      size=${size}>${readout}</${CycleRing}>`;
    return html`
      <div style=${{ position: "relative", width: size, height: size }}>
        ${onOpen
          ? html`<button style=${bareBtn} onClick=${onOpen}
              aria-label=${`Cycle ring — day ${day} of ${cl}, ${fmt.phaseLabel(pred.phase)} phase, today. Opens today's insight`}>${dial}</button>`
          : dial}
        <${RingPolish} size=${size} day=${day} cycleLength=${cl} phase=${pred.phase} />
        <${RingSticker} radius=${trackRadius(size)} periodFraction=${periodFraction(pred)} />
      </div>`;
  };

  const hero = html`
    <div style=${{ position: "relative", padding: "2px 0" }}>
      ${petalsOnRing() && html`<${PetalRain} count=${10} />`}
      <div style=${{ position: "relative", zIndex: 1, display: "flex", flexDirection: "column", alignItems: "center", gap: 10 }}>
        ${ring(p, 244, openPhase)}
        <button style=${bareBtn} onClick=${openPhase} aria-label=${`${fmt.phaseLabel(p.phase)} phase — open details`}>
          <${PhaseBadge} phase=${p.phase} />
        </button>
        <div style=${{ fontSize: "var(--text-sm)", fontWeight: 500, color: "var(--muted)", textAlign: "center" }}>${nextPeriodLine(p.daysUntilNextPeriod)}</div>
      </div>
    </div>`;

  // A best-guess ring before her first confirmed period: anchored on any bleeding
  // (or her first log), clearly labelled as an estimate (TodayView.previewHero).
  const previewHero = () => html`
    <div style=${{ display: "flex", flexDirection: "column", alignItems: "center", gap: 8 }}>
      ${ring(store.previewPrediction(today), 220, null)}
      <span style=${{ fontSize: "var(--text-xs)", fontWeight: 500, color: "var(--muted)" }}>A first guess — it sharpens as you log</span>
    </div>`;

  const quickLog = html`
    <${Card}>
      <div style=${{ display: "flex", flexDirection: "column", gap: 12 }}>
        ${showPeriodCTA && html`
          <${Button} variant="primary" block=${true}
            iconLeft=${html`<${Icon} name="droplet" size=${16} />`}
            onClick=${logPeriodStart}>
            ${daysUntil < 0 ? "My period started" : "My period started today"}
          </${Button}>`}
        <div style=${{ display: "flex", flexDirection: "column", gap: 8 }}>
          <span style=${{ fontSize: "var(--text-sm)", fontWeight: 600, color: "var(--text)" }}>How's your flow today?</span>
          <${FlowScale} value=${flow} onChange=${(lvl) => store.toggleFlow(lvl, today)} />
        </div>
        <${Button} variant="ghost" size="sm" iconLeft=${html`<${Icon} name="plus" size=${16} />`} onClick=${() => nav.setTab("log")}>
          Log mood & symptoms
        </${Button}>
      </div>
    </${Card}>`;

  const panes = [
    { icon: "activity", tint: "var(--phase-luteal)", title: "Stretch",
      line: "Gentle cramp-ease moves, a little every day — Posey guides you.",
      action: () => nav.setTab("stretch") },
    { icon: "bar-chart-2", tint: "var(--primary-strong)", title: "Insights",
      line: "Your averages, rhythms and top symptoms — all from what you log.",
      action: () => nav.setTab("insights") },
    { icon: "calendar", tint: "var(--phase-fertile)", title: "Calendar",
      line: "Your whole month at a glance — periods, fertile days, stretches.",
      action: () => nav.setTab("calendar") },
  ];
  const pc = panes[pane];
  const rotatingPane = html`
    <div key=${pane} style=${{ animation: "flowtier-view-in var(--dur-base) var(--ease-signature)" }}>
      <${Card} interactive=${true} as="button" onClick=${pc.action}
        style=${{ width: "100%", textAlign: "left" }} aria-label=${`Open ${pc.title}`}>
        <div style=${{ display: "flex", alignItems: "center", gap: 12 }}>
          <${Icon} name=${pc.icon} size=${22} color=${pc.tint} />
          <div style=${{ display: "flex", flexDirection: "column", gap: 2, flex: 1, minWidth: 0 }}>
            <span style=${{ fontSize: "var(--text-md)", fontWeight: 600, color: "var(--deep)" }}>${pc.title}</span>
            <span style=${{ fontSize: "var(--text-sm)", color: "var(--muted)" }}>${pc.line}</span>
          </div>
          <${Icon} name="chevron-right" size=${16} color="var(--muted)" />
        </div>
      </${Card}>
    </div>`;

  const startedState = html`
    <${Card}>
      <div style=${{ display: "flex", flexDirection: "column", alignItems: "center", gap: 12, textAlign: "center", padding: "12px 0" }}>
        <${FlowerMark} size=${72} breathe=${true} />
        <span style=${{ fontFamily: "var(--font-display)", fontWeight: 600, fontSize: "var(--text-lg)", color: "var(--deep)" }}>Your log is growing</span>
        <span style=${{ fontSize: "var(--text-sm)", color: "var(--muted)", lineHeight: "var(--leading-normal)" }}>Lovely start. The cycle ring and predictions appear once you log your first period days — light, medium or heavy flow.</span>
      </div>
    </${Card}>`;

  const emptyState = html`
    <${Card}>
      <div style=${{ display: "flex", flexDirection: "column", alignItems: "center", gap: 16, textAlign: "center", padding: "20px 0" }}>
        <button style=${bareBtn} onClick=${() => nav.setTab("log")} aria-label="Log today">
          <${FlowerMark} size=${120} breathe=${true} />
        </button>
        <span style=${{ fontFamily: "var(--font-display)", fontWeight: 600, fontSize: "var(--text-lg)", color: "var(--deep)" }}>Nothing logged yet</span>
        <span style=${{ fontSize: "var(--text-sm)", color: "var(--muted)" }}>Tap to log your first period.</span>
      </div>
    </${Card}>`;

  return html`
    <div style=${{ display: "flex", flexDirection: "column", gap: "var(--gap-card)" }}>
      ${toast}
      ${header}
      ${sampleBanner}
      ${p.hasHistory
        ? html`${hero}${quickLog}${rotatingPane}<${FertileWindow} ctx=${ctx} p=${p} />`
        : store.hasAnyLogs
          ? html`${previewHero()}${startedState}${quickLog}${rotatingPane}`
          : emptyState}
    </div>`;
}

// Fertile window + basal body temperature — port of FertileWindowCard.swift.
// The temperature reading is stored per-day via the shared store (persists).
function FertileWindow({ ctx, p }) {
  const { store, html, ui, Icon, fmt, today } = ctx;
  const { Card, Button, Badge } = ui;

  const tempF = fmt.cToF(store.logFor(today)?.temperatureC ?? null);

  // "Fertile now" inside the window, "In Nd" when it opens within a fortnight.
  let status = null;
  if (p.fertileStart && p.fertileEnd) {
    const toStart = fmt.daysUntil(today, p.fertileStart);
    const toEnd = fmt.daysUntil(today, p.fertileEnd);
    if (toStart <= 0 && toEnd >= 0) status = "Fertile now";
    else if (toStart > 0 && toStart <= 14) status = `In ${toStart}d`;
  }

  const infoRow = (label, value, tint) => html`
    <div style=${{ display: "flex", alignItems: "center", gap: 8 }}>
      <span style=${{ width: 8, height: 8, borderRadius: "50%", background: tint, flex: "0 0 auto" }} />
      <span style=${{ fontSize: "var(--text-sm)", color: "var(--text)" }}>${label}</span>
      <div style=${{ flex: 1 }} />
      <span style=${{ fontSize: "var(--text-sm)", fontWeight: 600, color: "var(--deep)" }}>${value}</span>
    </div>`;

  const temps = store.recentTemperatures();
  let sparkline = null;
  if (temps.length >= 2) {
    const fs = temps.map((t) => fmt.cToF(t.celsius));
    const lo = Math.min(...fs) - 0.1;
    const hi = Math.max(...fs) + 0.1;
    const span = Math.max(hi - lo, 0.2);
    const pts = fs.map((f, i) => `${(i / (fs.length - 1)) * 100},${(1 - (f - lo) / span) * 40}`).join(" ");
    sparkline = html`
      <svg viewBox="0 0 100 40" preserveAspectRatio="none" width="100%" height="40" aria-label=${`Recent basal temperature trend, ${temps.length} readings`}>
        <polyline points=${pts} fill="none" stroke="var(--phase-fertile)" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" vector-effect="non-scaling-stroke" />
      </svg>`;
  }

  return html`
    <${Card}>
      <div style=${{ display: "flex", flexDirection: "column", gap: 14 }}>
        <div style=${{ display: "flex", alignItems: "center", gap: 8 }}>
          <${Icon} name="thermometer" size=${16} color="var(--phase-fertile)" />
          <span style=${{ fontSize: "var(--text-md)", fontWeight: 600, color: "var(--deep)" }}>Fertile window</span>
          <div style=${{ flex: 1 }} />
          ${status && html`<${Badge} tone="fertile" dot=${true}>${status}</${Badge}>`}
        </div>

        ${p.fertileStart && p.fertileEnd
          ? infoRow("Window", `${monthDay(fmt, p.fertileStart)} – ${monthDay(fmt, p.fertileEnd)}`, "var(--phase-fertile)")
          : html`<span style=${{ fontSize: "var(--text-sm)", color: "var(--muted)" }}>Log a couple of cycles to estimate your fertile window.</span>`}
        ${p.ovulationDate && infoRow("Ovulation (est.)", monthDay(fmt, p.ovulationDate), "var(--phase-ovulation)")}

        <div style=${{ height: 1, background: "var(--line)" }} />

        <div style=${{ display: "flex", flexDirection: "column", gap: 10 }}>
          <div style=${{ display: "flex", alignItems: "center", gap: 8 }}>
            <span style=${{ fontSize: "var(--text-sm)", fontWeight: 600, color: "var(--text)" }}>Basal temperature</span>
            <div style=${{ flex: 1 }} />
            ${tempF != null && html`
              <button style=${{ ...bareBtn }} onClick=${() => store.setTemperatureC(null, today)} aria-label="Remove today's temperature">
                <${Icon} name="x" size=${16} color="var(--muted)" />
              </button>`}
          </div>
          ${tempF != null
            ? html`
              <span style=${{ fontFamily: "var(--font-display)", fontWeight: 600, fontSize: "var(--text-xl)", color: "var(--deep)" }}>${tempF.toFixed(2)} °F</span>
              <input type="range" min="96" max="100" step="0.05" value=${tempF}
                onInput=${(e) => store.setTemperatureC(fmt.fToC(parseFloat(e.target.value)), today)}
                aria-label="Basal temperature"
                style=${{ width: "100%", accentColor: "var(--phase-fertile)" }} />
              ${sparkline}`
            : html`<${Button} variant="soft" size="sm" iconLeft=${html`<${Icon} name="plus" size=${16} />`}
                onClick=${() => store.setTemperatureC(fmt.fToC(97.8), today)}>Log today's temp</${Button}>`}
        </div>

        <span style=${{ fontSize: "var(--text-2xs)", color: "var(--muted)" }}>Estimates — not a birth-control method.</span>
      </div>
    </${Card}>`;
}
