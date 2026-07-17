// Insights — full-parity port of App/Views/InsightsView.swift: a StatTile summary
// grid, the "right now" phase research card, IntensityBar breakdown charts
// (rhythm + symptom frequency), the monthly flow chart, the cycle-tuning
// controls, and the data doors (cycle report, CSV export, full backup &
// restore), all in warm second person.
// Adds the two web-only charts the brief asks for — flow breakdown and a
// lightweight inline-SVG basal temperature curve. Everything derives from the
// shared store; the only local effect marks insights seen on mount (mirrors
// Swift .onAppear).
import { periodStarts } from "../core/engine.js";
import { FLOW, FLOW_WEIGHT } from "../core/models.js";
import { startOfDay, addDays, daysBetween } from "../core/dates.js";
import { flags as reportFlags, text as reportText, csv as reportCsv, CSV_FILENAME } from "../core/report.js";
import { shareText, shareFile } from "../core/share.js";
import { makeBackup, restoreBackup, backupFilename } from "../core/backup.js";
import { rewards } from "../core/rewards.js";
import { report as phaseReport } from "../core/phaseResearch.js";

const React = window.React;
const { useState, useEffect, useRef } = React;

export default function InsightsScreen({ ctx }) {
  const { store, html, ui, Icon, fmt, today } = ctx;
  const { Card, StatTile, IntensityBar, Button, IconButton, Switch } = ui;
  const [shareNote, setShareNote] = useState(null); // fallback confirmations, no toast plumbing
  const [saved, setSaved] = useState(false);
  const [backupNote, setBackupNote] = useState(null);
  const restoreInput = useRef(null);

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

  // Real headings mirror Swift's .accessibilityAddTraits(.isHeader).
  const cardTitle = (t) =>
    html`<h2 style=${{ fontSize: "var(--text-md)", fontWeight: 600, color: "var(--deep)", margin: 0 }}>${t}</h2>`;
  const cardLabel = (icon, t) => html`
    <h2 style=${{ display: "flex", alignItems: "center", gap: 8, margin: 0,
      fontSize: "var(--text-md)", fontWeight: 600, color: "var(--deep)" }}>
      <${Icon} name=${icon} size=${16} color="var(--deep)" />
      <span>${t}</span>
    </h2>`;

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

  // ---- "right now" phase research card ----
  // The research report for where she is right now — the same short report the
  // ring's phase sheet shows, sitting right under the summary tiles so what
  // this week feels like (and what the evidence says helps) is never more than
  // one scroll away. (InsightsView.phaseReportCard)
  const phaseReportCard = p.phase ? (() => {
    const r = phaseReport(p.phase, p.cycleDay ?? 1, Math.max(p.averageCycleLength, 1));
    const tint = `var(--phase-${p.phase})`;
    return html`
      <${Card}>
        <div style=${{ display: "flex", flexDirection: "column", gap: 8 }}>
          <h2 style=${{ display: "flex", alignItems: "center", gap: 8, margin: 0,
            fontSize: "var(--text-md)", fontWeight: 600, color: "var(--deep)" }}>
            <span style=${{ width: 10, height: 10, borderRadius: "50%", background: tint, flex: "0 0 auto" }} />
            <span>Right now · ${r.title}</span>
          </h2>
          <div style=${{ fontSize: "var(--text-sm)", color: "var(--text)", lineHeight: "var(--leading-normal)" }}>${r.body}</div>
          ${r.tips.map((tip) => html`
            <div key=${tip} style=${{ display: "flex", alignItems: "flex-start", gap: 8 }}>
              <span style=${{ width: 5, height: 5, marginTop: 7, borderRadius: "50%", background: tint, flex: "0 0 auto" }} />
              <div style=${{ fontSize: "var(--text-sm)", color: "var(--text)" }}>${tip}</div>
            </div>`)}
          <div style=${{ fontSize: "var(--text-xs)", color: "var(--muted)", lineHeight: "var(--leading-normal)", marginTop: 2 }}>${r.evidenceNote}</div>
        </div>
      </${Card}>`;
  })() : null;

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
              color=${flowRampColor(r.key)}
              meta=${`${r.count} ${r.count === 1 ? "day" : "days"}`} />`)}
        </div>
      </${Card}>`
    : null;

  // ---- basal temperature (inline SVG biphasic curve, shown in °F) ----
  const tempCard = temperatureCard(store, html, ui, fmt, cardTitle);

  // ---- your flow, this month (InsightsView.flowChartCard) ----
  const flowChartCard = monthlyFlowChart(store, today, html, ui, fmt, cardTitle);

  // ---- tune your cycle — her numbers beat the math whenever she says so ----
  const s = store.settings;
  const locked = !!s.lockCycleLength;
  const step = (key, delta, lo, hi) => {
    const next = Math.min(hi, Math.max(lo, s[key] + delta));
    if (next !== s[key]) store.updateSettings({ [key]: next });
  };
  const stepperRow = (label, key, lo, hi) => html`
    <div style=${{ display: "flex", alignItems: "center", gap: 8 }}>
      <div style=${{ flex: 1, fontSize: "var(--text-sm)", fontWeight: 500, color: "var(--text)" }}>
        ${label} · ${s[key]} days
      </div>
      <${IconButton} label=${`Decrease ${label.toLowerCase()}`} size="sm"
        disabled=${s[key] <= lo} onClick=${() => step(key, -1, lo, hi)}>
        <${Icon} name="minus" size=${16} />
      </${IconButton}>
      <${IconButton} label=${`Increase ${label.toLowerCase()}`} size="sm"
        disabled=${s[key] >= hi} onClick=${() => step(key, +1, lo, hi)}>
        <${Icon} name="plus" size=${16} />
      </${IconButton}>
    </div>`;
  const tuningCard = html`
    <${Card}>
      <div style=${{ display: "flex", flexDirection: "column", gap: 12 }}>
        ${cardTitle("Tune your cycle")}
        ${stepperRow("Cycle length", "defaultCycleLength", 18, 45)}
        ${stepperRow("Period length", "defaultPeriodLength", 2, 10)}
        <div style=${{ display: "flex", alignItems: "center", gap: 10 }}>
          <div style=${{ flex: 1, minWidth: 0 }}>
            <div style=${{ fontSize: "var(--text-sm)", fontWeight: 600, color: "var(--text)" }}>Use my numbers, not the averages</div>
            <div style=${{ fontSize: "var(--text-xs)", color: "var(--muted)" }}>
              ${locked
                ? "Predictions follow both numbers above exactly."
                : "Off, your logged averages take over as history grows."}
            </div>
          </div>
          <${Switch} checked=${locked}
            onChange=${(next) => store.updateSettings({ lockCycleLength: next })}
            label="Use my cycle and period lengths instead of the logged averages" />
        </div>
      </div>
    </${Card}>`;

  // ---- cycle report — pre-written text to hand to a partner or clinician ----
  const flags = reportFlags(store, today);
  const shareReport = async () => {
    // Native share sheet inside the APK; Web Share / clipboard in a browser.
    setShareNote(await shareText({ title: "My cycle report", text: reportText(store, today) }));
  };
  const reportCard = html`
    <${Card} variant=${flags.length ? "accent" : "plain"}>
      <div style=${{ display: "flex", flexDirection: "column", gap: 10, alignItems: "flex-start" }}>
        ${cardLabel(flags.length ? "bell" : "check",
          flags.length
            ? `Cycle report: ${flags.length} thing${flags.length === 1 ? "" : "s"} worth noting`
            : "Cycle report: all quiet")}
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
        ${cardLabel("calendar", "Your data, your spreadsheet")}
        <div style=${{ fontSize: "var(--text-xs)", color: "var(--muted)" }}>
          Everything from the calendar (flow, discharge, temps, moods, symptoms, stretches, notes) as a CSV file.
        </div>
        <${Button} variant="soft" size="sm" onClick=${saveCsv}>Share the spreadsheet</${Button}>
        ${saved && html`
          <div style=${{ fontSize: "var(--text-xs)", color: "var(--muted)" }}>
            ${saved === "shared" ? `Shared as ${CSV_FILENAME}.` : `Saved to your downloads as ${CSV_FILENAME}.`}
          </div>`}
      </div>
    </${Card}>`;

  // ---- backup & restore — one file with everything, hers to keep or carry to
  // a new phone. Always visible: restore matters most when this phone is empty.
  // (Swift's "externaldrive" glyph has no offline counterpart; the settings
  // gear stands in as the data-management door.)
  const saveBackup = async () => {
    // The file is built the moment she shares — always current (Backup.swift's
    // ShareItem promise).
    const name = backupFilename();
    const status = await shareFile({
      filename: name, data: makeBackup(store, rewards),
      mimeType: "application/json", dialogTitle: "Uncorked backup",
    });
    setBackupNote(status === "shared" ? `Shared as ${name}.` : `Saved to your downloads as ${name}.`);
  };
  const pickRestore = () => {
    setBackupNote(null);
    if (restoreInput.current) restoreInput.current.click();
  };
  const onRestoreFile = async (e) => {
    const file = e.target.files && e.target.files[0];
    e.target.value = ""; // picking the same file again should re-fire
    if (!file) return;
    let text;
    try { text = await file.text(); }
    catch { setBackupNote("Couldn't read that file. Try picking it again."); return; }
    // The destructive confirm the Swift confirmationDialog gives her — this
    // replaces everything on this phone, so she says so out loud first.
    if (!window.confirm("Replace everything on this phone with this backup?\n\nYour current history, settings and garden will be replaced by the backup's.")) return;
    const ok = restoreBackup(text, store, rewards); // all-or-nothing
    setBackupNote(ok
      ? "Restored. Everything's home again."
      : "That didn't look like a complete backup from this app, so nothing was changed.");
  };
  const backupCard = html`
    <${Card}>
      <div style=${{ display: "flex", flexDirection: "column", gap: 8, alignItems: "flex-start" }}>
        ${cardLabel("settings", "Backup & restore")}
        <div style=${{ fontSize: "var(--text-xs)", color: "var(--muted)" }}>
          One file with everything: history, settings and your whole garden. Save it somewhere safe, or bring it to a new phone.
        </div>
        <div style=${{ display: "flex", gap: 8 }}>
          <${Button} variant="soft" size="sm" onClick=${saveBackup}>Save a backup</${Button}>
          <${Button} variant="ghost" size="sm" onClick=${pickRestore}>Restore</${Button}>
        </div>
        <input ref=${restoreInput} type="file" accept="application/json,.json"
          style=${{ display: "none" }} aria-hidden="true" tabIndex=${-1}
          onChange=${onRestoreFile} />
        ${backupNote && html`
          <div role="status" style=${{ fontSize: "var(--text-xs)", fontWeight: 500, color: "var(--muted)" }}>${backupNote}</div>`}
      </div>
    </${Card}>`;

  // When the cycle report has something worth noting, it IS the headline — it
  // leads the screen. All quiet, it rests near the bottom with the other data
  // doors. (InsightsView.body)
  const reportLeads = store.hasAnyLogs && flags.length > 0;

  return html`
    <div style=${{ display: "flex", flexDirection: "column", gap: "var(--gap-section)" }}>
      ${header}
      ${sampleBanner}
      ${reportLeads ? reportCard : null}
      ${p.hasHistory
        ? html`${summaryGrid}${phaseReportCard}${rhythmCard}${symptomsCard}${flowCard}${tempCard}`
        : emptyCard(html, ui, Icon)}
      ${flowChartCard}
      ${tuningCard}
      ${store.hasAnyLogs ? html`${reportLeads ? null : reportCard}${exportCard}` : null}
      ${backupCard}
    </div>`;
}

