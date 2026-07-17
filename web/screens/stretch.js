// Stretch — her coach. Port of App/Views/StretchCoachView.swift. Posey the flower
// cheers her on; the plan knows what day she's on automatically; every stretch is a
// checkbox; the whole day can be checked too. Three modes (core trio / 3-day starter
// default / full 14-day) switch from the plan bar at the top and never touch logged
// history — completions live on dates, in the shared store. The two scheduled modes
// lock in: a missed plan day costs 5 petals (never before the plan was activated).
// The garden header (points pill, shop, share, rules, tutorial sheets) is the garden
// feature and lives on its own screen — see web/screens/garden.js.
import * as lib from "../core/stretchLibrary.js";
import { startOfDay, isSameDay } from "../core/dates.js";
import { rewards, FLOWERS } from "../core/rewards.js";
import { crownSpot } from "../components/ringSticker.js";

const reduceMotion = () =>
  typeof window.matchMedia === "function" &&
  window.matchMedia("(prefers-reduced-motion: reduce)").matches;

const React = window.React;
const { useState, useEffect } = React;

// Mirrors @AppStorage("flowtear.planActivatedAt"): the dateKey of the day the
// current lock-in plan was (re)chosen. Penalties never reach behind this line —
// so switching tiers, or the first prediction remapping the window into the
// past, can never retroactively bill days the plan wasn't active for.
// ("Switching keeps every point and completion" has to be TRUE.)
const ACTIVATION_KEY = "flowtear.planActivatedAt";

// rewards' per-day pose ledger is dateKey-first (see rewards.js awardPose).
const awardPose = (dateKey, alreadyDone, total, multiplier) =>
  rewards.awardPose(dateKey, alreadyDone, total, multiplier);
const revokePose = (dateKey, remainingDone, total, wasFullDay, multiplier) =>
  rewards.revokePose(dateKey, remainingDone, total, wasFullDay, multiplier);

// Inline pose figure (ported PoseShape geometry) or a themed icon fallback.
function PoseFigure({ ctx, move, size = 24, color = "var(--phase-luteal)" }) {
  const { html, Icon } = ctx;
  const shape = lib.POSE_SHAPES[lib.poseKind(move.name)];
  if (!shape) {
    const name = move.icon === "wind" ? "wind" : move.icon === "figure.walk" ? "activity" : "activity";
    return html`<span style=${{ color, display: "inline-flex", width: size, height: size, alignItems: "center", justifyContent: "center", flex: "0 0 auto" }}>
      <${Icon} name=${name} size=${Math.round(size * 0.82)} /></span>`;
  }
  const [hx, hy, hr] = shape.head;
  return html`<svg viewBox="0 0 1 1" width=${size} height=${size} fill="none" stroke=${color}
      stroke-width=${0.09} stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"
      style=${{ display: "block", flex: "0 0 auto" }}>
    <circle cx=${hx} cy=${hy} r=${hr} />
    ${shape.paths.map((d, i) => html`<path key=${i} d=${d} />`)}
  </svg>`;
}

// A procedural inline bloom — the same catalog-indexed petals the garden shop
// draws, so a flower reads the same everywhere. ponytail: third copy of the
// shop's Bloom (garden.js, ringSticker.js keep theirs private); sharing needs a
// module outside this task's files.
function Bloom({ ctx, id, size }) {
  const { html, ui } = ctx;
  if (id === "posey" && ui.FlowerMark) return html`<${ui.FlowerMark} size=${size} />`;
  const idx = Math.max(FLOWERS.findIndex((f) => f.id === id), 0);
  const petals = 5 + (idx % 6);
  const fills = ["var(--primary)", "var(--primary-strong)", "var(--flower-center)", "var(--good)"];
  const fill = fills[idx % fills.length];
  const c = size / 2;
  const ring = size * 0.26;
  const nodes = [];
  for (let i = 0; i < petals; i++) {
    const a = (i / petals) * Math.PI * 2;
    const px = c + Math.cos(a) * ring;
    const py = c + Math.sin(a) * ring;
    nodes.push(html`<ellipse key=${i} cx=${px} cy=${py} rx=${size * 0.15} ry=${size * 0.26}
      transform=${`rotate(${(a * 180) / Math.PI + 90} ${px} ${py})`} fill=${fill} />`);
  }
  return html`<svg width=${size} height=${size} viewBox=${`0 0 ${size} ${size}`} aria-hidden="true"
      style=${{ display: "block" }}>
    ${nodes}
    <circle cx=${c} cy=${c} r=${size * 0.17} fill="var(--flower-center)" />
  </svg>`;
}

