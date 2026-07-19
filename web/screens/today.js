// Today — the home screen. Faithful port of App/Views/TodayView.swift:
// header (bloom + date + tips + theme pencil + garden shop), the CycleRing hero
// with drifting petals and her pluckable ring sticker, the current phase badge
// (tap → phase sheet), a next-period line, a quick flow log with a one-tap "My
// period started" CTA when it's due (undo toast gives one gentle chance to
// take it back), a rotating teaser pane (stretch → insights → calendar), and
// the fertile window + basal-temperature card. Before her first confirmed
// period the ring still shows, as a labelled best guess. The vendored DS
// CycleRing can't be edited, so the Swift ring's jewelry pass (metal sheen, 7s
// phase shimmer, solid today bead + glimmer) is an overlay sharing the ring's
// box — same pattern as RingSticker. A draggable chain-together toggle rides
// the ring's bottom-trailing corner once she's wearing a bead plus at least
// one more chained bloom. All state reads/writes go through the store.
import { rewards } from "../core/rewards.js";
import { emptyLog } from "../core/models.js";
import { RingSticker, trackRadius } from "../components/ringSticker.js";
import { GlitterHint } from "../components/glitterHint.js";
// Five levels, not the vendored four: the DS FlowScale predates Flow.superHeavy
// and can't show it (ds-bundle.js is uneditable). Drop-in same props.
import { FlowScale } from "../components/flowScale.js";

const React = window.React;
const { useState, useEffect, useRef } = React;
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
//   • ArcShimmer — one gleam every 7 seconds, taking turns around the phases
//     (bleed, fertile, ovulation), mounted only when motion is allowed
//     (Swift: if !reduceMotion — the rest state is the band at rest);
//   • TodayGlimmer — a breathing gold halo + two alternating four-point
//     twinkles on the today marker, plus the SOLID gold→phase bead that
//     covers the vendored knob's old bullseye. Reduce Motion keeps the halo
//     and one lit twinkle, static.
// ---------------------------------------------------------------------------

