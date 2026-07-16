// Stretch — her coach. Port of App/Views/StretchCoachView.swift. Posey the flower
// cheers her on; the plan knows what day she's on automatically; every stretch is a
// checkbox; the whole day can be checked too. Three modes (core trio / 3-day starter
// default / full 14-day) switch from the plan bar at the top and never touch logged
// history — completions live on dates, in the shared store. The two scheduled modes
// lock in: a missed plan day costs 5 petals, unless her plan is paused.
// The garden header (points pill, shop, share, rules, tutorial sheets) is the garden
// feature and lives on its own screen — see web/screens/garden.js.
import * as lib from "../core/stretchLibrary.js";
import { addDays, startOfDay } from "../core/dates.js";
import { rewards } from "../core/rewards.js";

const React = window.React;
const { useState, useEffect } = React;

// Mirrors @AppStorage("flowtear.planPaused") in StretchCoachView.
const PAUSE_KEY = "flowtear.planPaused";

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

// Posey — a simplified storybook coach flower (bloom + face + leaf arms) with a
// named speech bubble. ponytail: the SwiftUI CoachFlower animates (sway/wave/blink/
// watering); here she's a calm static bloom — same warmth, no animation loop.
function CoachFlower({ ctx, message }) {
  const { html, ui } = ctx;
  const { FlowerMark } = ui;
  return html`<div style=${{ display: "flex", alignItems: "flex-start", gap: 12 }}>
    <div style=${{ position: "relative", width: 60, flex: "0 0 auto", display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style=${{ position: "relative", lineHeight: 0 }}>
        ${FlowerMark ? html`<${FlowerMark} size=${46} />` : html`<div style=${{ width: 46, height: 46, borderRadius: "50%", background: "var(--primary)" }} />`}
        <div style=${{ position: "absolute", left: 0, right: 0, top: "52%", display: "flex", flexDirection: "column", alignItems: "center", gap: 2 }}>
          <div style=${{ display: "flex", gap: 5 }}>
            <span style=${{ width: 3, height: 5, borderRadius: 3, background: "var(--deep)" }} />
            <span style=${{ width: 3, height: 5, borderRadius: 3, background: "var(--deep)" }} />
          </div>
          <div style=${{ width: 9, height: 5, borderBottom: "1.4px solid var(--deep)", borderRadius: "0 0 9px 9px" }} />
        </div>
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
  return html`<button onClick=${onToggle} aria-pressed=${checked} aria-label=${move.name}
    style=${{ display: "block", width: "100%", textAlign: "left", background: "none", border: "none", padding: "6px 0", cursor: "pointer", minHeight: "var(--tap-min)" }}>${inner}</button>`;
}

// A read-only move (schedule days that aren't today).
function MoveDetail({ ctx, move }) {
  const { html } = ctx;
  return html`<div style=${{ display: "flex", alignItems: "flex-start", gap: 10 }}>
    <${PoseFigure} ctx=${ctx} move=${move} size=${24} />
    <div style=${{ flex: 1, minWidth: 0 }}>
      <div style=${{ display: "flex", justifyContent: "space-between", gap: 8, alignItems: "baseline" }}>
        <span style=${{ fontSize: "var(--text-base)", fontWeight: 600, color: "var(--text)" }}>${move.name}</span>
        <span style=${{ fontSize: "var(--text-xs)", fontWeight: 500, color: "var(--muted)", flex: "0 0 auto" }}>${move.hold}</span>
      </div>
      <div style=${{ fontSize: "var(--text-sm)", color: "var(--muted)", lineHeight: 1.5, marginTop: 2 }}>${move.cue}</div>
    </div>
  </div>`;
}

// The ×N points-multiplier pill.
function MultiplierPill({ ctx, tier }) {
  return ctx.html`<span style=${{ fontSize: "var(--text-2xs)", fontWeight: 700, color: "var(--surface)", background: "var(--phase-luteal)", borderRadius: 999, padding: "1px 6px", flex: "0 0 auto" }}>×${tier.multiplier}</span>`;
}

export default function StretchScreen({ ctx }) {
  const { store, nav, html, ui, Icon, today } = ctx;
  const { Card, Button, Switch } = ui;
  const [expandedDay, setExpandedDay] = useState(null);
  const [planExpanded, setPlanExpanded] = useState(false);
  const [showEvidence, setShowEvidence] = useState(false);
  const [showSafety, setShowSafety] = useState(false);
  const [planPaused, setPlanPaused] = useState(() => localStorage.getItem(PAUSE_KEY) === "true");
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
  const dateForPlanDay = (pd) =>
    p.nextPeriodStart ? addDays(addDays(p.nextPeriodStart, -tier.totalDays), pd - 1) : null;
  const isDone = (pd) => {
    const d = dateForPlanDay(pd);
    return d && d <= today ? store.stretchDone(d) : false;
  };

  // Past plan days in this window she didn't stretch — the lock-in's billable set.
  const missedKeys = () => {
    if (!tier.locksIn || tier.totalDays === 0) return [];
    const start = startOfDay(today);
    const keys = [];
    for (let pd = 1; pd <= tier.totalDays; pd++) {
      const d = dateForPlanDay(pd);
      if (!d || d >= start) continue;
      if (!store.stretchDone(d)) keys.push(store.key(d));
    }
    return keys;
  };

  // Lock-in accounting: a missed past plan day costs 5 petals, charged once ever
  // per day. Trio never penalizes; while the plan is PAUSED those days are excused
  // for good instead of charged. Runs on open and whenever the pause flips
  // (StretchCoachView: onAppear / onChange(of: planPaused)).
  useEffect(() => {
    let charged = 0;
    for (const k of missedKeys()) {
      if (planPaused) rewards.excuseMissedDay(k);
      else if (rewards.penalizeMissedDay(k)) charged += 1;
    }
    setPenaltyCharged(charged);
  }, [planPaused]);

  // Pausing grants amnesty immediately; UNpausing forgives everything missed up to
  // that moment first (days that elapsed while paused must never be billed), then
  // the effect above resumes normal accounting.
  const togglePause = (next) => {
    localStorage.setItem(PAUSE_KEY, String(next));
    if (!next) for (const k of missedKeys()) rewards.excuseMissedDay(k);
    setPlanPaused(next);
  };

  // Streak: consecutive days done, ending today (or yesterday if today's not done yet).
  const streak = (() => {
    let n = 0, cursor = store.stretchDone(today) ? today : addDays(today, -1);
    while (store.stretchDone(cursor)) { n++; cursor = addDays(cursor, -1); }
    return n;
  })();
  const totalLogged = store.logsSnapshot.filter((l) => l.stretchDone).length;

  const coachLine = coachMessage({ store, today, p, todaySession });

  const sessionFinishTitle = (!isTrio && todaySession)
    ? `Day ${lib.planDay(todaySession, tier)} done` : "Session done";
  const play = (day, finishTitle) => nav.open("session", { day, finishTitle, multiplier });

  // Checking a pose ON pays; UNchecking takes the same points back, so toggling
  // can't farm petals. Finishing the set rings her chime.
  const toggleMove = (i, s) => {
    const before = store.stretchMovesDone(today);
    const checked = before.includes(i);
    const wasFullDay = before.length === s.moves.length;
    const completedDay = store.toggleStretchMove(i, today, s.moves.length);
    if (!checked) rewards.awardPose(before.length, s.moves.length, multiplier);
    else rewards.revokePose(Math.max(before.length - 1, 0), s.moves.length, wasFullDay, multiplier);
    if (completedDay) rewards.playCelebrationIfOwned();
  };

  // ---- plan bar: her mode, right at the top ----
  const rowShell = (selected) => ({
    display: "flex", alignItems: "center", gap: 10, width: "100%", textAlign: "left",
    background: selected ? "var(--surface-soft)" : "var(--surface)",
    border: `${selected ? 1.5 : 1}px solid ${selected ? "var(--primary-strong)" : "var(--line)"}`,
    borderRadius: "var(--radius-md)", padding: "10px 14px", minHeight: "var(--tap-min)",
  });

  const radio = (selected) => html`<span style=${{ width: 18, height: 18, borderRadius: "50%", flex: "0 0 auto",
    border: `2px solid ${selected ? "var(--primary-strong)" : "var(--line)"}`, display: "inline-flex", alignItems: "center", justifyContent: "center" }}>
    ${selected && html`<span style=${{ width: 8, height: 8, borderRadius: "50%", background: "var(--primary-strong)" }} />`}
  </span>`;

  const modeRow = (t, note) => {
    const selected = tier.key === t.key;
    return html`<button key=${t.key} onClick=${() => { store.stretchTier = t.key; setPlanExpanded(false); setExpandedDay(null); }}
      aria-pressed=${selected} aria-label=${`${t.label}, ${note}, up to ${lib.maxDailyPoints(t)} points a day`}
      style=${{ ...rowShell(selected), cursor: "pointer" }}>
      ${radio(selected)}
      <span style=${{ flex: 1, minWidth: 0 }}>
        <span style=${{ display: "flex", alignItems: "center", gap: 6 }}>
          <span style=${{ fontSize: "var(--text-sm)", fontWeight: 700, color: "var(--deep)" }}>${t.label}</span>
          <${MultiplierPill} ctx=${ctx} tier=${t} />
        </span>
        <span style=${{ display: "block", fontSize: "var(--text-xs)", color: "var(--muted)", marginTop: 1 }}>${note}</span>
      </span>
      <span style=${{ fontSize: "var(--text-xs)", fontWeight: 700, color: "var(--deep)", flex: "0 0 auto" }}>up to ${lib.maxDailyPoints(t)}/day</span>
    </button>`;
  };

  // Her plan, her terms: pausing excuses missed days instead of charging them.
  const pauseRow = () => html`<div style=${rowShell(false)}>
    <span style=${{ color: planPaused ? "var(--primary-strong)" : "var(--muted)", flex: "0 0 auto", display: "inline-flex" }}>
      <${Icon} name="clock" size=${17} /></span>
    <div style=${{ flex: 1, minWidth: 0 }}>
      <div style=${{ fontSize: "var(--text-sm)", fontWeight: 700, color: "var(--deep)" }}>Pause my plan</div>
      <div style=${{ fontSize: "var(--text-xs)", color: "var(--muted)", marginTop: 1 }}>Life happens — missed days cost nothing while paused</div>
    </div>
    <${Switch} checked=${planPaused} onChange=${togglePause} label="Pause my plan" />
  </div>`;

  const planBar = () => html`<div style=${{ display: "flex", flexDirection: "column", gap: 8 }}>
    <button onClick=${() => setPlanExpanded(!planExpanded)} aria-expanded=${planExpanded}
      aria-label=${`Current plan: ${tier.label}`}
      style=${{ display: "flex", alignItems: "center", gap: 8, width: "100%", textAlign: "left", cursor: "pointer",
        background: "var(--surface)", border: "1px solid var(--line)", borderRadius: "var(--radius-md)", padding: "11px 14px", minHeight: "var(--tap-min)" }}>
      <span style=${{ fontSize: "var(--text-2xs)", fontWeight: 700, letterSpacing: "0.08em", color: "var(--muted)" }}>PLAN</span>
      <span style=${{ fontSize: "var(--text-sm)", fontWeight: 700, color: "var(--deep)" }}>${tier.label}</span>
      <${MultiplierPill} ctx=${ctx} tier=${tier} />
      ${planPaused && tier.locksIn && html`<span style=${{ fontSize: "var(--text-2xs)", fontWeight: 700, color: "var(--deep)", background: "var(--surface-soft)", borderRadius: 999, padding: "1px 6px" }}>paused</span>`}
      <span style=${{ flex: 1, minWidth: 4 }} />
      <span style=${{ fontSize: "var(--text-xs)", fontWeight: 700, color: "var(--deep)", flex: "0 0 auto" }}>up to ${lib.maxDailyPoints(tier)}/day</span>
      <span style=${{ color: "var(--muted)", flex: "0 0 auto", display: "inline-flex", transform: planExpanded ? "rotate(180deg)" : "none", transition: "transform var(--dur-fast)" }}>
        <${Icon} name="chevron-down" size=${14} /></span>
    </button>
    ${planExpanded && html`<div style=${{ display: "flex", flexDirection: "column", gap: 8 }}>
      ${modeRow(lib.TIERS.trio, "Any day, no schedule, no pressure")}
      ${modeRow(lib.TIERS.starter, "The 3 days before your period · −5 a missed day")}
      ${modeRow(lib.TIERS.full, "The full two weeks · −5 a missed day")}
      ${tier.locksIn && pauseRow()}
      <div style=${{ fontSize: "var(--text-2xs)", color: "var(--muted)" }}>Switching keeps every point and completion.</div>
    </div>`}
  </div>`;

  // ---- today's session card ----
  const todayCard = (s, heading) => html`<${Card}>
    <div style=${{ display: "flex", flexDirection: "column", gap: 14 }}>
      <div style=${{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", gap: 8 }}>
        <div>
          <div style=${{ fontSize: "var(--text-2xs)", fontWeight: 700, letterSpacing: "0.08em", color: "var(--muted)" }}>${heading}</div>
          <div style=${{ fontFamily: "var(--font-display)", fontSize: "var(--text-lg)", fontWeight: 600, color: "var(--deep)", marginTop: 2 }}>${s.focus}</div>
        </div>
        <div style=${{ fontSize: "var(--text-sm)", fontWeight: 600, color: "var(--phase-luteal)", flex: "0 0 auto" }}>${s.minutes} min</div>
      </div>

      ${s.moves.map((m, i) => html`<${MoveRow} key=${m.id} ctx=${ctx} move=${m}
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
        <span style=${{ fontSize: "var(--text-sm)", fontWeight: 600, color: "var(--text)" }}>${dayDone ? "Today's stretching — done" : "Mark the whole day done"}</span>
      </button>
    </div>
  </${Card}>`;

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
    ${penaltyCharged * 5} petals drifted off for missed days — today's a fresh bloom.
  </div>`;

  // ---- out-of-window notice ----
  const outOfWindow = () => {
    let title, body;
    if (p.phase === "menstrual") {
      title = "You're on your period";
      body = "Gentle knees-to-chest and child's pose can still ease cramps today. The plan picks back up before your next period — the schedule is below.";
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
  // Her own checkbox for each day — tappable for today and past plan days; future
  // days wait their turn.
  const dayCheckbox = (pd) => {
    const done = isDone(pd);
    const d = dateForPlanDay(pd);
    const tappable = d ? d <= today : false;
    return html`<button disabled=${!tappable} aria-pressed=${done}
      aria-label=${done ? `Day ${pd} done` : `Mark day ${pd} done`}
      onClick=${() => {
        if (!d) return;
        const finishing = !store.stretchDone(d);
        store.setStretchDone(finishing, d);
        if (finishing) rewards.playCelebrationIfOwned();
      }}
      style=${{ display: "inline-flex", alignItems: "center", justifyContent: "center", flex: "0 0 auto",
        width: 30, height: "var(--tap-min)", background: "none", border: "none", padding: 0,
        cursor: tappable ? "pointer" : "default",
        color: done ? "var(--good)" : (tappable ? "var(--muted)" : "var(--line)") }}>
      <${Icon} name=${done ? "check" : "circle"} size=${20} />
    </button>`;
  };

  const scheduleRow = (d) => {
    const pd = lib.planDay(d, tier);
    const isTodayRow = !!todaySession && todaySession.daysBeforePeriod === d.daysBeforePeriod;
    const expanded = expandedDay === pd;
    const rowDate = dateForPlanDay(pd);
    return html`<div key=${d.id}>
      <div style=${{ display: "flex", alignItems: "center", gap: 10, padding: "4px 0" }}>
        ${dayCheckbox(pd)}
        <button onClick=${() => setExpandedDay(expanded ? null : pd)}
          aria-expanded=${expanded} aria-label=${`Day ${pd}, ${d.focus}, ${d.minutes} minutes`}
          style=${{ display: "flex", alignItems: "center", gap: 10, flex: 1, minWidth: 0, background: "none", border: "none", padding: "5px 0", cursor: "pointer", textAlign: "left" }}>
          <span style=${{ flex: 1, minWidth: 0 }}>
            <span style=${{ display: "flex", alignItems: "center", gap: 6 }}>
              <span style=${{ fontSize: "var(--text-sm)", fontWeight: 700, color: isTodayRow ? "var(--primary-strong)" : "var(--deep)" }}>Day ${pd}</span>
              ${isTodayRow && html`<span style=${{ fontSize: "var(--text-2xs)", fontWeight: 700, color: "var(--surface)", background: "var(--primary-strong)", borderRadius: 999, padding: "2px 7px" }}>today</span>`}
              ${rowDate && html`<span style=${{ fontSize: "var(--text-2xs)", color: "var(--muted)" }}>${ctx.fmt.monthShort(rowDate.getMonth())} ${rowDate.getDate()}</span>`}
            </span>
            <span style=${{ display: "block", fontSize: "var(--text-sm)", color: "var(--text)" }}>${d.focus}</span>
          </span>
          <span style=${{ fontSize: "var(--text-xs)", color: "var(--muted)", flex: "0 0 auto" }}>${d.minutes}m</span>
          <span style=${{ color: "var(--muted)", flex: "0 0 auto", display: "inline-flex", transform: expanded ? "rotate(180deg)" : "none", transition: "transform var(--dur-fast)" }}><${Icon} name="chevron-down" size=${16} /></span>
        </button>
      </div>
      ${expanded && html`<div style=${{ paddingLeft: 34, paddingBottom: 12, display: "flex", flexDirection: "column", gap: 8, alignItems: "flex-start" }}>
        ${isTodayRow
          // Today's moves are the real thing — check them off right here.
          ? html`${d.moves.map((m, i) => html`<${MoveRow} key=${m.id} ctx=${ctx} move=${m}
              checked=${movesDone.includes(i)} onToggle=${() => toggleMove(i, d)} />`)}
            <${Button} variant="soft" size="sm" iconLeft=${html`<${Icon} name="activity" size=${16} />`}
              onClick=${() => play(d, sessionFinishTitle)}>Start guided session</${Button}>`
          // Off-schedule days still open the guided player — the whole system is
          // hers to explore; completions log to today.
          : html`${d.moves.map((m) => html`<${MoveDetail} key=${m.id} ctx=${ctx} move=${m} />`)}
            <${Button} variant="soft" size="sm" iconLeft=${html`<${Icon} name="activity" size=${16} />`}
              onClick=${() => play(d, "Session done")}>Do this session now</${Button}>`}
      </div>`}
    </div>`;
  };

  const scheduleCard = () => {
    const days = lib.daysFor(tier);
    return html`<${Card}>
      <div style=${{ fontSize: "var(--text-md)", fontWeight: 600, color: "var(--deep)" }}>${tier.key === "starter" ? "The 3 days" : "The 14 days"}</div>
      <div style=${{ fontSize: "var(--text-xs)", color: "var(--muted)", margin: "2px 0 6px" }}>Tap any day to open its moves — and run any session guided, whenever you like.</div>
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

  const evidenceBody = html`<div style=${{ display: "flex", flexDirection: "column", gap: 8 }}>
    <p style=${{ margin: 0, fontSize: "var(--text-sm)", color: "var(--text)", lineHeight: 1.6 }}>${lib.evidenceNote}</p>
    <p style=${{ margin: 0, fontSize: "var(--text-xs)", color: "var(--muted)", lineHeight: 1.5 }}>${lib.dosingNote}</p>
    <p style=${{ margin: 0, fontSize: "var(--text-xs)", fontWeight: 500, color: "var(--muted)", lineHeight: 1.5 }}>${lib.disclaimer}</p>
  </div>`;

  const safetyBody = html`<div style=${{ display: "flex", flexDirection: "column", gap: 8 }}>
    ${lib.contraindications.map((item, i) => html`<div key=${i} style=${{ display: "flex", gap: 8, alignItems: "flex-start" }}>
      <span style=${{ width: 5, height: 5, borderRadius: "50%", background: "var(--primary)", flex: "0 0 auto", marginTop: 7 }} />
      <span style=${{ fontSize: "var(--text-sm)", color: "var(--text)", lineHeight: 1.5 }}>${item}</span>
    </div>`)}
  </div>`;

  return html`<div class="pad" style=${{ display: "flex", flexDirection: "column", gap: "var(--gap-card)" }}>
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
      : html`${outOfWindow()}${todayCard(lib.anytimeSession, "ANYTIME SESSION · NO SCHEDULE NEEDED")}`}

    ${!isTrio && scheduleCard()}
    ${disclosure(showEvidence, setShowEvidence, "Why this may help", evidenceBody)}
    ${disclosure(showSafety, setShowSafety, "Before you start", safetyBody)}
  </div>`;
}

// The coach's voice — warm, specific, never nagging (ported from StretchCoachView).
function coachMessage({ store, today, p, todaySession }) {
  const dayNumber = today.getDate();
  const done = store.stretchMovesDone(today);
  if (store.stretchDone(today)) {
    return ["All done — I'm so proud I could wilt. Rest those roots.",
      "Beautiful work today, petal. Even the sun took notes.",
      "Stretches complete. Somewhere, a garden applauds."][dayNumber % 3];
  }
  if (done.length) {
    return ["You've started — that's the hard part. Keep going, petal.",
      "Look at you go. A couple more and we're done.",
      "Halfway feelings are the best feelings, I always say."][dayNumber % 3];
  }
  if (todaySession) {
    return ["Ready when you are — even five gentle minutes counts.",
      `Just ${todaySession.minutes} easy minutes today. I'll be right here on my stem.`,
      "No rush, petal. We bloom on our own schedule."][dayNumber % 3];
  }
  if (p.phase === "menstrual") {
    return ["Rest week, petal. A gentle knees-to-chest still helps if cramps bite.",
      "You made it — be soft with yourself this week."][dayNumber % 2];
  }
  return ["No schedule today — but stretching is always in season. Care for a quick trio?",
    "Off-plan days are my favorite: no rules, just a little reach and bend.",
    "I'll wave when your plan starts. Meanwhile, the anytime session is right below."][dayNumber % 3];
}