// A quiet garden wash behind the Stretch screen: the plan's own lavender
// breathing down from the top, and two faint blooms resting in the corners like
// pressed flowers. Purely decorative and fully static — no motion, nothing to
// gate — and whisper-faint so every card stays legible. Port of Swift's
// StretchGardenBackdrop; its hand-drawn FlowerArt has no web port, so the
// shop's procedural blooms stand in.
function GardenBackdrop({ ctx }) {
  const { html } = ctx;
  return html`<div aria-hidden="true" style=${{
    position: "fixed", top: 0, bottom: 0, left: "50%", transform: "translateX(-50%)",
    width: "100%", maxWidth: "var(--screen-max, 440px)", overflow: "hidden",
    pointerEvents: "none", zIndex: 0,
  }}>
    <div style=${{ position: "absolute", inset: 0,
      background: "linear-gradient(to bottom, color-mix(in srgb, var(--phase-luteal-soft) 55%, transparent), transparent 50%)" }} />
    <div style=${{ position: "absolute", top: -24, right: -60, opacity: 0.06, transform: "rotate(-14deg)" }}>
      <${Bloom} ctx=${ctx} id="camellia" size=${210} /></div>
    <div style=${{ position: "absolute", bottom: -36, left: -46, opacity: 0.05, transform: "rotate(18deg)" }}>
      <${Bloom} ctx=${ctx} id="daisy" size=${170} /></div>
  </div>`;
}

// Posey — a simplified storybook coach flower (bloom + face + leaf arms) with a
// named speech bubble. ponytail: the SwiftUI CoachFlower animates (sway/wave/blink/
// watering); here she's a calm static bloom — same warmth, no animation loop.
function CoachFlower({ ctx, message }) {
  const { html, ui } = ctx;
  const { FlowerMark } = ui;
  // The crown she chained on her ring, resting on Posey's petals — same blooms,
  // same order, as the ring, through the same crownSpot geometry the garden's
  // chain tutorial draws its practice Posey with (CoachFlower.crownSpot in Swift).
  const chain = (rewards.ringChain ?? []).slice(0, 7);   // a crown, not a hedge
  const crowned = (rewards.poseyCrowned ?? false) && chain.length >= 3;
  const crown = crowned && html`<div aria-hidden="true" style=${{ position: "absolute", inset: 0, pointerEvents: "none" }}>
    ${chain.map((id, i) => {
      const spot = crownSpot(i, chain.length);
      return html`<span key=${i} style=${{ position: "absolute", left: "50%", top: "50%",
        transform: `translate(-50%, -50%) translate(${spot.x}px, ${spot.y}px) rotate(${spot.tilt}deg)` }}>
        <${Bloom} ctx=${ctx} id=${id} size=${11} /></span>`;
    })}
  </div>`;
  return html`<div style=${{ display: "flex", alignItems: "flex-start", gap: 12 }}>
    <div style=${{ position: "relative", width: 60, flex: "0 0 auto", display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style=${{ position: "relative", lineHeight: 0 }}>
        ${FlowerMark ? html`<${FlowerMark} size=${46} />` : html`<div style=${{ width: 46, height: 46, borderRadius: "50%", background: "var(--primary)" }} />`}
        <div style=${{ position: "absolute", left: 0, right: 0, top: "52%", display: "flex", flexDirection: "column", alignItems: "center", gap: 2 }}>
          <div style=${{ display: "flex", gap: 5 }}>
            <span style=${{ width: 3, height: 5, borderRadius: 3, background: "var(--bloom-ink, var(--deep))" }} />
            <span style=${{ width: 3, height: 5, borderRadius: 3, background: "var(--bloom-ink, var(--deep))" }} />
          </div>
          <div style=${{ width: 6, height: 3, borderBottom: "1.1px solid var(--bloom-ink, var(--deep))", borderRadius: "0 0 6px 6px", opacity: 0.75 }} />
        </div>
        ${crown}
      </div>
      <div style=${{ width: 3, height: 20, background: "var(--good)", borderRadius: 3 }} />
    </div>
    <div style=${{ flex: 1, background: "var(--surface)", border: "1px solid var(--line)", borderRadius: "var(--radius-md)", padding: "11px 14px" }}>
      <div style=${{ fontSize: "var(--text-2xs)", fontWeight: 700, letterSpacing: "0.12em", color: "var(--primary-strong)" }}>POSEY</div>
      <div style=${{ fontSize: "var(--text-sm)", fontWeight: 500, color: "var(--text)", lineHeight: 1.5, marginTop: 2 }}>${message}</div>
    </div>
  </div>`;
}