// ArcShimmer (CycleRing.swift) — one gleam every 7 seconds, taking turns
// around the phases: a narrow soft highlight sweeps ONE phase arc from start
// to end (~1.1s), then the band rests until the next phase's turn.
// Deterministic cadence, one shimmer at a time; the caller mounts it only
// when motion is allowed.
function ArcShimmer({ size, cycleLength, periodLength }) {
  const r = trackRadius(size);
  const w = (15 * size) / 200;
  // Same phase-arc math as the vendored DS ring (computeCycle).
  const cl = cycleLength;
  const ovDay = Math.min(Math.max(cl - 14, periodLength + 1), cl - 1);
  const fertileStart = Math.max(ovDay - 5, periodLength + 1);
  const segs = [
    { from: 0, to: periodLength / cl },
    { from: (fertileStart - 1) / cl, to: (ovDay + 1) / cl },
    { from: (ovDay - 0.6) / cl, to: (ovDay + 0.6) / cl },
  ];

  const [sweep, setSweep] = useState(null); // { seg, head } while a gleam travels
  useEffect(() => {
    let t;
    let seg = 0;
    const steps = 36;
    const run = (i) => {
      const s = segs[seg % segs.length];
      setSweep({ seg: seg % segs.length, head: s.from + (s.to - s.from + 0.05) * (i / steps) });
      if (i < steps) t = setTimeout(() => run(i + 1), 30);
      else { setSweep(null); seg += 1; rest(); }
    };
    const rest = () => { t = setTimeout(() => run(0), 5900); }; // + ~1.1s sweep = 7s cadence
    rest();
    return () => clearTimeout(t);
  }, [size, cycleLength, periodLength]);

  if (!sweep) return null;
  const s = segs[sweep.seg];
  const from = Math.max(sweep.head - 0.05, s.from);
  const to = Math.min(sweep.head, s.to);
  if (to - from < 0.0005) return null;
  const c = size / 2;
  const pt = (f) => {
    const a = ((f * 360 - 90) * Math.PI) / 180;
    return `${c + r * Math.cos(a)} ${c + r * Math.sin(a)}`;
  };
  const grad = `ft-shimmer-${size}`;
  return mhtml`
    <svg width=${size} height=${size} viewBox=${`0 0 ${size} ${size}`} aria-hidden="true"
      style=${{ position: "absolute", inset: 0, pointerEvents: "none" }}>
      <defs>
        <linearGradient id=${grad}>
          <stop offset="0" stop-color="#fff" stop-opacity="0" />
          <stop offset="0.5" stop-color="#fff" stop-opacity="0.55" />
          <stop offset="1" stop-color="#fff" stop-opacity="0" />
        </linearGradient>
      </defs>
      <path d=${`M ${pt(from)} A ${r} ${r} 0 0 1 ${pt(to)}`}
        fill="none" stroke=${`url(#${grad})`} stroke-width=${w} stroke-linecap="round" />
    </svg>`;
}

// FFTwinkle (CycleRing.swift) — the same concave four-point star GlitterHint uses.
const Twinkle = ({ size, style }) => mhtml`
  <svg width=${size} height=${size} viewBox="0 0 10 10" aria-hidden="true"
    style=${{ position: "absolute", ...style }}>
    <path d="M5 0C5.6 3.2 6.8 4.4 10 5C6.8 5.6 5.6 6.8 5 10C4.4 6.8 3.2 5.6 0 5C3.2 4.4 4.4 3.2 5 0Z"
      fill="var(--flower-center)" />
  </svg>`;

// LinkGlyph — stand-in for the "link" SF Symbol on the chain-together toggle;
// no offline lucide glyph of a chain link exists (see vendor/icon.js's ICONS),
// so this is a small hand-drawn pair of interlocking hooks, same pattern as
// Twinkle above and RingSticker's Bloom.
const LinkGlyph = ({ size, color }) => mhtml`
  <svg width=${size} height=${size} viewBox="0 0 24 24" fill="none" stroke=${color}
    stroke-width="2.4" stroke-linecap="round" aria-hidden="true">
    <path d="M8.5 13.5 6 16a3 3 0 0 0 4.2 4.2l2.5-2.5" />
    <path d="M15.5 10.5 18 8a3 3 0 0 0-4.2-4.2l-2.5 2.5" />
    <path d="M9 15 15 9" />
  </svg>`;

function RingPolish({ size, day, cycleLength, periodLength, phase }) {
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
  // The solid focus bead (Swift: stroke + 8k, gold→phase gradient on today,
  // hairline surface rim, specular top-left kiss). The vendored knob beneath
  // still draws the old bullseye and its outer edge sits at 13.5 units in the
  // 200 viewBox, so the bead is sized to cover it completely.
  const bead = 27 * k;

  // ponytail: web theme presets have no dark mode, so the sheen's shadow end
  // is the Swift light value (.16); revisit if a dark preset lands.
  return mhtml`
    <div aria-hidden="true" style=${{ position: "absolute", inset: 0, pointerEvents: "none" }}>
      <div style=${banded({
        background: "linear-gradient(135deg, rgba(255,255,255,.38) 0%, rgba(255,255,255,.08) 35%, transparent 55%, rgba(0,0,0,.16) 100%)",
      })} />
      ${!still && mhtml`<${ArcShimmer} size=${size} cycleLength=${cycleLength} periodLength=${periodLength} />`}

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
          position: "absolute", left: -bead / 2, top: -bead / 2, width: bead, height: bead,
          borderRadius: "50%", boxSizing: "border-box",
          background: `linear-gradient(135deg, var(--flower-center), var(--phase-${phase || "menstrual"}))`,
          border: "2px solid var(--surface)",
          boxShadow: `0 1px 2px var(--shadow), inset ${1.5 * k}px ${1.5 * k}px ${2 * k}px rgba(255,255,255,.55)`,
        }} />
      </div>
    </div>`;
}

export default function TodayScreen({ ctx }) {
  const { store, html, ui, Icon, fmt, today, nav } = ctx;
  const { Card, Button, FlowerMark, IconButton, PetalRain, CycleRing, PhaseBadge } = ui;

  const p = store.prediction(today);
  const flow = store.logFor(today)?.flow ?? null;
  const openPhase = () => nav.open("phase", { phase: p.phase });

  // The garden blob lives outside CycleStore's own subscription, so re-render
  // Today when it changes too (equipping, chaining, spending) — the balance
  // pill and the chain-together toggle both read it live.
  const [, forceRewards] = useState(0);
  useEffect(() => rewards.subscribe(() => forceRewards((n) => n + 1)), []);

  // Chained blooms minus the one riding as the draggable bead, so a worn bloom
  // never renders twice on the ring (TodayView.chainMinusBead).
  const chainMinusBead = rewards.ringChain.filter((id) => id !== rewards.activeSticker);
  const chainLinked = rewards.chainLinked ?? false;
  const toggleChainLinked = () => {
    // ponytail: rewards.js may not have grown chainLinked/setChainLinked yet
    // (parallel Garden/Rewards port) — fall back to a direct, unpersisted
    // toggle so the button still works this session. Once core/rewards.js
    // adds setChainLinked, this branch is dead and can be deleted.
    if (typeof rewards.setChainLinked === "function") {
      rewards.setChainLinked(!chainLinked);
    } else {
      rewards.chainLinked = !chainLinked;
      rewards._save();
      rewards._notify();
    }
  };

  // Where she's parked the chain toggle, relative to the ring's corner —
  // same AppStorage keys as Swift (TodayView.chainBtnX/Y).
  const CHAIN_X_KEY = "flowtear.chainBtnX", CHAIN_Y_KEY = "flowtear.chainBtnY";
  const [chainPos, setChainPos] = useState(() => ({
    x: parseFloat(localStorage.getItem(CHAIN_X_KEY)) || -18,
    y: parseFloat(localStorage.getItem(CHAIN_Y_KEY)) || -18,
  }));
  const [chainDrag, setChainDrag] = useState({ x: 0, y: 0 });
  const chainGesture = useRef(null); // { startX, startY, dx, dy, moved }

  const onChainDown = (e) => {
    e.stopPropagation();
    e.currentTarget.setPointerCapture(e.pointerId);
    chainGesture.current = { startX: e.clientX, startY: e.clientY, dx: 0, dy: 0, moved: false };
  };
  const onChainMove = (e) => {
    const g = chainGesture.current;
    if (!g) return;
    g.dx = e.clientX - g.startX;
    g.dy = e.clientY - g.startY;
    // A drag only "counts" past 8px of travel — a plain tap must still toggle.
    if (!g.moved && Math.hypot(g.dx, g.dy) > 8) g.moved = true;
    if (g.moved) setChainDrag({ x: g.dx, y: g.dy });
  };
  const onChainUp = () => {
    const g = chainGesture.current;
    chainGesture.current = null;
    if (g && g.moved) {
      // Commit and clamp so it can never wander off the hero.
      const x = Math.min(Math.max(chainPos.x + g.dx, -250), 6);
      const y = Math.min(Math.max(chainPos.y + g.dy, -250), 6);
      setChainPos({ x, y });
      localStorage.setItem(CHAIN_X_KEY, String(x));
      localStorage.setItem(CHAIN_Y_KEY, String(y));
      setChainDrag({ x: 0, y: 0 });
    } else if (g) {
      toggleChainLinked();
    }
  };

  // The chain-together toggle itself: a quiet little link she can drag
  // anywhere around the ring and tap to snap or spread her flowers. Only
  // shown when there's a bead plus at least one more bloom — something to
  // snap (TodayView.chainButton).
  const chainButton = rewards.activeSticker != null && chainMinusBead.length > 0 && html`
    <div style=${{
      position: "absolute", right: 0, bottom: 0,
      transform: `translate(${chainPos.x + chainDrag.x}px, ${chainPos.y + chainDrag.y}px)`,
    }}>
      <${GlitterHint} hintKey="chainTogether">
        <button type="button"
          onPointerDown=${onChainDown} onPointerMove=${onChainMove}
          onPointerUp=${onChainUp} onPointerCancel=${onChainUp}
          aria-label=${chainLinked ? "Spread your flowers around the ring" : "Snap your flowers into a chain"}
          aria-description="Drag to move this button"
          style=${{
            ...bareBtn, width: 34, height: 34, borderRadius: "50%",
            display: "grid", placeItems: "center", cursor: "grab", touchAction: "none",
            background: `color-mix(in srgb, var(${chainLinked ? "--surface-soft" : "--surface"}) 90%, transparent)`,
            border: `${chainLinked ? 1.2 : 1}px solid var(${chainLinked ? "--primary-strong" : "--line"})`,
          }}>
          <${LinkGlyph} size=${13} color=${`var(${chainLinked ? "--primary-strong" : "--muted"})`} />
        </button>
      </${GlitterHint}>
    </div>`;

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
      <${GlitterHint} hintKey="todayShop">
        <!-- Swift's "bag" glyph has no offline lucide counterpart; "gift" is
             the shop-shaped icon the vendored set carries (same substitution
             log.js's garden-shop button already uses). -->
        <${IconButton} label="Garden shop" variant="soft" onClick=${() => nav.open("garden")}>
          <${Icon} name="gift" size=${18} />
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
  // RingPolish shares the same box for the Swift ring's sheen/shimmer/glimmer;
  // her daisy chain rides the ring beneath the draggable bead, and the
  // chain-together toggle rides its bottom-trailing corner (TodayView.swift).
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
    // spinnable: the DS ring's built-in fidget spin (drag + inertial decay) —
    // pure fun, reduced-motion aware inside the vendored component. The wrapping
    // button suppresses its click when the pointer actually dragged, so spinning
    // never accidentally opens the phase sheet; a clean tap still does.
    const dial = html`<${CycleRing}
      cycleDay=${day}
      cycleLength=${cl}
      periodLength=${pred.averagePeriodLength}
      spinnable=${true}
      size=${size}>${readout}</${CycleRing}>`;
    const down = { x: 0, y: 0 };
    const onDown = (e) => { down.x = e.clientX; down.y = e.clientY; };
    const onClick = (e) => {
      if (Math.hypot(e.clientX - down.x, e.clientY - down.y) > 8) return; // was a spin
      onOpen();
    };
    return html`
      <div style=${{ position: "relative", width: size, height: size }}>
        ${onOpen
          ? html`<button style=${bareBtn} onPointerDown=${onDown} onClick=${onClick}
              aria-label=${`Cycle ring — day ${day} of ${cl}, ${fmt.phaseLabel(pred.phase)} phase, today. Opens today's insight`}>${dial}</button>`
          : dial}
        <${RingPolish} size=${size} day=${day} cycleLength=${cl}
          periodLength=${pred.averagePeriodLength} phase=${pred.phase} />
        <!-- RingSticker now draws the whole chain itself (bead excluded, see
             its chainBlooms), matching Swift's TodayView which no longer calls
             RingChainView separately — do NOT re-add a <RingChain> call here,
             it would double-render every chained bloom on top of itself. -->
        <${RingSticker} radius=${trackRadius(size)} periodFraction=${periodFraction(pred)} />
        ${chainButton}
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
      line: "Gentle cramp-ease moves, a little every day. Posey guides you.",
      action: () => nav.setTab("stretch") },
    { icon: "bar-chart-2", tint: "var(--primary-strong)", title: "Insights",
      line: "Your averages, rhythms and top symptoms, all from what you log.",
      action: () => nav.setTab("insights") },
    { icon: "calendar", tint: "var(--phase-fertile)", title: "Calendar",
      line: "Your whole month at a glance: periods, fertile days, stretches.",
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

        <span style=${{ fontSize: "var(--text-2xs)", color: "var(--muted)" }}>Estimates, not a birth-control method.</span>
      </div>
    </${Card}>`;
}
