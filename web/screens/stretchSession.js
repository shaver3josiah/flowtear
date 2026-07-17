// Guided stretch session — the interactive player. Port of
// App/Views/StretchSessionView.swift. One move at a time: a timer ring counts the
// hold, the cue sits underneath, and finishing marks the day done with a petal
// celebration. Pause, skip, or step back anytime. Each move it finishes is checked
// off through store.toggleStretchMove (never unchecked), so the coach's checklist and
// window progress stay in sync; the last move sets stretchDone. Close ends the session.
// Each move pays its pose points at her plan's multiplier, plus +30 the first time
// she's ever guided through that pose. Everything logs to `logDate` — today, unless
// the session was launched from a plan day's schedule row (then it's that day).
import * as lib from "../core/stretchLibrary.js";
import { rewards } from "../core/rewards.js";

const React = window.React;
const { useState, useEffect } = React;

// rewards' per-day pose ledger is dateKey-first (see rewards.js awardPose).
const awardPose = (dateKey, alreadyDone, total, multiplier) =>
  rewards.awardPose(dateKey, alreadyDone, total, multiplier);

// Inline pose figure (ported PoseShape geometry) or a themed icon fallback.
// ponytail: small duplicate of stretch.js's figure — a shared helper would need a 4th
// file the task scopes out; 12 lines is cheaper than the plumbing.
function PoseFigure({ ctx, move, size, color = "var(--phase-luteal)" }) {
  const { html, Icon } = ctx;
  const shape = lib.POSE_SHAPES[lib.poseKind(move.name)];
  if (!shape) {
    const name = move.icon === "wind" ? "wind" : "activity";
    return html`<span style=${{ color, display: "inline-flex", width: size, height: size, alignItems: "center", justifyContent: "center" }}><${Icon} name=${name} size=${Math.round(size * 0.75)} /></span>`;
  }
  const [hx, hy, hr] = shape.head;
  return html`<svg viewBox="0 0 1 1" width=${size} height=${size} fill="none" stroke=${color}
      stroke-width=${0.075} stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" style=${{ display: "block" }}>
    <circle cx=${hx} cy=${hy} r=${hr} />
    ${shape.paths.map((d, i) => html`<path key=${i} d=${d} />`)}
  </svg>`;
}