// A move's cue row: pose figure, name (+ strike when checked), hold, cue.
function MoveRow({ ctx, move, checked, onToggle }) {
  const { html } = ctx;
  const inner = html`<div style=${{ display: "flex", alignItems: "flex-start", gap: 10 }}>
    <span style=${{ color: checked ? "var(--good)" : "var(--line)", flex: "0 0 auto", marginTop: 1 }}>
      <${ctx.Icon} name=${checked ? "check" : "circle"} size=${20} /></span>
    <${PoseFigure} ctx=${ctx} move=${move} size=${24} />
    <div style=${{ flex: 1, minWidth: 0 }}>
      <div style=${{ display: "flex", justifyContent: "space-between", gap: 8, alignItems: "baseline" }}>
        <span style=${{ fontSize: "var(--text-base)", fontWeight: 600, color: "var(--text)", textDecoration: checked ? "line-through" : "none", textDecorationColor: "var(--muted)" }}>${move.name}</span>
        <span style=${{ fontSize: "var(--text-xs)", fontWeight: 500, color: "var(--muted)", flex: "0 0 auto" }}>${move.hold}</span>
      </div>
      <div style=${{ fontSize: "var(--text-sm)", color: "var(--muted)", lineHeight: 1.5, marginTop: 2 }}>${move.cue}</div>
    </div>
  </div>`;
  // The label carries the hold time with the name (the coaching cue is the
  // visible text below), mirroring StretchCoachView's VoiceOver label + hint.
  return html`<button onClick=${onToggle} aria-pressed=${checked} aria-label=${`${move.name}, ${move.hold}`}
    style=${{ display: "block", width: "100%", textAlign: "left", background: "none", border: "none", padding: "6px 0", cursor: "pointer", minHeight: "var(--tap-min)" }}>${inner}</button>`;
}

