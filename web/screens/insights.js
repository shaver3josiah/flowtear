// Insights — full-parity port of App/Views/InsightsView.swift: a StatTile summary
// grid, IntensityBar breakdown charts (rhythm + symptom frequency), the sample
// banner, the empty state, and the shareable cycle report + CSV export, all in
// warm second person. Adds the two web-only charts the brief asks for — flow
// breakdown and a lightweight inline-SVG basal temperature curve. Everything
// derives from the shared store; the only local effect marks insights seen on
// mount (mirrors Swift .onAppear).
import { periodStarts } from "../core/engine.js";
import { FLOW } from "../core/models.js";
import { flags as reportFlags, text as reportText, csv as reportCsv, CSV_FILENAME } from "../core/report.js";
import { shareText, shareFile } from "../core/share.js";

const React = window.React;
const { useState, useEffect } = React;

export default function InsightsScreen({ ctx }) {
  const { store, html, ui, Icon, fmt, today } = ctx;
  const { Card, StatTile, IntensityBar, Button } = ui;
  const [shareNote, setShareNote] = useState(null); // fallback confirmations, no toast plumbing
  const [saved, setSaved] = useState(false);

  useEffect(() => { store.markInsightsSeen(); }, []); // ponytail: mount-once, matches Swift .onAppear

  const p = store.prediction(today);
  const logs = store.logsSnapshot;
  const cyclesTracked = periodStarts(store.periodDays).length;

  const d = p.daysUntilNextPeriod;
  const subtitle = !p.hasHistory
    ? "Let's find your rhythm."
    : (d != null && d >= 0)
      ? `Your next period is about ${d} ${d === 1 ? "day" : "days"} away.`
      : "The patterns behind your cycle, gathered gently.";

  const cardTitle = (t) =>
    html`<div style=${{ fontSize: "var(--text-md)", fontWeight: 600, color: "var(--deep)" }}>${t}</div>`;

  // ---- header ----
  const header = html`
    <div>
      <h1 style=${{ fontSize: "var(--text-2xl)", fontWeight: 700, color: "var(--deep)" }}>Insights</h1>
      <p style=${{ fontSize: "var(--text-sm)", color: "var(--muted)", margin: "4px 0 0" }}>${subtitle}</p>
    </div>`;

  // ---- sample banner (mirrors App/Components/SampleBanner.swift) ----
  const clearSample = () => {
    if (window.confirm("Clear the sample data? The preview goes away and the app starts fresh with your own logs.")) {
      store.clearSampleData();
    }
  };
  const sampleBanner = store.sampleActive
    ? html`
      <${Card} variant="soft" style=${{ display: "flex", alignItems: "center", gap: 10 }}>
        <${Icon} name="sparkles" size=${16} color="var(--flower-center)" />
        <div style=${{ flex: 1, minWidth: 0 }}>
          <div style=${{ fontSize: "var(--text-sm)", fontWeight: 600, color: "var(--deep)" }}>You're exploring sample data</div>
          <div style=${{ fontSize: "var(--text-xs)", color: "var(--muted)" }}>Clear it to begin your own</div>
        </div>
        <${Button} variant="primary" size="sm" onClick=${clearSample}>Clear sample data</${Button}>
      </${Card}>`
    : null;

  // ---- summary tiles ----
  const summaryGrid = html`
    <div style=${{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
      <${StatTile} value=${p.averageCycleLength} unit="days" label="Avg cycle" />
      <${StatTile} value=${p.averagePeriodLength} unit="days" label="Avg period" />
      <${StatTile} value=${cyclesTracked} label="Cycles tracked" />
      <${StatTile} value=${logs.length} label="Days logged" />
    </div>`;

  // ---- rhythm chart ----
  const rhythmCard = html`
    <${Card}>
      <div style=${{ display: "flex", flexDirection: "column", gap: 12 }}>
        ${cardTitle("Your rhythm")}
        <${IntensityBar} label="Cycle length" value=${Math.min(1, p.averageCycleLength / 40)}
          color="var(--primary)" meta=${`${p.averageCycleLength} days`} />
        <${IntensityBar} label="Period length" value=${Math.min(1, p.averagePeriodLength / 10)}
          color="var(--phase-menstrual)" meta=${`${p.averagePeriodLength} days`} />
      </div>
    </${Card}>`;

  // ---- symptom frequency (value = fraction of logged days, meta = count) ----
  const symTally = {};
  for (const l of logs) for (const s of (l.symptoms || [])) symTally[s] = (symTally[s] || 0) + 1;
  const symRows = Object.entries(symTally)
    .map(([name, count]) => ({ name, count }))
    .sort((a, b) => b.count - a.count);
  const symptomsCard = symRows.length
    ? html`
      <${Card}>
        <div style=${{ display: "flex", flexDirection: "column", gap: 12 }}>
          ${cardTitle("What you feel most")}
          ${symRows.map((r) => html`
            <${IntensityBar} key=${r.name} label=${fmt.symptomLabel(r.name)}
              value=${logs.length ? r.count / logs.length : 0}
              color="var(--primary)" meta=${`${r.count}×`} />`)}
        </div>
      </${Card}>`
    : null;

  // ---- flow breakdown (distribution across logged flow days, --flow-* ramp) ----
  const flowTally = {};
  for (const l of logs) if (l.flow) flowTally[l.flow] = (flowTally[l.flow] || 0) + 1;
  const totalFlow = Object.values(flowTally).reduce((a, b) => a + b, 0);
  const flowRows = FLOW.filter((k) => flowTally[k]).map((k) => ({ key: k, count: flowTally[k] }));
  const flowCard = flowRows.length
    ? html`
      <${Card}>
        <div style=${{ display: "flex", flexDirection: "column", gap: 12 }}>
          ${cardTitle("How your flow breaks down")}
          ${flowRows.map((r) => html`
            <${IntensityBar} key=${r.key} label=${fmt.flowLabel(r.key)}
              value=${totalFlow ? r.count / totalFlow : 0}
              color=${`var(--flow-${r.key})`}
              meta=${`${r.count} ${r.count === 1 ? "day" : "days"}`} />`)}
        </div>
      </${Card}>`
    : null;

  // ---- basal temperature (inline SVG biphasic curve, shown in °F) ----
  const tempCard = temperatureCard(store, html, ui, fmt, cardTitle);

  // ---- cycle report — pre-written text to hand to a partner or clinician ----
  const flags = reportFlags(store, today);
  const shareReport = async () => {
    // Native share sheet inside the APK; Web Share / clipboard in a browser.
    setShareNote(await shareText({ title: "My cycle report", text: reportText(store, today) }));
  };
  const reportCard = html`
    <${Card} variant=${flags.length ? "accent" : "plain"}>
      <div style=${{ display: "flex", flexDirection: "column", gap: 10, alignItems: "flex-start" }}>
        <div style=${{ display: "flex", alignItems: "center", gap: 8 }}>
          <${Icon} name=${flags.length ? "bell" : "check"} size=${16} color="var(--deep)" />
          <div style=${{ fontSize: "var(--text-md)", fontWeight: 600, color: "var(--deep)" }}>
            ${flags.length
              ? `Cycle report — ${flags.length} thing${flags.length === 1 ? "" : "s"} worth noting`
              : "Cycle report — all quiet"}
          </div>
        </div>
        ${flags.slice(0, 2).map((f) => html`
          <div key=${f} style=${{ display: "flex", alignItems: "flex-start", gap: 8 }}>
            <span style=${{ width: 5, height: 5, marginTop: 7, borderRadius: "50%",
              background: "var(--primary-strong)", flex: "0 0 auto" }} />
            <div style=${{ fontSize: "var(--text-sm)", color: "var(--text)", lineHeight: 1.5 }}>${f}</div>
          </div>`)}
        <${Button} variant="primary" size="sm" onClick=${shareReport}>Share the report</${Button}>
        ${shareNote && html`<div style=${{ fontSize: "var(--text-xs)", color: "var(--muted)" }}>${shareNote}</div>`}
      </div>
    </${Card}>`;

  // ---- every logged day, as a spreadsheet ----
  const saveCsv = async () => {
    setSaved(await shareFile({
      filename: CSV_FILENAME, data: reportCsv(store),
      mimeType: "text/csv", dialogTitle: "Your cycle data",
    }));
  };
  const exportCard = html`
    <${Card}>
      <div style=${{ display: "flex", flexDirection: "column", gap: 10, alignItems: "flex-start" }}>
        <div style=${{ display: "flex", alignItems: "center", gap: 8 }}>
          <${Icon} name="calendar" size=${16} color="var(--deep)" />
          <div style=${{ fontSize: "var(--text-md)", fontWeight: 600, color: "var(--deep)" }}>Your data, your spreadsheet</div>
        </div>
        <div style=${{ fontSize: "var(--text-xs)", color: "var(--muted)" }}>
          Everything from the calendar — flow, discharge, temps, moods, symptoms, stretches, notes — as a CSV file.
        </div>
        <${Button} variant="soft" size="sm" onClick=${saveCsv}>Share the spreadsheet</${Button}>
        ${saved && html`
          <div style=${{ fontSize: "var(--text-xs)", color: "var(--muted)" }}>
            ${saved === "shared" ? `Shared as ${CSV_FILENAME}.` : `Saved to your downloads as ${CSV_FILENAME}.`}
          </div>`}
      </div>
    </${Card}>`;

  return html`
    <div style=${{ display: "flex", flexDirection: "column", gap: "var(--gap-section)" }}>
      ${header}
      ${sampleBanner}
      ${p.hasHistory
        ? html`${summaryGrid}${rhythmCard}${symptomsCard}${flowCard}${tempCard}`
        : emptyCard(html, ui, Icon)}
      ${store.hasAnyLogs ? html`${reportCard}${exportCard}` : null}
    </div>`;
}