export default function StretchSession({ ctx }) {
  const { store, nav, html, ui, Icon, today, screenProps } = ctx;
  const { Button, IconButton } = ui;

  const day = screenProps && screenProps.day ? screenProps.day : lib.anytimeSession;
  const finishTitle = (screenProps && screenProps.finishTitle) || "Session done";
  const multiplier = (screenProps && screenProps.multiplier) || 1;
  // The calendar date completions and awards land on. Defaults to today; a
  // session run from a plan day's schedule row passes THAT day, so the row's
  // checkboxes light up and nothing can be earned twice.
  const logDate = (screenProps && screenProps.logDate) || today;
  const moves = day.moves;

  const [index, setIndex] = useState(0);
  const [remaining, setRemaining] = useState(() => moves[0] ? moves[0].seconds : 0);
  const [paused, setPaused] = useState(false);
  const [finished, setFinished] = useState(false);
  const [earned, setEarned] = useState(0);      // petals collected this session
  const [cheer, setCheer] = useState(null);     // Posey's between-move encouragement

  const move = moves[Math.min(index, moves.length - 1)];
  const progress = move && move.seconds > 0 ? 1 - remaining / move.seconds : 1;

  // A different whisper each transition; the midpoint gets its own. `at` is the
  // move she just landed on (state hasn't repainted yet), matching Swift's
  // sayCheer() being called after index advances.
  const sayCheer = (at) => {
    const midpoint = Math.floor(moves.length / 2);
    if (at === midpoint && moves.length >= 3) { setCheer("Halfway there. You're doing lovely."); return; }
    const lines = ["Beautiful. Next one, petal.",
      "That's it. Shoulders soft.",
      "Gorgeous work. Keep breathing.",
      "One more bloom in the garden."];
    setCheer(lines[at % lines.length]);
  };

  // Gone again in a couple of seconds (Swift's .task(id: line) sleep). Re-arms
  // per line, so a new cheer cancels the old timer instead of racing it.
  useEffect(() => {
    if (!cheer) return undefined;
    const t = setTimeout(() => setCheer(null), 2400);
    return () => clearTimeout(t);
  }, [cheer]);

  // The move she just finished counts — check it off (never uncheck), award its
  // points, and pay the first-ever-guided bonus for this pose. Then advance or
  // finish the day. Every petal it pays lands in `earned`, so the header can
  // count them up in front of her.
  const advance = () => {
    const doneBefore = store.stretchMovesDone(logDate);
    let gained = 0;
    if (!doneBefore.includes(index)) {
      store.toggleStretchMove(index, logDate, moves.length);
      gained += awardPose(store.key(logDate), doneBefore.length, moves.length, multiplier);
    }
    gained += rewards.awardGuidedFirstTime(move.name, multiplier);
    if (gained) setEarned((n) => n + gained);
    if (index + 1 < moves.length) {
      setIndex(index + 1);
      setRemaining(moves[index + 1].seconds);
      sayCheer(index + 1);
    } else {
      store.setStretchDone(true, logDate);
      rewards.playCelebrationIfOwned();
      setFinished(true);
    }
  };

  const back = () => {
    if (index === 0) return;
    setIndex(index - 1);
    setRemaining(moves[index - 1].seconds);
  };

  // One-second tick. Re-arms on each remaining/paused/finished change (captures a
  // fresh `advance`, so no stale closures). At zero, advance to the next move.
  useEffect(() => {
    if (paused || finished) return undefined;
    if (remaining <= 0) { advance(); return undefined; }
    const t = setTimeout(() => setRemaining((r) => r - 1), 1000);
    return () => clearTimeout(t);
  }, [remaining, paused, finished]);

  if (finished) {
    const { PetalRain } = ui;
    // Her run of stretch days, worn like a little medal. The store owns the
    // streak definition, so this card and the Stretch screen always agree.
    const streak = store.stretchStreak(today);
    return html`<div style=${{ position: "relative", overflow: "hidden", padding: "48px 24px calc(28px + env(safe-area-inset-bottom))", textAlign: "center" }}>
      ${PetalRain && html`<${PetalRain} count=${18} />`}
      <div style=${{ position: "relative", display: "flex", flexDirection: "column", alignItems: "center", gap: 14 }}>
        <div style=${{ color: "var(--good)", display: "flex", justifyContent: "center" }}><${Icon} name="check" size=${56} /></div>
        <div style=${{ fontFamily: "var(--font-display)", fontSize: "var(--text-2xl)", fontWeight: 700, color: "var(--deep)" }}>${finishTitle}</div>
        ${earned > 0 && html`<div style=${{ display: "grid", gap: 2 }}>
          <div style=${{ fontFamily: "var(--font-display)", fontSize: "var(--text-3xl)", fontWeight: 600, color: "var(--flower-center)", lineHeight: 1.1 }}>+${earned}</div>
          <div style=${{ fontSize: "var(--text-2xs)", fontWeight: 700, letterSpacing: "0.12em", color: "var(--muted)" }}>PETAL POINTS EARNED</div>
        </div>`}
        ${streak >= 2 && html`<div style=${{ display: "inline-flex", alignItems: "center", gap: 5, padding: "8px 14px",
          borderRadius: 999, background: "var(--surface)", border: "1px solid var(--flower-center)" }}>
          <${Icon} name="zap" size=${13} color="var(--flower-center)" />
          <span style=${{ fontSize: "var(--text-sm)", fontWeight: 700, color: "var(--deep)" }}>That makes a ${streak} day streak</span>
        </div>`}
        <div style=${{ fontSize: "var(--text-base)", color: "var(--muted)", margin: "0 0 6px", lineHeight: 1.5 }}>That's ${day.minutes} gentle minutes toward an easier period.</div>
        <${Button} variant="primary" onClick=${nav.close}>Done</${Button}>
      </div>
    </div>`;
  }

  const timeText = remaining >= 60 ? `${Math.floor(remaining / 60)}:${String(remaining % 60).padStart(2, "0")}` : `${remaining}s`;
  const C = 2 * Math.PI * 54; // ring circumference (r=54 in a 120 viewBox)

  return html`<div style=${{ display: "flex", flexDirection: "column", gap: 20, padding: "12px 20px calc(20px + env(safe-area-inset-bottom))", minHeight: "70dvh" }}>
    <div style=${{ display: "flex", flexDirection: "column", gap: 12 }}>
      <div style=${{ display: "flex", alignItems: "center", gap: 10 }}>
        <${IconButton} variant="soft" label="End session" onClick=${nav.close}><${Icon} name="x" size=${20} /></${IconButton}>
        <span style=${{ flex: 1 }} />
        ${earned > 0 && html`<span aria-label=${`${earned} petals earned so far`}
          style=${{ display: "inline-flex", alignItems: "center", gap: 4 }}>
          <${Icon} name="sparkles" size=${11} color="var(--flower-center)" />
          <span style=${{ fontSize: "var(--text-sm)", fontWeight: 600, color: "var(--deep)", fontVariantNumeric: "tabular-nums" }}>+${earned}</span>
        </span>`}
        <span style=${{ fontSize: "var(--text-sm)", fontWeight: 600, color: "var(--muted)" }}>Move ${index + 1} of ${moves.length}</span>
      </div>
      <div style=${{ display: "flex", gap: 4 }} aria-hidden="true">
        ${moves.map((m, i) => html`<div key=${i} style=${{ flex: 1, height: 4, borderRadius: 999, background: i < index ? "var(--phase-luteal)" : i === index ? "var(--primary-strong)" : "var(--surface-soft)" }} />`)}
      </div>
      ${cheer && html`<div role="status" style=${{ fontSize: "var(--text-xs)", fontWeight: 600, color: "var(--primary-strong)" }}>${cheer}</div>`}
    </div>

    <div style=${{ display: "flex", flexDirection: "column", alignItems: "center", gap: 20, flex: 1, justifyContent: "center", paddingTop: 8 }}>
      <div style=${{ position: "relative", width: 240, height: 240 }} aria-label=${`${move.name}, ${remaining} seconds left`} role="timer">
        <svg viewBox="0 0 120 120" width=${240} height=${240} style=${{ display: "block" }} aria-hidden="true">
          <circle cx=${60} cy=${60} r=${54} fill="none" stroke="var(--surface-soft)" stroke-width=${14} />
          <circle cx=${60} cy=${60} r=${54} fill="none" stroke="var(--phase-luteal)" stroke-width=${14} stroke-linecap="round"
            stroke-dasharray=${C} stroke-dashoffset=${C * (1 - Math.max(0, Math.min(1, progress)))}
            transform="rotate(-90 60 60)" style=${{ transition: "stroke-dashoffset 1s linear" }} />
        </svg>
        <div style=${{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 6 }}>
          <${PoseFigure} ctx=${ctx} move=${move} size=${62} />
          <div style=${{ fontFamily: "var(--font-display)", fontSize: "var(--text-3xl)", fontWeight: 600, color: "var(--deep)", lineHeight: 1 }}>${timeText}</div>
          <div style=${{ fontSize: "var(--text-sm)", fontWeight: 500, color: "var(--muted)" }}>${move.hold}</div>
        </div>
      </div>

      <div style=${{ textAlign: "center" }}>
        <div style=${{ fontFamily: "var(--font-display)", fontSize: "var(--text-xl)", fontWeight: 700, color: "var(--deep)" }}>${move.name}</div>
        <div style=${{ fontSize: "var(--text-base)", color: "var(--text)", lineHeight: 1.6, marginTop: 8, padding: "0 8px" }}>${move.cue}</div>
      </div>
    </div>

    <div style=${{ display: "flex", alignItems: "center", gap: 12 }}>
      <${IconButton} variant="soft" label="Previous move" onClick=${back}
        style=${{ opacity: index === 0 ? 0.4 : 1, pointerEvents: index === 0 ? "none" : "auto" }}><${Icon} name="arrow-left" size=${20} /></${IconButton}>
      <div style=${{ flex: 1 }}>
        <${Button} variant=${paused ? "primary" : "soft"} block=${true} onClick=${() => setPaused(!paused)}>${paused ? "Resume" : "Pause"}</${Button}>
      </div>
      <${IconButton} variant="soft" label="Next move" onClick=${advance}><${Icon} name="arrow-right" size=${20} /></${IconButton}>
    </div>
  </div>`;
}