export default function StretchScreen({ ctx }) {
  const { store, nav, html, ui, Icon, today } = ctx;
  const { Card, Button } = ui;
  const [expandedDay, setExpandedDay] = useState(null);
  const [showEvidence, setShowEvidence] = useState(false);
  const [showSafety, setShowSafety] = useState(false);
  // The no-schedule card rests folded.
  const [anytimeExpanded, setAnytimeExpanded] = useState(false);
  const [penaltyCharged, setPenaltyCharged] = useState(0);

  const p = store.prediction(today);
  const tier = lib.tierFor(store.stretchTier);
  const isTrio = tier.key === "trio";
  const daysUntil = p.daysUntilNextPeriod;
  // The trio is every day's session; the scheduled modes only light up inside
  // their window.
  const todaySession = isTrio
    ? lib.anytimeSession
    : (daysUntil != null && daysUntil >= 1 && daysUntil <= tier.totalDays ? lib.session(daysUntil, tier) : null);
  const activeSession = todaySession ?? lib.anytimeSession;
  // Points multiplier: anytime x1, 3-day starter x2, full 14-day x4.
  const multiplier = (isTrio || !todaySession) ? 1 : tier.multiplier;

  const movesDone = store.stretchMovesDone(today);
  const dayDone = store.stretchDone(today);

  // Date that a given plan-day falls on (for schedule + window done-state).
  // Every plan day always maps to a real date — with no prediction the window
  // starts today — so every schedule checkbox is always live (the extracted,
  // self-checked math in stretchLibrary).
  const dateForPlanDay = (pd) => lib.dateForPlanDay(pd, tier, p.nextPeriodStart, today);
  const isDone = (pd) => store.stretchDone(dateForPlanDay(pd));

  // Re-anchor the accounting to a given day: nothing before it is ever
  // chargeable. The rewards side owns the penalty ledger; tell it too if it
  // grows an anchor API (that change lands in parallel).
  const setActivation = (dateKey) => {
    localStorage.setItem(ACTIVATION_KEY, dateKey);
  };

  // Lock-in accounting: a missed past plan day costs 5 petals, charged once ever
  // per day. Trio never penalizes; days before the plan was activated are never
  // chargeable at all. Runs on open and on a tier switch so the penalty note
  // never shows a stale count from the previous plan (StretchCoachView:
  // onAppear / onChange(of: stretchTierRaw)).
  useEffect(() => {
    // Trio never penalizes — and must also clear any note left over from a
    // lock-in tier, or the "petals drifted off" line goes stale on switch.
    if (!tier.locksIn || tier.totalDays === 0) { setPenaltyCharged(0); return; }
    const start = startOfDay(today);
    // While there's no prediction the window is unknown (it slides with today
    // and can never charge) — keep sliding the anchor too, so when the FIRST
    // prediction lands and pins the window into real dates, it can only reach
    // back to the last day the window was still unknown. Also anchors the very
    // first run ever: nothing before "she started" is chargeable.
    let activation = localStorage.getItem(ACTIVATION_KEY);
    if (!activation || daysUntil == null) {
      activation = store.key(start);
      setActivation(activation);
    }
    let charged = 0;
    for (let pd = 1; pd <= tier.totalDays; pd++) {
      const d = dateForPlanDay(pd);
      if (d >= start || store.stretchDone(d)) continue;
      const k = store.key(d);
      if (k < activation) rewards.excuseMissedDay(k);
      else if (rewards.penalizeMissedDay(k)) charged += 1;
    }
    setPenaltyCharged(charged);
  }, [tier.key]);

  // Streak: consecutive days done, ending today (or yesterday, so an unfinished
  // today never breaks the run). The store owns the definition now, so this
  // screen and the guided session's finish card can never drift apart.
  const streak = store.stretchStreak(today);
  const totalLogged = store.logsSnapshot.filter((l) => l.stretchDone).length;

  const coachLine = coachMessage({ store, today, p, todaySession });

  const sessionFinishTitle = (!isTrio && todaySession)
    ? `Day ${lib.planDay(todaySession, tier)} done` : "Session done";
  // A session run from a plan day's schedule row passes THAT day as logDate, so
  // completions and petals land on that date — matching the row's own checkboxes
  // (no lost completions, no double-earning). Omitted, it defaults to today.
  const play = (day, finishTitle, logDate) => nav.open("session", { day, finishTitle, multiplier, logDate });

  // One pose, one checkmark. `d` defaults to today; schedule rows pass their own
  // day so every plan day's poses check off (and pay) on that date. Checking a
  // pose ON pays; UNchecking takes the same points back, so toggling can't farm
  // petals. Finishing the set rings her chime.
  const toggleMove = (i, s, d = today) => {
    const before = store.stretchMovesDone(d);
    const checked = before.includes(i);
    const wasFullDay = before.length === s.moves.length;
    const completedDay = store.toggleStretchMove(i, d, s.moves.length);
    if (!checked) awardPose(store.key(d), before.length, s.moves.length, multiplier);
    else revokePose(store.key(d), Math.max(before.length - 1, 0), s.moves.length, wasFullDay, multiplier);
    if (completedDay) rewards.playCelebrationIfOwned();
  };

  // ---- plan bar: her mode, right at the top — all three choices visible all
  // the time, one tap to switch (no hidden menus to discover). The segments
  // carry the name and points multiplier; the line beneath explains the one
  // she's on.
  const planNote = (t) =>
    t.key === "trio" ? "Any day, no schedule, no pressure"
    : t.key === "starter" ? "The 3 days before your period · −5 a missed day"
    : "The full two weeks · −5 a missed day";

  // Plain-prose plan description — no midpoints or minus glyphs for screen readers.
  const planA11yLabel = (t) => {
    const how = t.key === "trio" ? "any day, no schedule, no pressure"
      : t.key === "starter" ? "the 3 days before your period, 5 petals lost per missed day"
      : "the full two weeks before your period, 5 petals lost per missed day";
    return `${t.label}, ${how}, up to ${lib.maxDailyPoints(t)} petals a day`;
  };

  const selectTier = (t) => {
    if (t.key === tier.key) return;
    // Re-anchor the accounting: a freshly chosen plan starts today, so its
    // window days in the past can never be billed retroactively.
    setActivation(store.key(startOfDay(today)));
    store.stretchTier = t.key;
    setExpandedDay(null);
  };

  const planSegment = (t, name) => {
    const selected = tier.key === t.key;
    return html`<button key=${t.key} onClick=${() => selectTier(t)}
      aria-pressed=${selected} aria-label=${planA11yLabel(t)}
      style=${{ flex: 1, minWidth: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
        gap: 1, padding: "7px 4px", minHeight: "var(--tap-min)", cursor: "pointer", border: "none",
        background: selected ? "var(--primary-strong)" : "transparent", borderRadius: "var(--radius-sm)" }}>
      <span style=${{ fontSize: "var(--text-sm)", fontWeight: 700, whiteSpace: "nowrap",
        color: selected ? "var(--text-on-primary)" : "var(--text)" }}>${name}</span>
      <span style=${{ fontSize: "var(--text-2xs)", fontWeight: 600, whiteSpace: "nowrap",
        color: selected ? "var(--text-on-primary)" : "var(--muted)" }}>×${t.multiplier} petals</span>
    </button>`;
  };

  const planBar = () => html`<div style=${{ display: "flex", flexDirection: "column", gap: 8 }}>
    <span style=${{ fontSize: "var(--text-2xs)", fontWeight: 700, letterSpacing: "0.08em", color: "var(--muted)" }}>YOUR PLAN</span>
    <div role="group" aria-label="Plan choices"
      style=${{ display: "flex", gap: 4, padding: 4, background: "var(--surface-soft)", borderRadius: "var(--radius-md)" }}>
      ${planSegment(lib.TIERS.trio, "Anytime")}
      ${planSegment(lib.TIERS.starter, "3-day")}
      ${planSegment(lib.TIERS.full, "14-day")}
    </div>
    <div style=${{ display: "flex", alignItems: "baseline", gap: 8 }}>
      <span style=${{ flex: 1, fontSize: "var(--text-xs)", color: "var(--muted)" }}>${planNote(tier)}</span>
      <span style=${{ fontSize: "var(--text-xs)", fontWeight: 700, color: "var(--deep)", flex: "0 0 auto" }}>up to ${lib.maxDailyPoints(tier)}/day</span>
    </div>
    <div style=${{ fontSize: "var(--text-2xs)", color: "var(--muted)" }}>Switching keeps every point and completion.</div>
  </div>`;

  // ---- today's session card ----
  // Collapsible cards fold to just the header — one tap opens (Swift's
  // anytimeExpanded: the no-schedule card rests folded so the schedule leads).
  // A live little ring: poses done today out of the session (StretchCoachView's
  // 34pt progress ring). The count is the reward — she can watch the session
  // close itself without opening the guided player.
  const poseRing = (s) => {
    const total = s.moves.length;
    const done = movesDone.length;
    const R = 15, C = 2 * Math.PI * R;                    // r=15 in a 34 box
    return html`<span role="img" aria-label=${`${done} of ${total} poses done`}
      style=${{ position: "relative", width: 34, height: 34, flex: "0 0 auto", display: "inline-flex" }}>
      <svg width=${34} height=${34} viewBox="0 0 34 34" aria-hidden="true" style=${{ display: "block" }}>
        <circle cx=${17} cy=${17} r=${R} fill="none" stroke="var(--surface-soft)" stroke-width=${4} />
        <circle cx=${17} cy=${17} r=${R} fill="none" stroke="var(--phase-luteal)" stroke-width=${4}
          stroke-linecap="round" stroke-dasharray=${C} transform="rotate(-90 17 17)"
          stroke-dashoffset=${C * (1 - (total ? done / total : 0))}
          style=${{ transition: reduceMotion() ? "none" : "stroke-dashoffset var(--dur-base) var(--ease-signature)" }} />
      </svg>
      <span aria-hidden="true" style=${{ position: "absolute", inset: 0, display: "flex", alignItems: "center",
        justifyContent: "center", fontSize: "var(--text-2xs)", fontWeight: 600, color: "var(--deep)",
        fontVariantNumeric: "tabular-nums" }}>${done}/${total}</span>
    </span>`;
  };

  const todayCard = (s, heading, collapsible = false) => {
    const open = !collapsible || anytimeExpanded;
    return html`<${Card}>
    <div style=${{ display: "flex", flexDirection: "column", gap: 14 }}>
      <button onClick=${() => collapsible && setAnytimeExpanded(!anytimeExpanded)}
        disabled=${!collapsible} aria-expanded=${collapsible ? open : undefined}
        style=${{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", gap: 8,
          width: "100%", textAlign: "left", background: "none", border: "none", padding: 0,
          cursor: collapsible ? "pointer" : "default", color: "inherit" }}>
        <div>
          <div style=${{ fontSize: "var(--text-2xs)", fontWeight: 700, letterSpacing: "0.08em", color: "var(--muted)" }}>${heading}</div>
          <div style=${{ fontFamily: "var(--font-display)", fontSize: "var(--text-lg)", fontWeight: 600, color: "var(--deep)", marginTop: 2 }}>${s.focus}</div>
        </div>
        <div style=${{ display: "flex", alignItems: "center", gap: 8, flex: "0 0 auto" }}>
          ${poseRing(s)}
          <span style=${{ fontSize: "var(--text-sm)", fontWeight: 600, color: "var(--phase-luteal)" }}>${s.minutes} min</span>
          ${collapsible && html`<span style=${{ color: "var(--muted)", display: "inline-flex", transform: open ? "rotate(180deg)" : "none", transition: "transform var(--dur-fast)" }}><${Icon} name="chevron-down" size=${16} /></span>`}
        </div>
      </button>

      ${open && html`${s.moves.map((m, i) => html`<${MoveRow} key=${m.id} ctx=${ctx} move=${m}
        checked=${movesDone.includes(i)} onToggle=${() => toggleMove(i, s)} />`)}

      ${!dayDone && html`<${Button} variant="primary" block=${true}
        iconLeft=${html`<${Icon} name="activity" size=${18} />`}
        onClick=${() => play(activeSession, sessionFinishTitle)}>Start guided session</${Button}>`}

      <button onClick=${() => {
        const finishing = !dayDone;
        store.setStretchDone(finishing, today);
        if (finishing) rewards.playCelebrationIfOwned();
      }}
        style=${{ display: "flex", alignItems: "center", gap: 8, width: "100%", background: "none", border: "none", padding: 0, cursor: "pointer", minHeight: "var(--tap-min)" }}>
        <span style=${{ color: dayDone ? "var(--good)" : "var(--muted)" }}><${Icon} name=${dayDone ? "check" : "circle"} size=${19} /></span>
        <span style=${{ fontSize: "var(--text-sm)", fontWeight: 600, color: "var(--text)" }}>${dayDone ? "Today's stretching: done" : "Mark the whole day done"}</span>
      </button>`}
    </div>
  </${Card}>`;
  };

  // ---- window progress strip ----
  const progressStrip = () => {
    const doneCount = Array.from({ length: tier.totalDays }, (_, i) => i + 1).filter(isDone).length;
    return html`<${Card} variant="soft">
      <div style=${{ display: "flex", justifyContent: "space-between", marginBottom: 8 }}>
        <span style=${{ fontSize: "var(--text-sm)", fontWeight: 600, color: "var(--deep)" }}>This window</span>
        <span style=${{ fontSize: "var(--text-sm)", fontWeight: 700, color: "var(--phase-luteal)" }}>${doneCount} of ${tier.totalDays} days</span>
      </div>
      <div style=${{ display: "flex", gap: 3 }}>
        ${Array.from({ length: tier.totalDays }, (_, i) => html`<div key=${i}
          style=${{ flex: 1, height: 6, borderRadius: 999, background: isDone(i + 1) ? "var(--phase-luteal)" : "var(--surface)" }} />`)}
      </div>
    </${Card}>`;
  };

  const penaltyNote = () => html`<div style=${{ fontSize: "var(--text-xs)", color: "var(--muted)" }}>
    ${penaltyCharged * 5} petals drifted off for ${penaltyCharged === 1 ? "a missed day" : "missed days"}. Today's a fresh bloom.
  </div>`;

  // ---- out-of-window notice ----
  const outOfWindow = () => {
    let title, body;
    if (p.phase === "menstrual") {
      title = "You're on your period";
      body = "Gentle knees-to-chest and child's pose can still ease cramps today. The plan picks back up before your next period. The schedule is below.";
    } else if (daysUntil == null) {
      title = "Your plan appears with a bit of history";
      body = "Log a couple of cycles and the plan will time itself to the days before your period.";
    } else {
      title = "Your plan starts soon";
      const start = dateForPlanDay(1);
      body = start
        ? `The ${tier.label.toLowerCase()} starts around ${ctx.fmt.shortDate(start)}. The schedule is below.`
        : "It runs in the days before your period. The schedule is below.";
    }
    return html`<${Card} variant="soft">
      <div style=${{ fontSize: "var(--text-md)", fontWeight: 600, color: "var(--deep)", marginBottom: 6 }}>${title}</div>
      <div style=${{ fontSize: "var(--text-sm)", color: "var(--muted)", lineHeight: 1.6 }}>${body}</div>
    </${Card}>`;
  };

  // ---- schedule (per-mode, expandable, with day check-offs) ----
  // The day's own checkbox — EVERY day is tappable: past days back-fill, today
  // counts, and future days can be done early (her plan, her pace). Completing
  // rings her chime. Full 44px hit target — the glyph stays 20px, only the
  // touchable area grows (and pulls clear of the expand button).
  const dayCheckbox = (pd) => {
    const done = isDone(pd);
    return html`<button aria-pressed=${done}
      aria-label=${done ? `Day ${pd} done` : `Mark day ${pd} done`}
      onClick=${() => {
        const d = dateForPlanDay(pd);
        const finishing = !store.stretchDone(d);
        store.setStretchDone(finishing, d);
        if (finishing) rewards.playCelebrationIfOwned();
      }}
      style=${{ display: "inline-flex", alignItems: "center", justifyContent: "center", flex: "0 0 auto",
        width: "var(--tap-min)", height: "var(--tap-min)", background: "none", border: "none", padding: 0,
        cursor: "pointer", color: done ? "var(--good)" : "var(--muted)" }}>
      <${Icon} name=${done ? "check" : "circle"} size=${20} />
    </button>`;
  };

  // The full spoken row: screen readers hear the date and today-badge state the
  // eyes get from the chips, so back-filling checkboxes stays navigable.
  const scheduleRowLabel = (pd, d, isTodayRow, rowDate) => {
    let label = `Day ${pd}`;
    if (isTodayRow) label += ", today";
    label += `, ${rowDate.toLocaleDateString(undefined, { month: "long", day: "numeric" })}`;
    return `${label}, ${d.focus}, ${d.minutes} minutes`;
  };

  const scheduleRow = (d) => {
    const pd = lib.planDay(d, tier);
    // Today is decided by the DATE the row writes to, so the badge also appears
    // in the no-prediction fallback window (day 1 = today).
    const rowDate = dateForPlanDay(pd);
    const isTodayRow = isSameDay(rowDate, today);
    const expanded = expandedDay === pd;
    return html`<div key=${d.id}>
      <div style=${{ display: "flex", alignItems: "center", gap: 10, padding: "4px 0" }}>
        ${dayCheckbox(pd)}
        <button onClick=${() => setExpandedDay(expanded ? null : pd)}
          aria-expanded=${expanded} aria-label=${scheduleRowLabel(pd, d, isTodayRow, rowDate)}
          style=${{ display: "flex", alignItems: "center", gap: 10, flex: 1, minWidth: 0, background: "none", border: "none", padding: "5px 0", cursor: "pointer", textAlign: "left", minHeight: "var(--tap-min)" }}>
          <span style=${{ flex: 1, minWidth: 0 }}>
            <span style=${{ display: "flex", alignItems: "center", gap: 6 }}>
              <span style=${{ fontSize: "var(--text-sm)", fontWeight: 700, color: isTodayRow ? "var(--primary-strong)" : "var(--deep)" }}>Day ${pd}</span>
              ${isTodayRow && html`<span style=${{ fontSize: "var(--text-2xs)", fontWeight: 700, color: "var(--text-on-primary)", background: "var(--primary-strong)", borderRadius: 999, padding: "2px 7px" }}>today</span>`}
              <span style=${{ fontSize: "var(--text-2xs)", color: "var(--muted)" }}>${ctx.fmt.monthShort(rowDate.getMonth())} ${rowDate.getDate()}</span>
            </span>
            <span style=${{ display: "block", fontSize: "var(--text-sm)", color: "var(--text)" }}>${d.focus}</span>
          </span>
          <span style=${{ fontSize: "var(--text-xs)", color: "var(--muted)", flex: "0 0 auto" }}>${d.minutes}m</span>
          <span style=${{ color: "var(--muted)", flex: "0 0 auto", display: "inline-flex", transform: expanded ? "rotate(180deg)" : "none", transition: "transform var(--dur-fast)" }}><${Icon} name="chevron-down" size=${16} /></span>
        </button>
      </div>
      ${expanded && html`<div style=${{ paddingLeft: 54, paddingBottom: 12, display: "flex", flexDirection: "column", gap: 8, alignItems: "flex-start" }}>
        ${isTodayRow
          // Today's moves are the real thing — check them off right here.
          ? html`${d.moves.map((m, i) => html`<${MoveRow} key=${m.id} ctx=${ctx} move=${m}
              checked=${movesDone.includes(i)} onToggle=${() => toggleMove(i, d)} />`)}
            <${Button} variant="soft" size="sm" iconLeft=${html`<${Icon} name="activity" size=${16} />`}
              onClick=${() => play(d, sessionFinishTitle, rowDate)}>Start guided session</${Button}>`
          // Every plan day's poses get their own checkmarks, checked off (and
          // paid) on THAT day's date — back-fill or work ahead.
          : html`${d.moves.map((m, i) => html`<${MoveRow} key=${m.id} ctx=${ctx} move=${m}
              checked=${store.stretchMovesDone(rowDate).includes(i)} onToggle=${() => toggleMove(i, d, rowDate)} />`)}
            <${Button} variant="soft" size="sm" iconLeft=${html`<${Icon} name="activity" size=${16} />`}
              onClick=${() => play(d, "Session done", rowDate)}>Do this session now</${Button}>`}
      </div>`}
    </div>`;
  };

  const scheduleCard = () => {
    const days = lib.daysFor(tier);
    return html`<${Card}>
      <div style=${{ fontSize: "var(--text-md)", fontWeight: 600, color: "var(--deep)" }}>${tier.key === "starter" ? "The 3 days" : "The 14 days"}</div>
      <div style=${{ fontSize: "var(--text-xs)", color: "var(--muted)", margin: "2px 0 6px" }}>Tap a day for its moves, run any session guided, and check off any day, even ahead of schedule.</div>
      ${days.map((d, i) => html`<div key=${d.id}>
        ${scheduleRow(d)}
        ${i < days.length - 1 && html`<div style=${{ height: 1, background: "var(--line)" }} />`}
      </div>`)}
    </${Card}>`;
  };

  // ---- evidence + safety (disclosure) ----
  const disclosure = (open, setOpen, title, body) => html`<${Card} variant=${title === "Before you start" ? "outline" : "plain"}>
    <button onClick=${() => setOpen(!open)} aria-expanded=${open}
      style=${{ display: "flex", justifyContent: "space-between", alignItems: "center", width: "100%", background: "none", border: "none", padding: 0, cursor: "pointer" }}>
      <span style=${{ fontSize: "var(--text-md)", fontWeight: 600, color: "var(--deep)" }}>${title}</span>
      <span style=${{ color: "var(--primary-strong)", transform: open ? "rotate(180deg)" : "none", transition: "transform var(--dur-fast)" }}><${Icon} name="chevron-down" size=${18} /></span>
    </button>
    ${open && html`<div style=${{ marginTop: 12 }}>${body}</div>`}
  </${Card}>`;

  // The readable short report first, then the specific citations.
  const evidenceBody = html`<div style=${{ display: "flex", flexDirection: "column", gap: 8 }}>
    <p style=${{ margin: 0, fontSize: "var(--text-sm)", color: "var(--text)", lineHeight: 1.6 }}>${lib.stretchingReport}</p>
    <p style=${{ margin: 0, fontSize: "var(--text-xs)", color: "var(--muted)", lineHeight: 1.5 }}>${lib.evidenceNote}</p>
    <p style=${{ margin: 0, fontSize: "var(--text-xs)", color: "var(--muted)", lineHeight: 1.5 }}>${lib.dosingNote}</p>
    <p style=${{ margin: 0, fontSize: "var(--text-xs)", fontWeight: 500, color: "var(--muted)", lineHeight: 1.5 }}>${lib.disclaimer}</p>
  </div>`;

  const safetyBody = html`<div style=${{ display: "flex", flexDirection: "column", gap: 8 }}>
    ${lib.contraindications.map((item, i) => html`<div key=${i} style=${{ display: "flex", gap: 8, alignItems: "flex-start" }}>
      <span style=${{ width: 5, height: 5, borderRadius: "50%", background: "var(--primary)", flex: "0 0 auto", marginTop: 7 }} />
      <span style=${{ fontSize: "var(--text-sm)", color: "var(--text)", lineHeight: 1.5 }}>${item}</span>
    </div>`)}
  </div>`;

  return html`<div>
    <${GardenBackdrop} ctx=${ctx} />
    <div class="pad" style=${{ position: "relative", zIndex: 1, display: "flex", flexDirection: "column", gap: "var(--gap-card)" }}>
    ${planBar()}
    <${CoachFlower} ctx=${ctx} message=${coachLine} />

    <div style=${{ display: "flex", gap: "var(--gap-card)" }}>
      <${ui.StatTile} tone="soft" value=${streak} unit=${streak === 1 ? "day" : "days"} label="Current streak"
        icon=${html`<${Icon} name="activity" size=${18} />`} style=${{ flex: 1 }} />
      <${ui.StatTile} tone="soft" value=${totalLogged} label="Days stretched"
        icon=${html`<${Icon} name="check" size=${18} />`} style=${{ flex: 1 }} />
    </div>

    ${todaySession
      ? html`${todayCard(todaySession, isTrio ? "TODAY · THE CORE TRIO" : `TODAY · DAY ${lib.planDay(todaySession, tier)} OF ${tier.totalDays}`)}
          ${!isTrio && progressStrip()}
          ${penaltyCharged > 0 && penaltyNote()}`
      // Stretching is never locked: any day, she can run and check off a
      // session — it logs to today like any other. Folded by default so the
      // schedule below leads; one tap opens it.
      : html`${outOfWindow()}${todayCard(lib.anytimeSession, "ANYTIME SESSION · NO SCHEDULE NEEDED", true)}`}

    ${!isTrio && scheduleCard()}
    ${disclosure(showEvidence, setShowEvidence, "Why this may help", evidenceBody)}
    ${disclosure(showSafety, setShowSafety, "Before you start", safetyBody)}
    </div>
  </div>`;
}