// The flow ramp color for a level. superHeavy has no --flow-* token yet (that
// lives in tokens.css, another slice), so the deepest ramp color stands in.
// models.js keys are camelCase; the CSS ramp is kebab (--flow-super-heavy).
const flowRampColor = (key) => `var(--flow-${key.replace(/[A-Z]/g, (c) => "-" + c.toLowerCase())})`;

// ---------------------------------------------------------------------------
// Monthly flow chart (InsightsView.flowChartCard / flowChartData). Swift draws
// it with Swift Charts; the web has no chart lib and must stay offline, so it's
// inline SVG on the same scale: y 0…5 (spotting 1 → superHeavy 5), gridlines at
// 1/3/5, a 30-day window, and the dashed projection of the next expected period.

const Y_LABELS = { 1: "Spotting", 3: "Medium", 5: "Super" }; // InsightsView.yLabel

/// Her average intensity for each period day, from every logged period; days
/// she's never logged fall back to a gentle bell. (InsightsView.projectedPattern)
function projectedPattern(store, len) {
  const bell = [3, 4, 4, 3, 2, 1];
  while (bell.length < len) bell.push(1);
  const sums = Array(len).fill(0);
  const counts = Array(len).fill(0);
  for (const s of periodStarts(store.periodDays)) {
    for (let k = 0; k < len; k++) {
      const flow = store.logFor(addDays(s, k))?.flow;
      if (flow) { sums[k] += FLOW_WEIGHT[flow]; counts[k] += 1; }
    }
  }
  return Array.from({ length: len }, (_, k) =>
    counts[k] > 0 ? Math.round(sums[k] / counts[k]) : bell[k]);
}

