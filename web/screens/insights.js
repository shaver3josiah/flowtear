// Insights — full-parity port of App/Views/InsightsView.swift: a StatTile summary
// grid, the "right now" phase research card, IntensityBar breakdown charts
// (rhythm + symptom frequency), the cycle-tuning controls, and the data doors
// (cycle report, CSV export, full backup & restore), all in warm second person.
// Adds the two web-only charts the brief asks for — flow breakdown and a
// lightweight inline-SVG basal temperature curve. Everything derives from the
// shared store; the only local effect marks insights seen on mount (mirrors
// Swift .onAppear).
import { periodStarts } from "../core/engine.js";
import { FLOW } from "../core/models.js";
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
              color=${`var(--flow-${r.key})`}
              meta=${`${r.count} ${r.count === 1 ? "day" : "days"}`} />`)}
        </div>
      </${Card}>`
    : null;

  // ---- basal temperature (inline SVG biphasic curve, shown in °F) ----
  const tempCard = temperatureCard(store, html, ui, fmt, cardTitle);

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
            ? `Cycle report — ${flags.length} thing${flags.length === 1 ? "" : "s"} worth noting`
            : "Cycle report — all quiet")}
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
          Everything from the calendar — flow, discharge, temps, moods, symptoms, stretches, notes — as a CSV file.
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
    catch { setBackupNote("Couldn't read that file — try picking it again."); return; }
    // The destructive confirm the Swift confirmationDialog gives her — this
    // replaces everything on this phone, so she says so out loud first.
    if (!window.confirm("Replace everything on this phone with this backup?\n\nYour current history, settings and garden will be replaced by the backup's.")) return;
    const ok = restoreBackup(text, store, rewards); // all-or-nothing
    setBackupNote(ok
      ? "Restored — everything's home again."
      : "That didn't look like a complete backup from this app — nothing was changed.");
  };
  const backupCard = html`
    <${Card}>
      <div style=${{ display: "flex", flexDirection: "column", gap: 8, alignItems: "flex-start" }}>
        ${cardLabel("settings", "Backup & restore")}
        <div style=${{ fontSize: "var(--text-xs)", color: "var(--muted)" }}>
          One file with everything — history, settings and your whole garden. Save it somewhere safe, or bring it to a new phone.
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
      ${tuningCard}
      ${store.hasAnyLogs ? html`${reportLeads ? null : reportCard}${exportCard}` : null}
      ${backupCard}
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
          Log a few cycles and you'll see your average rhythm, the symptoms you feel most, and when your next period is due.
        </div>
      </div>
    </${Card}>`;
}
