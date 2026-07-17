// SymptomEcho — port of App/Components/SymptomEchoSheet.swift. The little
// history card that appears when she logs a symptom she's felt before. It
// answers three questions in one glance: when was the last time, what did that
// whole day look like, and where in her cycle was she then compared to now. One
// tap more shows those days on the calendar, annotated.
//
// Opened as the "symptomEcho" overlay:
//   nav.open("symptomEcho", { symptom, lastDate, loggingDate, onShowCalendar })
//   symptom        — SYMPTOMS key, e.g. "cramps"                    (required)
//   lastDate       — Date she last felt it; defaults to store.lastFelt(...)
//   loggingDate    — the day she's logging (may be back-filled); defaults today
//   onShowCalendar — (symptom, date) => void; defaults to the Calendar tab
// Swift's SymptomEcho struct carries the same three values; the callback is
// LogView's `onShowCalendar`.

import { daysBetween, isSameDay } from "../core/dates.js";

export default function SymptomEchoScreen({ ctx }) {
  const { store, html, ui, Icon, fmt, today, nav, screenProps } = ctx;
  const { Card, Button, IconButton } = ui;

  const symptom = screenProps?.symptom;
  const loggingDate = screenProps?.loggingDate ?? today;
  const lastDate = screenProps?.lastDate
    ?? (symptom ? store.lastFelt(symptom, loggingDate) : null);
  // Swift only presents the sheet when there IS a last time (LogView.swift:96).
  if (!symptom || !lastDate) return null;

  const daysAgo = daysBetween(lastDate, loggingDate);
  const loggingToday = isSameDay(loggingDate, today);
  const when = `${fmt.monthName(lastDate)} ${lastDate.getDate()}`;
  const lastFeltLine = daysAgo === 1
    ? (loggingToday ? `Yesterday, ${when}` : `${when}, the day before`)
    : (loggingToday ? `${when}, ${daysAgo} days ago` : `${when}, ${daysAgo} days earlier`);

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
  const phaseCompareCard = html`
    <${Card} variant="soft">
      <div style=${{ display: "flex", flexDirection: "column", gap: 6 }}>${compareRows}</div>
    </${Card}>`;

  const log = store.logFor(lastDate);

  return html`
    <div style=${{ padding: "4px 20px 8px", display: "flex", flexDirection: "column", gap: 16 }}>
      <div style=${{ display: "flex", alignItems: "flex-start", gap: 10 }}>
        <${Icon} name="clock" size=${20} color="var(--primary-strong)" />
        <div style=${{ display: "flex", flexDirection: "column", gap: 2, flex: 1, minWidth: 0 }}>
          <h2 style=${{ margin: 0, fontFamily: "var(--font-display)", fontWeight: 700,
            fontSize: "var(--text-lg)", color: "var(--deep)" }}>
            ${fmt.symptomLabel(symptom)}, last time
          </h2>
          <span style=${{ fontSize: "var(--text-sm)", color: "var(--muted)" }}>${lastFeltLine}</span>
        </div>
        <${IconButton} label="Close" variant="ghost" onClick=${() => nav.close()}>
          <${Icon} name="x" size=${18} />
        </${IconButton}>
      </div>

      ${phaseCompareCard}

      ${log && html`
        <div style=${{ display: "flex", flexDirection: "column", gap: 8 }}>
          <h3 style=${{ margin: 0, fontSize: "var(--text-2xs)", fontWeight: 700,
            letterSpacing: "0.8px", color: "var(--muted)" }}>THAT WHOLE DAY</h3>
          <${DayLogSummary} ctx=${ctx} log=${log} />
        </div>`}

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