/// The last 30 days of logged flow (0 on quiet days) plus a dashed projection
/// of the next expected period, shaped by her own pattern. With no flow logged
/// at all, a labeled one-month preview shows instead. (InsightsView.flowChartData)
function flowChartData(store, today) {
  const t0 = startOfDay(today);
  const hasFlow = store.logsSnapshot.some((l) => l.flow != null);

  // First-month preview: a gentle example so the card teaches itself.
  if (!hasFlow) {
    const start = addDays(t0, -29);
    const example = [0, 0, 0, 2, 4, 4, 3, 2, 1, ...Array(21).fill(0)];
    return {
      logged: example.map((weight, i) => ({ date: addDays(start, i), weight })),
      projected: [], isPreview: true,
    };
  }

  const logged = [];
  for (let off = -29; off <= 0; off++) {
    const date = addDays(t0, off);
    const flow = store.logFor(date)?.flow;
    logged.push({ date, weight: flow ? FLOW_WEIGHT[flow] : 0 });
  }

  // Projection: dashes from tomorrow through the predicted period's end, shaped
  // by her own per-day intensity averages (a soft bell until then).
  const projected = [];
  const p = store.prediction(today);
  if (p.nextPeriodStart) {
    const start = startOfDay(p.nextPeriodStart);
    const len = Math.max(p.averagePeriodLength, 1);
    const pattern = projectedPattern(store, len);
    const end = addDays(start, len - 1);
    for (let d = addDays(t0, 1); d <= end && daysBetween(t0, d) <= 35; d = addDays(d, 1)) {
      const k = daysBetween(start, d);
      projected.push({ date: d, weight: (k >= 0 && k < len) ? pattern[Math.min(k, pattern.length - 1)] : 0 });
    }
  }
  return { logged, projected, isPreview: false };
}

