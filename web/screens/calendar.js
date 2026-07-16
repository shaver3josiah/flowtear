// Full-parity Calendar screen — a port of App/Views/CalendarView.swift +
// App/Components/DayCell.swift. A month grid of ctx.ui.DayCell: each day carries
// its computed phase state (period / predicted / fertile / ovulation) plus a
// logged-flow dot. Prev/next month pager, a color legend, and a read-only
// summary of the tapped day with an "Edit this day" hop into the Log screen.
//
// All state (logs + predictions) is read straight from the shared store; the
// only local state is which month is shown and which day is selected.

import { FLOW_WEIGHT } from "../core/models.js";
import { keyFromDate, dateFromKey, addDays, startOfDay, daysBetween } from "../core/dates.js";

const React = window.React;
const { useState } = React;

// Sun..Sat via fmt.weekdayShort (Jan 1 2023 was a Sunday). Su-first matches
// CalendarView's en_US firstWeekday.
const weekdayHeaders = (fmt) =>
  Array.from({ length: 7 }, (_, i) => fmt.weekdayShort(new Date(2023, 0, 1 + i)));

export default function CalendarScreen({ ctx }) {
  const { store, nav, html, ui, Icon, fmt, today } = ctx;
  const { Card, IconButton, Badge, Button } = ui;

  const [monthDate, setMonthDate] = useState(
    () => new Date(today.getFullYear(), today.getMonth(), 1),
  );
  const [selectedKey, setSelectedKey] = useState(() => keyFromDate(today));

  const p = store.prediction(today);
  const year = monthDate.getFullYear();
  const month = monthDate.getMonth();

  // nil-padded 7-col grid: leading blanks before day 1, then the month's days.
  const leading = new Date(year, month, 1).getDay(); // Sunday = 0
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const cells = [];
  for (let i = 0; i < leading; i++) cells.push(null);
  for (let d = 1; d <= daysInMonth; d++) cells.push(new Date(year, month, d));

  const shift = (by) => setMonthDate(new Date(year, month + by, 1));

  // Predicted period run: nextPeriodStart .. + averagePeriodLength − 1.
  const isPredictedPeriod = (d0) => {
    if (!p.nextPeriodStart) return false;
    const start = startOfDay(p.nextPeriodStart);
    const end = addDays(start, p.averagePeriodLength - 1);
    return d0 >= start && d0 <= end;
  };

  // Logged bleeding wins, then ovulation, fertile window, then a predicted
  // upcoming period — mutually exclusive so each day reads as one state.
  // Note: only real bleeding (flow weight >= 2) washes as "period"; a spotting
  // day still shows its flow dot but no full wash.
  const stateFor = (date) => {
    const flow = store.logFor(date)?.flow ?? null;
    if (flow && FLOW_WEIGHT[flow] >= 2) return "period";
    const d0 = startOfDay(date);
    if (p.ovulationDate && daysBetween(d0, p.ovulationDate) === 0) return "ovulation";
    if (p.fertileStart && p.fertileEnd &&
        d0 >= startOfDay(p.fertileStart) && d0 <= startOfDay(p.fertileEnd)) return "fertile";
    if (isPredictedPeriod(d0)) return "predicted";
    return null;
  };

  const selectedDate = dateFromKey(selectedKey);
  const selectedLog = store.logFor(selectedDate);
  const selectedState = stateFor(selectedDate);

  const cell = { display: "grid", gridTemplateColumns: "repeat(7, 1fr)", gap: 2, justifyItems: "center" };

  return html`
    <div class="pad">
      <${Card} style=${{ marginTop: 4 }}>
        <div style=${{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
          <${IconButton} label="Previous month" variant="soft" onClick=${() => shift(-1)}>
            <${Icon} name="chevron-left" size=${20} />
          </${IconButton}>
          <div style=${{ fontFamily: "var(--font-display)", fontSize: "var(--text-lg)", fontWeight: 600, color: "var(--deep)" }}>
            ${fmt.monthName(monthDate)} ${year}
          </div>
          <${IconButton} label="Next month" variant="soft" onClick=${() => shift(1)}>
            <${Icon} name="chevron-right" size=${20} />
          </${IconButton}>
        </div>

        <div style=${{ ...cell, marginTop: 12 }} aria-hidden="true">
          ${weekdayHeaders(fmt).map((s, i) => html`
            <div key=${i} style=${{ fontSize: "var(--text-2xs)", fontWeight: 700, color: "var(--muted)" }}>${s}</div>
          `)}
        </div>

        <div style=${{ ...cell, marginTop: 6 }} role="grid">
          ${cells.map((date, i) => date == null
            ? html`<div key=${"b" + i} style=${{ width: 40, height: 40 }} />`
            : html`<${ui.DayCell}
                key=${keyFromDate(date)}
                day=${date.getDate()}
                state=${stateFor(date)}
                flow=${store.logFor(date)?.flow ?? null}
                today=${daysBetween(date, today) === 0}
                selected=${keyFromDate(date) === selectedKey}
                onClick=${() => setSelectedKey(keyFromDate(date))}
              />`)}
        </div>
      </${Card}>

      <${Card} variant="soft" style=${{ marginTop: 12, display: "flex", flexWrap: "wrap", gap: 10, alignItems: "center" }}>
        <${Badge} tone="menstrual" dot=${true}>Period</${Badge}>
        <${Badge} tone="fertile" dot=${true}>Fertile</${Badge}>
        <${Badge} tone="ovulation" dot=${true}>Ovulation</${Badge}>
        <span style=${{ display: "inline-flex", alignItems: "center", gap: 6 }}>
          <span style=${{ width: 12, height: 12, borderRadius: "50%", border: "1.5px dashed var(--phase-menstrual)" }} />
          <span style=${{ fontSize: "var(--text-xs)", color: "var(--text)" }}>Predicted</span>
        </span>
      </${Card}>

      <${Card} style=${{ marginTop: 12 }}>
        <div style=${{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 8 }}>
          <div style=${{ fontWeight: 700, color: "var(--deep)" }}>${fmt.longDate(selectedDate)}</div>
          ${selectedState && html`<${Badge} tone=${stateTone(selectedState)} dot=${true}>${stateLabel(selectedState)}</${Badge}>`}
        </div>

        ${selectedLog
          ? html`<div style=${{ marginTop: 10, display: "grid", gap: 8 }}>
              ${row(html, "Flow", selectedLog.flow ? fmt.flowLabel(selectedLog.flow) : null)}
              ${row(html, "Temperature", tempF(fmt, selectedLog.temperatureC))}
              ${row(html, "Moods", listLabels(fmt.moodLabel, selectedLog.moods))}
              ${row(html, "Symptoms", listLabels(fmt.symptomLabel, selectedLog.symptoms))}
              ${row(html, "Discharge", selectedLog.discharge ? fmt.dischargeLabel(selectedLog.discharge) : null)}
              ${row(html, "Note", selectedLog.note || null)}
            </div>`
          : html`<p style=${{ marginTop: 8, color: "var(--muted)" }}>Nothing logged on this day.</p>`}

        <${Button} variant="soft" block=${true} style=${{ marginTop: 14 }}
          onClick=${() => nav.open("log", { date: selectedDate })}>
          Edit this day
        </${Button}>
      </${Card}>
    </div>
  `;
}

// One "Label — value" row; renders nothing when the value is empty.
function row(html, label, value) {
  if (!value) return null;
  return html`<div style=${{ display: "flex", gap: 10, fontSize: "var(--text-base)" }}>
    <div style=${{ minWidth: 96, color: "var(--muted)" }}>${label}</div>
    <div style=${{ color: "var(--text)", flex: 1 }}>${value}</div>
  </div>`;
}

const listLabels = (labeler, arr) =>
  arr && arr.length ? arr.map(labeler).join(", ") : null;

const tempF = (fmt, celsius) => {
  const f = fmt.cToF(celsius);
  return f == null ? null : `${f.toFixed(1)} °F`;
};

const stateTone = (s) => (s === "predicted" || s === "period" ? "menstrual" : s);
const stateLabel = (s) =>
  ({ period: "Period", predicted: "Predicted", fertile: "Fertile", ovulation: "Ovulation" }[s] || "");
