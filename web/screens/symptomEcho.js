// SymptomEcho — port of App/Components/SymptomEchoSheet.swift. The history
// tour behind the little clock button next to a symptom she's felt before.
// The headline answers the one essential question ("when was the last
// time?") in a single calm line; everything deeper waits behind tappable
// questions that expand in place, so she reads exactly as much as she wants
// and never meets a wall of text.
//
// Opened as the "symptomEcho" overlay:
//   nav.open("symptomEcho", { symptom, lastDate, loggingDate, onShowCalendar })
//   symptom        — SYMPTOMS key, e.g. "cramps"                    (required)
//   lastDate       — Date she last felt it; defaults to store.lastFelt(...)
//   loggingDate    — the day she's logging (may be back-filled); defaults today
//   onShowCalendar — (symptom, date) => void; defaults to the Calendar tab
// Swift's SymptomEcho struct carries the same three values; the callback is
// LogView's `onShowCalendar`.

import { daysBetween, isSameDay, startOfDay } from "../core/dates.js";

const { useState } = window.React;

export default function SymptomEchoScreen({ ctx }) {
  const { store, html, ui, Icon, fmt, today, nav, screenProps } = ctx;
  const { Button, IconButton } = ui;

  const symptom = screenProps?.symptom;
  const loggingDate = screenProps?.loggingDate ?? today;
  const lastDate = screenProps?.lastDate
    ?? (symptom ? store.lastFelt(symptom, loggingDate) : null);
  // Swift only presents the sheet when there IS a last time (LogView.swift:96).
  if (!symptom || !lastDate) return null;

  // Which tour rows are expanded (SymptomEchoSheet.open — a Set of row ids).
  const [open, setOpen] = useState(() => new Set());
  const toggleRow = (id) => setOpen((prev) => {
    const next = new Set(prev);
    next.has(id) ? next.delete(id) : next.add(id);
    return next;
  });

  const daysAgo = daysBetween(lastDate, loggingDate);
  const loggingToday = isSameDay(loggingDate, today);
  const when = `${fmt.monthName(lastDate)} ${lastDate.getDate()}`;
  const lastFeltLine = daysAgo === 1
    ? (loggingToday ? `Last felt yesterday, ${when}` : `Last felt ${when}, the day before`)
    : (loggingToday ? `Last felt ${when}, ${daysAgo} days ago` : `Last felt ${when}, ${daysAgo} days earlier`);

  const showCalendar = () => {
    nav.close();
    // The caller wires the calendar's symptom focus; without one, the tab alone
    // is still the right destination.
    if (screenProps?.onShowCalendar) screenProps.onShowCalendar(symptom, lastDate);
    else nav.setTab("calendar");
  };

  // Then vs the day she's logging: the same phase twice is a pattern worth
  // seeing. Both sides are judged AT their own dates, so back-filling a past day
  // compares the right two days (never today by accident).
  const then = store.phaseSnapshot(lastDate);
  const now = store.phaseSnapshot(loggingDate);
  const phaseRow = (snap, prefix) => html`
    <div key=${prefix} style=${{ display: "flex", alignItems: "center", gap: 8 }}>
      <span style=${{ width: 9, height: 9, borderRadius: "50%", flex: "0 0 auto",
        background: `var(--phase-${snap.phase})` }} />
      <span style=${{ fontSize: "var(--text-sm)", fontWeight: 600, color: "var(--text)" }}>
        ${prefix}: ${fmt.phaseLabel(snap.phase)} phase, cycle day ${snap.day}
      </span>
    </div>`;

  const compareRows = [];
  if (then.phase && then.day != null) compareRows.push(phaseRow(then, "Then"));
  if (now.phase && now.day != null) {
    compareRows.push(phaseRow(now, loggingToday ? "Now" : "This day"));
    if (then.phase) {
      compareRows.push(html`
        <span key="verdict" style=${{ fontSize: "var(--text-xs)", color: "var(--muted)" }}>
          ${then.phase === now.phase
            ? "Same part of your cycle both times. Bodies love a rhythm."
            : "A different part of your cycle this time."}
        </span>`);
    }
  }
  const phaseCompare = html`
    <div style=${{ display: "flex", flexDirection: "column", gap: 6 }}>${compareRows}</div>`;

  const log = store.logFor(lastDate);

  // Every earlier day with this symptom, told in one gentle sentence
  // (SymptomEchoSheet.timesContent/timesLine).
  const cutoff = startOfDay(loggingDate);
  const earlier = store.daysFelt(symptom).filter((d) => d < cutoff);
  const timesLine = (() => {
    if (!earlier.length) return "This is the first time you've logged it.";
    const first = earlier[0];
    const firstWhen = `${fmt.monthName(first)} ${first.getDate()}`;
    if (earlier.length === 1) return `Once before now, on ${firstWhen}.`;
    return `${earlier.length} times before now. The first was ${firstWhen}.`;
  })();

  // A question that expands in place (SymptomEchoSheet.tourRow). Icons: Swift's
  // "arrow.triangle.2.circlepath" and "list.bullet.rectangle.portrait" have no
  // offline lucide counterpart (see vendor/icon.js's ICONS) — "moon" (cycle
  // phases) and "edit-3" (a written rundown) stand in; "calendar" is exact.
  const tourRow = (id, iconName, title, content) => {
    const isOpen = open.has(id);
    return html`
      <div key=${id} style=${{ display: "flex", flexDirection: "column", gap: 8 }}>
        <button type="button" onClick=${() => toggleRow(id)} aria-expanded=${isOpen}
          style=${{
            display: "flex", alignItems: "center", gap: 10, minHeight: 44,
            width: "100%", padding: 0, background: "none", border: "none",
            cursor: "pointer", textAlign: "left", font: "inherit",
          }}>
          <span style=${{ width: 30, height: 30, borderRadius: "50%", flex: "none",
            display: "grid", placeItems: "center", background: "var(--surface-soft)" }}>
            <${Icon} name=${iconName} size=${13} color="var(--primary-strong)" />
          </span>
          <span style=${{ fontSize: "var(--text-sm)", fontWeight: 600, color: "var(--text)", flex: 1 }}>${title}</span>
          <span style=${{
            display: "inline-flex", color: "var(--muted)",
            transform: isOpen ? "rotate(180deg)" : "none",
            transition: "transform var(--dur-fast) var(--ease-signature)",
          }}>
            <${Icon} name="chevron-down" size=${13} />
          </span>
        </button>
        ${isOpen && html`<div style=${{ paddingLeft: 40 }}>${content}</div>`}
        <div style=${{ height: 1, background: "var(--line)" }} />
      </div>`;
  };

  return html`
    <div style=${{ padding: "4px 20px 20px", display: "flex", flexDirection: "column", gap: 16 }}>
      <div style=${{ display: "flex", alignItems: "flex-start", gap: 10 }}>
        <${Icon} name="clock" size=${20} color="var(--primary-strong)" />
        <div style=${{ display: "flex", flexDirection: "column", gap: 2, flex: 1, minWidth: 0 }}>
          <h2 style=${{ margin: 0, fontFamily: "var(--font-display)", fontWeight: 700,
            fontSize: "var(--text-lg)", color: "var(--deep)" }}>
            ${fmt.symptomLabel(symptom)}
          </h2>
          <span style=${{ fontSize: "var(--text-sm)", color: "var(--muted)" }}>${lastFeltLine}</span>
        </div>
        <${IconButton} label="Close" variant="ghost" onClick=${() => nav.close()}>
          <${Icon} name="x" size=${18} />
        </${IconButton}>
      </div>

      <span style=${{ fontSize: "var(--text-xs)", color: "var(--muted)" }}>Tap any question below to open it up.</span>

      <div style=${{ display: "flex", flexDirection: "column", gap: 12 }}>
        ${tourRow("cycle", "moon", "Where in your cycle, then and now", phaseCompare)}
        ${log && tourRow("day", "edit-3", "What that whole day looked like",
          html`<${DayLogSummary} ctx=${ctx} log=${log} />`)}
        ${tourRow("times", "calendar", "How often it visits",
          html`<span style=${{ fontSize: "var(--text-sm)", color: "var(--text)", lineHeight: "var(--leading-normal)" }}>${timesLine}</span>`)}
      </div>

      <${Button} variant="primary" block=${true} onClick=${showCalendar}
        iconLeft=${html`<${Icon} name="calendar" size=${16} />`}>
        See those days on the calendar
      </${Button}>
      <${Button} variant="ghost" size="sm" onClick=${() => nav.close()}>Keep logging</${Button}>
    </div>`;
}