// Fritsch-Carlson monotone cubic through the points, as a bezier path — Swift's
// .interpolationMethod(.monotone). Monotone and not a plain smoothing spline
// because flow reads 0,0,4,0: anything that overshoots would draw negative flow.
function monotonePath(pts) {
  const n = pts.length;
  if (n === 0) return "";
  const r = (v) => +v.toFixed(1);
  if (n === 1) return `M ${r(pts[0].x)},${r(pts[0].y)}`;

  const slope = [];
  for (let i = 0; i < n - 1; i++) slope.push((pts[i + 1].y - pts[i].y) / (pts[i + 1].x - pts[i].x));
  const m = [slope[0]];
  for (let i = 1; i < n - 1; i++) m.push(slope[i - 1] * slope[i] <= 0 ? 0 : (slope[i - 1] + slope[i]) / 2);
  m.push(slope[n - 2]);
  for (let i = 0; i < n - 1; i++) {
    if (slope[i] === 0) { m[i] = 0; m[i + 1] = 0; continue; }
    const a = m[i] / slope[i], b = m[i + 1] / slope[i];
    const s = a * a + b * b;
    if (s > 9) { const t = 3 / Math.sqrt(s); m[i] = t * a * slope[i]; m[i + 1] = t * b * slope[i]; }
  }

  let out = `M ${r(pts[0].x)},${r(pts[0].y)}`;
  for (let i = 0; i < n - 1; i++) {
    const h = (pts[i + 1].x - pts[i].x) / 3;
    out += ` C ${r(pts[i].x + h)},${r(pts[i].y + m[i] * h)}` +
           ` ${r(pts[i + 1].x - h)},${r(pts[i + 1].y - m[i + 1] * h)}` +
           ` ${r(pts[i + 1].x)},${r(pts[i + 1].y)}`;
  }
  return out;
}

