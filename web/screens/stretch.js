// Stretch — her coach. Port of App/Views/StretchCoachView.swift. Posey the flower
// cheers her on; the plan knows what day she's on automatically; every stretch is a
// checkbox; the whole day can be checked too. Two tiers (3-day starter default /
// full 14-day) switch manually and never touch logged history — completions live on
// dates, in the shared store. Rewards/garden/shop/share/tutorial (RewardsStore) are
// a separate feature and are intentionally not wired here.
import * as lib from "../core/stretchLibrary.js";
import { addDays } from "../core/dates.js";

const React = window.React;
const { useState } = React;

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

export default function StretchScreen({ ctx }) {
  const { store, nav, html, ui, Icon, today } = ctx;
  const { Card, Button } = ui;
  const [expandedDay, setExpandedDay] = useState(null);
  const [showEvidence, setShowEvidence] = useState(false);
  const [showSafety, setShowSafety] = useState(false);

  const p = store.prediction(today);
  const tier = lib.tierFor(store.fullStretchPlan);
  const daysUntil = p.daysUntilNextPeriod;
  const todaySession = (daysUntil != null && daysUntil >= 1 && daysUntil <= tier.totalDays)
    ? lib.session(daysUntil, tier) : null;
  const activeSession = todaySession ?? lib.anytimeSession;

  const movesDone = store.stretchMovesDone(today);
  const dayDone = store.stretchDone(today);

  // Date that a given plan-day falls on (for schedule + window done-state).
  const dateForPlanDay = (pd) =>
    p.nextPeriodStart ? addDays(addDays(p.nextPeriodStart, -tier.totalDays), pd - 1) : null;
  const isDone = (pd) => {
    const d = dateForPlanDay(pd);
    return d && d <= today ? store.stretchDone(d) : false;
  };

  // Streak: consecutive days done, ending today (or yesterday if today's not done yet).
  const streak = (() => {
    let n = 0, cursor = store.stretchDone(today) ? today : addDays(today, -1);
    while (store.stretchDone(cursor)) { n++; cursor = addDays(cursor, -1); }
    return n;
  })();
  const totalLogged = store.logsSnapshot.filter((l) => l.stretchDone).length;

  const coachLine = coachMessage({ store, today, p, todaySession });

  const startSession = () => nav.open("session", {
    day: activeSession,
    finishTitle: todaySession ? `Day ${lib.planDay(todaySession, tier)} done` : "Session done",
  });

  const toggleMove = (i, s) => store.toggleStretchMove(i, today, s.moves.length);

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
        iconLeft=${html`<${Icon} name="activity" size=${18} />`} onClick=${startSession}>Start guided session</${Button}>`}

      <button onClick=${() => store.setStretchDone(!dayDone, today)}
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

  // ---- plan switcher ----
  const planSwitch = () => html`<${Card} variant="outline">
    <div style=${{ fontSize: "var(--text-md)", fontWeight: 600, color: "var(--deep)" }}>${tier.key === "starter" ? "Loving it?" : "Want a lighter touch?"}</div>
    <div style=${{ fontSize: "var(--text-sm)", color: "var(--muted)", lineHeight: 1.6, margin: "6px 0 10px" }}>
      ${tier.key === "starter"
        ? "You're on the 3-day starter. When it's working for you, the full 14-day plan goes deeper — same idea, two weeks of it."
        : "You're on the full 14-day plan. The 3-day starter keeps just the essentials."}
    </div>
    <${Button} variant="soft" size="sm" onClick=${() => { store.fullStretchPlan = !store.fullStretchPlan; setExpandedDay(null); }}>
      ${tier.key === "starter" ? "Switch to the full 14-day plan" : "Back to the 3-day starter"}
    </${Button}>
    <div style=${{ fontSize: "var(--text-2xs)", color: "var(--muted)", marginTop: 8 }}>Switching never erases anything — every stretch you've logged stays.</div>
  </${Card}>`;

  // ---- schedule (expandable) ----
  const scheduleRow = (d) => {
    const pd = lib.planDay(d, tier);
    const isTodayRow = todaySession && todaySession.daysBeforePeriod === d.daysBeforePeriod;
    const expanded = expandedDay === pd;
    const rowDate = dateForPlanDay(pd);
    return html`<div key=${d.id}>
      <button onClick=${() => setExpandedDay(expanded ? null : pd)}
        aria-expanded=${expanded} aria-label=${`Day ${pd}, ${d.focus}, ${d.minutes} minutes`}
        style=${{ display: "flex", alignItems: "center", gap: 10, width: "100%", background: "none", border: "none", padding: "9px 0", cursor: "pointer", textAlign: "left" }}>
        <span style=${{ color: isDone(pd) ? "var(--good)" : "var(--line)", flex: "0 0 auto" }}><${Icon} name=${isDone(pd) ? "check" : "circle"} size=${18} /></span>
        <div style=${{ flex: 1, minWidth: 0 }}>
          <div style=${{ display: "flex", alignItems: "center", gap: 6 }}>
            <span style=${{ fontSize: "var(--text-sm)", fontWeight: 700, color: isTodayRow ? "var(--primary-strong)" : "var(--deep)" }}>Day ${pd}</span>
            ${isTodayRow && html`<span style=${{ fontSize: "var(--text-2xs)", fontWeight: 700, color: "#fff", background: "var(--primary-strong)", borderRadius: 999, padding: "2px 7px" }}>today</span>`}
            ${rowDate && html`<span style=${{ fontSize: "var(--text-2xs)", color: "var(--muted)" }}>${ctx.fmt.monthShort(rowDate.getMonth())} ${rowDate.getDate()}</span>`}
          </div>
          <div style=${{ fontSize: "var(--text-sm)", color: "var(--text)" }}>${d.focus}</div>
        </div>
        <span style=${{ fontSize: "var(--text-xs)", color: "var(--muted)", flex: "0 0 auto" }}>${d.minutes}m</span>
        <span style=${{ color: "var(--muted)", flex: "0 0 auto", transform: expanded ? "rotate(180deg)" : "none", transition: "transform var(--dur-fast)" }}><${Icon} name="chevron-down" size=${16} /></span>
      </button>
      ${expanded && html`<div style=${{ paddingLeft: 34, paddingBottom: 12, display: "flex", flexDirection: "column", gap: 8 }}>
        ${d.moves.map((m) => html`<div key=${m.id} style=${{ display: "flex", alignItems: "flex-start", gap: 10 }}>
          <${PoseFigure} ctx=${ctx} move=${m} size=${24} />
          <div style=${{ flex: 1, minWidth: 0 }}>
            <div style=${{ display: "flex", justifyContent: "space-between", gap: 8, alignItems: "baseline" }}>
              <span style=${{ fontSize: "var(--text-base)", fontWeight: 600, color: "var(--text)" }}>${m.name}</span>
              <span style=${{ fontSize: "var(--text-xs)", fontWeight: 500, color: "var(--muted)", flex: "0 0 auto" }}>${m.hold}</span>
            </div>
            <div style=${{ fontSize: "var(--text-sm)", color: "var(--muted)", lineHeight: 1.5, marginTop: 2 }}>${m.cue}</div>
          </div>
        </div>`)}
      </div>`}
    </div>`;
  };

  const scheduleCard = () => {
    const days = lib.daysFor(tier);
    return html`<${Card}>
      <div style=${{ fontSize: "var(--text-md)", fontWeight: 600, color: "var(--deep)", marginBottom: 8 }}>${tier.key === "starter" ? "The 3 days" : "The 14 days"}</div>
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
    <${CoachFlower} ctx=${ctx} message=${coachLine} />

    <div style=${{ display: "flex", gap: "var(--gap-card)" }}>
      <${ui.StatTile} tone="soft" value=${streak} unit=${streak === 1 ? "day" : "days"} label="Current streak"
        icon=${html`<${Icon} name="activity" size=${18} />`} style=${{ flex: 1 }} />
      <${ui.StatTile} tone="soft" value=${totalLogged} label="Days stretched"
        icon=${html`<${Icon} name="check" size=${18} />`} style=${{ flex: 1 }} />
    </div>

    ${todaySession
      ? html`${todayCard(todaySession, `TODAY · DAY ${lib.planDay(todaySession, tier)} OF ${tier.totalDays}`)}${progressStrip()}`
      : html`${outOfWindow()}${todayCard(lib.anytimeSession, "ANYTIME SESSION · NO SCHEDULE NEEDED")}`}

    ${planSwitch()}
    ${scheduleCard()}
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