// DayLogSummary — one day's whole log as compact readable rows. Shared by the
// symptom echo sheet and the calendar's history banner (as in Swift), so it is
// exported: `import { DayLogSummary } from "./symptomEcho.js"`.
export function DayLogSummary({ ctx, log }) {
  const { html, Icon, fmt } = ctx;

  const row = (icon, tint, text) => html`
    <div key=${icon} style=${{ display: "flex", alignItems: "flex-start", gap: 10 }}>
      <span style=${{ width: 20, flex: "0 0 auto", paddingTop: 1, display: "flex", justifyContent: "center" }}>
        <${Icon} name=${icon} size=${13} color=${`var(${tint})`} />
      </span>
      <span style=${{ fontSize: "var(--text-sm)", color: "var(--text)", lineHeight: "var(--leading-normal)" }}>${text}</span>
    </div>`;

  // Swift sorts the LABELS, not the raw keys (DayLogSummary).
  const labels = (keys, toLabel) => keys.map(toLabel).sort().join(", ");
  const rows = [
    log.flow && row("droplet", "--phase-menstrual", `${fmt.flowLabel(log.flow)} flow`),
    log.discharge && row("cloud-rain", "--phase-fertile", `${fmt.dischargeLabel(log.discharge)} discharge`),
    log.temperatureC != null &&
      row("thermometer", "--phase-ovulation", `${fmt.cToF(log.temperatureC).toFixed(2)}° in the morning`),
    log.moods?.length && row("smile", "--phase-luteal", labels(log.moods, fmt.moodLabel)),
    log.symptoms?.length && row("heart", "--primary-strong", labels(log.symptoms, fmt.symptomLabel)),
    log.note && row("edit-3", "--deep", `“${log.note}”`),
    log.stretchDone === true && row("leaf", "--phase-luteal", "Stretched that day"),
  ].filter(Boolean);

  return html`
    <div style=${{ display: "flex", flexDirection: "column", gap: 8, padding: 16,
      background: "var(--surface)", border: "1px solid var(--line)",
      borderRadius: "var(--radius-md)" }}>
      ${rows}
    </div>`;
}