// InsightsView.chartA11y — the whole chart in one sentence for a screen reader.
function chartA11y(data, fmt) {
  if (data.isPreview) return "A preview flow chart. It fills in with your own flow as you log.";
  const wide = (d) => `${fmt.monthName(d)} ${d.getDate()}`;
  const peak = data.logged.reduce((a, b) => (b.weight > a.weight ? b : a), data.logged[0]);
  let out = "Flow over the last 30 days.";
  if (peak && peak.weight > 0) out += ` Heaviest on ${wide(peak.date)}.`;
  const first = data.projected.find((pt) => pt.weight > 0);
  if (first) out += ` The next period is expected around ${wide(first.date)}.`;
  return out;
}

function monthlyFlowChart(store, today, html, ui, fmt, cardTitle) {
  const { Card } = ui;
  const data = flowChartData(store, today);
  const all = [...data.logged, ...data.projected];
  if (all.length < 2) return null; // two points to draw a line, as everywhere else

  // One shared x scale across both series (Swift's single Chart domain).
  const first = all[0].date, last = all[all.length - 1].date;
  const spanDays = Math.max(daysBetween(first, last), 1);
  // Gutters: left for the y labels ("Spotting"), bottom for the dates, right
  // wide enough that the last date label stays inside the viewBox (it's centred
  // on the final gridline, which lands exactly on the plot's right edge).
  const W = 320, H = 150, P = { t: 8, r: 20, b: 18, l: 54 };
  const iw = W - P.l - P.r, ih = H - P.t - P.b, bottom = P.t + ih;
  const X = (d) => P.l + iw * (daysBetween(first, d) / spanDays);
  const Y = (w) => P.t + ih * (1 - w / 5); // chartYScale(domain: 0...5)

  const toPts = (series) => series.map((pt) => ({ x: X(pt.date), y: Y(pt.weight) }));
  const loggedPts = toPts(data.logged);
  const loggedLine = monotonePath(loggedPts);
  const loggedArea = loggedPts.length
    ? `${loggedLine} L ${loggedPts[loggedPts.length - 1].x.toFixed(1)},${bottom} L ${loggedPts[0].x.toFixed(1)},${bottom} Z`
    : "";

  // X gridlines every 7 days (AxisMarks(.stride(by: .day, count: 7))).
  const ticks = [];
  for (let k = 0; k <= spanDays; k += 7) ticks.push(addDays(first, k));

  const legendSwatch = (dashed, label) => html`
    <div key=${label} style=${{ display: "flex", alignItems: "center", gap: 5 }}>
      <svg width="18" height="3" viewBox="0 0 18 3" aria-hidden="true" style=${{ flex: "0 0 auto" }}>
        <line x1="1.5" y1="1.5" x2="16.5" y2="1.5" stroke=${dashed ? "var(--muted)" : "var(--phase-menstrual)"}
          strokeWidth=${2.5} strokeLinecap="round" strokeDasharray=${dashed ? "4 3" : undefined} />
      </svg>
      <span style=${{ fontSize: "var(--text-2xs)", fontWeight: 500, color: "var(--muted)" }}>${label}</span>
    </div>`;

  return html`
    <${Card}>
      <div style=${{ display: "flex", flexDirection: "column", gap: 8 }}>
        <div style=${{ display: "flex", alignItems: "center", gap: 8 }}>
          ${cardTitle("Your flow, this month")}
          <div style=${{ flex: 1 }} />
          ${data.isPreview && html`
            <span style=${{ fontSize: "var(--text-2xs)", fontWeight: 700, letterSpacing: "0.8px",
              color: "var(--on-primary)", background: "var(--primary-strong)",
              padding: "2px 8px", borderRadius: "var(--radius-pill)" }}>PREVIEW</span>`}
        </div>

        <svg viewBox=${`0 0 ${W} ${H}`} width="100%" style=${{ display: "block", height: "auto" }}
          role="img" aria-label=${chartA11y(data, fmt)}>
          ${[1, 3, 5].map((w) => html`
            <g key=${w}>
              <line x1=${P.l} y1=${Y(w).toFixed(1)} x2=${W - P.r} y2=${Y(w).toFixed(1)}
                stroke="var(--line)" strokeWidth=${1} />
              <text x=${P.l - 6} y=${(Y(w) + 3).toFixed(1)} textAnchor="end"
                fontSize=${9} fontWeight=${500} fill="var(--muted)">${Y_LABELS[w]}</text>
            </g>`)}
          ${ticks.map((d) => html`
            <g key=${d.getTime()}>
              <line x1=${X(d).toFixed(1)} y1=${P.t} x2=${X(d).toFixed(1)} y2=${bottom}
                stroke="var(--line)" strokeWidth=${1} />
              <text x=${X(d).toFixed(1)} y=${H - 5} textAnchor="middle"
                fontSize=${9} fontWeight=${500} fill="var(--muted)">${fmt.monthShort(d.getMonth())} ${d.getDate()}</text>
            </g>`)}
          ${loggedArea && html`<path d=${loggedArea} fill="var(--phase-menstrual)" fillOpacity=${0.14} />`}
          <path d=${loggedLine} fill="none" stroke="var(--phase-menstrual)"
            strokeWidth=${2.5} strokeLinecap="round" strokeLinejoin="round" />
          ${data.projected.length > 1 && html`
            <path d=${monotonePath(toPts(data.projected))} fill="none" stroke="var(--muted)"
              strokeWidth=${2} strokeLinecap="round" strokeLinejoin="round" strokeDasharray="5 4" />`}
        </svg>

        <div style=${{ display: "flex", flexWrap: "wrap", gap: 16 }}>
          ${legendSwatch(false, data.isPreview ? "A month like yours could look" : "What you logged")}
          ${data.projected.length > 0 && legendSwatch(true, "Next period, as expected")}
        </div>
        ${data.isPreview && html`
          <div style=${{ fontSize: "var(--text-xs)", color: "var(--muted)" }}>
            This becomes your own curve as you log your flow.
          </div>`}
      </div>
    </${Card}>`;
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
          Log a few cycles and you'll see your average rhythm, the symptoms you feel most, and when your next period is due.
        </div>
      </div>
    </${Card}>`;
}