// Lightweight offline line/area chart — no chart lib. Maps the recent basal
// temperatures (°C in the store) to °F and plots them in a fixed viewBox.
function temperatureCard(store, html, ui, fmt, cardTitle) {
  const { Card } = ui;
  const temps = store.recentTemperatures(14);
  if (temps.length < 2) return null; // need two points to draw a line

  const fs = temps.map((t) => fmt.cToF(t.celsius));
  const lo0 = Math.min(...fs), hi0 = Math.max(...fs);
  const padV = (hi0 - lo0) * 0.25 || 0.5; // headroom so a flat run isn't glued to the edges
  const lo = lo0 - padV, hi = hi0 + padV, span = hi - lo || 1;

  const W = 300, H = 120, P = { t: 14, r: 12, b: 14, l: 12 };
  const iw = W - P.l - P.r, ih = H - P.t - P.b, bottom = P.t + ih, n = temps.length;
  const X = (i) => +(P.l + iw * i / (n - 1)).toFixed(1);
  const Y = (v) => +(P.t + ih * (1 - (v - lo) / span)).toFixed(1);

  const pts = fs.map((v, i) => `${X(i)},${Y(v)}`).join(" ");
  const areaD = `M ${X(0)},${bottom} ` + fs.map((v, i) => `L ${X(i)},${Y(v)}`).join(" ") + ` L ${X(n - 1)},${bottom} Z`;

  return html`
    <${Card}>
      <div style=${{ display: "flex", flexDirection: "column", gap: 10 }}>
        ${cardTitle("Your basal temperature")}
        <svg viewBox=${`0 0 ${W} ${H}`} width="100%" style=${{ display: "block", height: "auto" }}
          role="img" aria-label="Basal body temperature trend, in Fahrenheit">
          <path d=${areaD} fill="var(--phase-fertile-soft)" />
          <polyline points=${pts} fill="none" stroke="var(--primary-strong)"
            strokeWidth=${2} strokeLinecap="round" strokeLinejoin="round" />
          ${fs.map((v, i) => html`<circle key=${i} cx=${X(i)} cy=${Y(v)} r=${2.2} fill="var(--primary-strong)" />`)}
        </svg>
        <div style=${{ fontSize: "var(--text-xs)", color: "var(--muted)" }}>
          ${fmt.shortDate(temps[0].date)} – ${fmt.shortDate(temps[n - 1].date)} · ${lo0.toFixed(1)}°–${hi0.toFixed(1)}°F
        </div>
      </div>
    </${Card}>`;
}

function emptyCard(html, ui, Icon) {
  const { Card } = ui;
  return html`
    <${Card} variant="soft" style=${{ textAlign: "center" }}>
      <div style=${{ display: "flex", flexDirection: "column", alignItems: "center", gap: 8, padding: "16px 0" }}>
        <${Icon} name="bar-chart-2" size=${26} color="var(--primary)" />
        <div style=${{ fontSize: "var(--text-md)", fontWeight: 600, color: "var(--deep)" }}>Your patterns will appear here</div>
        <div style=${{ fontSize: "var(--text-sm)", color: "var(--muted)", maxWidth: 280 }}>
          Log a few cycles and Uncorked will show your average rhythm, the symptoms you feel most, and when your next period is due.
        </div>
      </div>
    </${Card}>`;
}