// The coach's voice — warm, specific, never nagging (ported from StretchCoachView).
function coachMessage({ store, today, p, todaySession }) {
  const dayNumber = today.getDate();
  const done = store.stretchMovesDone(today);
  if (store.stretchDone(today)) {
    return ["All done. I'm so proud I could wilt. Rest those roots.",
      "Beautiful work today, petal. Even the sun took notes.",
      "Stretches complete. Somewhere, a garden applauds."][dayNumber % 3];
  }
  if (done.length) {
    return ["You've started, and that's the hard part. Keep going, petal.",
      "Look at you go. A couple more and we're done.",
      "Halfway feelings are the best feelings, I always say."][dayNumber % 3];
  }
  if (todaySession) {
    return ["Ready when you are. Even five gentle minutes counts.",
      `Just ${todaySession.minutes} easy minutes today. I'll be right here on my stem.`,
      "No rush, petal. We bloom on our own schedule."][dayNumber % 3];
  }
  if (p.phase === "menstrual") {
    return ["Rest week, petal. A gentle knees-to-chest still helps if cramps bite.",
      "You made it. Be soft with yourself this week."][dayNumber % 2];
  }
  return ["No schedule today, but stretching is always in season. Care for a quick trio?",
    "Off-plan days are my favorite: no rules, just a little reach and bend.",
    "I'll wave when your plan starts. Meanwhile, the anytime session is right below."][dayNumber % 3];
}
