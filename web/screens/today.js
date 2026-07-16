// Today — the home screen. Faithful port of App/Views/TodayView.swift:
// header (bloom + date + theme pencil), the CycleRing hero with drifting petals,
// the current phase badge (tap → phase sheet), a next-period line, a quick flow
// log, a rotating teaser pane (stretch → insights → calendar), and the fertile
// window + basal-temperature card. All state reads/writes go through the store.
import { rewards } from "../core/rewards.js";

const React = window.React;
const { useState, useEffect } = React;

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

  const header = html`
    <div style=${{ display: "flex", alignItems: "center", gap: 11, marginBottom: 4 }}>
      <${FlowerMark} size=${38} />
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
      <${IconButton} label="Theme settings" variant="soft" onClick=${() => nav.open("theme")}>
        <${Icon} name="edit-3" size=${18} />
      </${IconButton}>
    </div>`;

  const sampleBanner = store.sampleActive ? html`
    <${Card} variant="soft" padding=${12}>
      <div style=${{ display: "flex", alignItems: "center", gap: 10 }}>
        <${Icon} name="sparkles" size=${18} color="var(--primary-strong)" />
        <span style=${{ fontSize: "var(--text-sm)", color: "var(--muted)" }}>Showing sample data so you can explore. Log your own day to make it yours.</span>
      </div>
    </${Card}>` : null;

  const hero = html`
    <div style=${{ position: "relative", padding: "2px 0" }}>
      <${PetalRain} count=${10} />
      <div style=${{ position: "relative", zIndex: 1, display: "flex", flexDirection: "column", alignItems: "center", gap: 10 }}>
        <button style=${bareBtn} onClick=${openPhase} aria-label="Explore this phase">
          <${CycleRing}
            cycleDay=${Math.min(Math.max(p.cycleDay || 1, 1), p.averageCycleLength)}
            cycleLength=${p.averageCycleLength}
            periodLength=${p.averagePeriodLength}
            size=${244} />
        </button>
        <button style=${bareBtn} onClick=${openPhase} aria-label=${`${fmt.phaseLabel(p.phase)} phase — open details`}>
          <${PhaseBadge} phase=${p.phase} />
        </button>
        <div style=${{ fontSize: "var(--text-sm)", fontWeight: 500, color: "var(--muted)", textAlign: "center" }}>${nextPeriodLine(p.daysUntilNextPeriod)}</div>
      </div>
    </div>`;

  const quickLog = html`
    <${Card}>
      <div style=${{ display: "flex", flexDirection: "column", gap: 12 }}>
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
      ${header}
      ${sampleBanner}
      ${p.hasHistory
        ? html`${hero}${quickLog}${rotatingPane}<${FertileWindow} ctx=${ctx} p=${p} />`
        : store.hasAnyLogs
          ? html`${startedState}${quickLog}${rotatingPane}`
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
