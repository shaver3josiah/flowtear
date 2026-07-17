// Full-parity Calendar screen — a port of App/Views/CalendarView.swift +
// App/Components/DayCell.swift. A month grid of ctx.ui.DayCell: each day carries
// its computed phase state (period / predicted / fertile / ovulation) plus a
// logged-flow dot. Prev/next month pager, a color legend, and a read-only
// summary of the tapped day with an "Edit this day" hop into the Log screen.
//
// All state (logs + predictions) is read straight from the shared store; the
// only local state is which month is shown and which day is selected.

import { FLOW_WEIGHT } from "../core/models.js";
import { FLOW_COLOR } from "../components/flowScale.js";
import { keyFromDate, dateFromKey, addDays, startOfDay, daysBetween } from "../core/dates.js";

const React = window.React;
const { useState, useEffect } = React;

// ---- symptom-history deep link (CalendarView.swift `@Binding var focus`) ----
// Swift threads a SymptomFocus down from RootView; the web's nav.setTab(id)
// takes no props and tab screens always get `screenProps: {}` (app.js), so the
// symptom-echo sheet parks its request here instead:
//
//     requestSymptomFocus(symptom, anchorDate);  nav.setTab("calendar");
//
// Mounting picks up a parked request (switching tabs remounts this screen —
// app.js keys <main> on the tab); the listener covers the case where Calendar
// is ALREADY the tab, e.g. the echo opened from the Log overlay on top of it.
//
// ponytail: a module-local handoff beats threading params through app.js's nav
// for one caller. Upgrade to real nav params if a second screen ever needs them.
let pendingFocus = null;
const focusListeners = new Set();

/// Ask the Calendar to open on one symptom's history, anchored on `anchor`.
export function requestSymptomFocus(symptom, anchor) {
  pendingFocus = { symptom, anchor: startOfDay(anchor) };
  focusListeners.forEach((fn) => fn(pendingFocus));
}

// Sun..Sat via fmt.weekdayShort (Jan 1 2023 was a Sunday). Su-first matches
// CalendarView's en_US firstWeekday.
const weekdayHeaders = (fmt) =>
  Array.from({ length: 7 }, (_, i) => fmt.weekdayShort(new Date(2023, 0, 1 + i)));

const firstOfMonth = (d) => new Date(d.getFullYear(), d.getMonth(), 1);

export default function CalendarScreen({ ctx }) {
  const { store, nav, html, ui, Icon, fmt, today } = ctx;
  const { Card, IconButton, Badge, Button } = ui;

  // { symptom, anchor } | null — her symptom history, marked on the grid.
  const [focus, setFocus] = useState(() => pendingFocus);
  const anchor = pendingFocus ? pendingFocus.anchor : today;
  const [monthDate, setMonthDate] = useState(() => firstOfMonth(anchor));
  const [selectedKey, setSelectedKey] = useState(() => keyFromDate(anchor));
  // Swift's `focusedOccurrence`: which marked day the banner is sitting on.
  const [focusedKey, setFocusedKey] = useState(() => (pendingFocus ? keyFromDate(anchor) : null));

  // Land on the anchor occurrence and scroll the month to it (adoptFocus).
  const adoptFocus = (f) => {
    const k = keyFromDate(f.anchor);
    setFocus(f);
    setFocusedKey(k);
    setSelectedKey(k);
    setMonthDate(firstOfMonth(f.anchor));
  };

  useEffect(() => {
    pendingFocus = null; // mounting consumed it
    focusListeners.add(adoptFocus);
    return () => focusListeners.delete(adoptFocus);
  }, []);

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

  // ---- symptom history ----------------------------------------------------

  // Every day she's felt the focused symptom, oldest to newest.
  const occurrences = focus ? store.daysFelt(focus.symptom) : [];
  const occKeys = occurrences.map(keyFromDate);
  const selectedOccKey = focusedKey ?? occKeys[occKeys.length - 1] ?? null;
  const occIdx = selectedOccKey ? occKeys.indexOf(selectedOccKey) : -1;

  // Rings mark the focused symptom's days; the selected one is bolder. Gold on
  // dark, deep rose on light: the mark must read on white cards and on the pale
  // period wash, not just on near-black (CalendarView.swift dayCell overlay).
  // The two dark presets are the same list themeEditor.js calls DARK_PRESETS.
  const ringColor = nav.theme === "dark" || nav.theme === "midnight"
    ? "var(--flower-center)" : "var(--primary-strong)";

  const stepOcc = (by) => {
    const next = occIdx + by;
    if (next < 0 || next >= occKeys.length) return;
    setFocusedKey(occKeys[next]);
    setSelectedKey(occKeys[next]);          // the summary card below follows along
    setMonthDate(firstOfMonth(occurrences[next]));
  };

  const closeFocus = () => { setFocus(null); setFocusedKey(null); };

  const occDate = occIdx >= 0 ? occurrences[occIdx] : null;
  const occSnap = occDate ? store.phaseSnapshot(occDate) : null;

  // Explains what the marks mean and steps day to day through the history.
  // ponytail: Swift's banner repeats the day's whole log plus an "Open this
  // day's log" button; the web already has both right below (the selected-day
  // summary card and its Edit button), and stepping moves that selection, so
  // the banner only carries what the card doesn't — the phase line.
  const focusBanner = focus && html`
    <${Card} variant="accent" style=${{ marginTop: 4, marginBottom: 12 }}>
      <div style=${{ display: "flex", alignItems: "center", gap: 8 }}>
        <${Icon} name="heart" size=${15} color="var(--primary-strong)" />
        <div style=${{ fontSize: "var(--text-md)", fontWeight: 600, color: "var(--deep)" }}>
          ${fmt.symptomLabel(focus.symptom)} days
        </div>
        <div style=${{ flex: 1 }} />
        <${IconButton} label="Close symptom history" variant="ghost" onClick=${closeFocus}>
          <${Icon} name="x" size=${16} />
        </${IconButton}>
      </div>
      <p style=${{ margin: "8px 0 0", fontSize: "var(--text-xs)", color: "var(--muted)" }}>
        ${occKeys.length === 1
          ? "One day is marked below with a ring."
          : `${occKeys.length} days are marked below with rings. Step through them, or tap any marked day.`}
      </p>
      ${occDate && html`
        <div style=${{ display: "flex", alignItems: "center", gap: 8, marginTop: 10 }}>
          <${IconButton} label="Earlier day" variant="soft" disabled=${occIdx <= 0}
            style=${{ opacity: occIdx <= 0 ? 0.35 : 1 }} onClick=${() => stepOcc(-1)}>
            <${Icon} name="chevron-left" size=${18} />
          </${IconButton}>
          <div style=${{ flex: 1, textAlign: "center" }}>
            <div style=${{ fontSize: "var(--text-sm)", fontWeight: 700, color: "var(--deep)" }}>
              ${fmt.monthName(occDate)} ${occDate.getDate()}, ${occDate.getFullYear()}
            </div>
            ${occSnap && occSnap.phase && occSnap.day && html`
              <div style=${{ fontSize: "var(--text-xs)", color: "var(--muted)" }}>
                ${fmt.phaseLabel(occSnap.phase)} phase, cycle day ${occSnap.day}
              </div>`}
          </div>
          <${IconButton} label="Later day" variant="soft" disabled=${occIdx >= occKeys.length - 1}
            style=${{ opacity: occIdx >= occKeys.length - 1 ? 0.35 : 1 }} onClick=${() => stepOcc(1)}>
            <${Icon} name="chevron-right" size=${18} />
          </${IconButton}>
        </div>`}
    </${Card}>`;

  // One day of the grid. The wrapper exists so we can draw over the vendored
  // DayCell, which knows nothing about symptom rings or super-heavy flow.
  const dayCell = (date) => {
    const k = keyFromDate(date);
    const flow = store.logFor(date)?.flow ?? null;
    const isSelected = k === selectedKey;
    const isOcc = occKeys.includes(k);
    // Tapping a marked day selects it in the banner too; every day still just
    // selects (the web's summary card + "Edit this day" open the log, where
    // Swift's untracked days open it on tap).
    const onClick = () => { setSelectedKey(k); if (isOcc) setFocusedKey(k); };
    // The vendored DayCell's FLOW_COLOR has no `superHeavy` key, so passing it
    // through yields `undefined` and the dot silently VANISHES — a super-heavy
    // day would read as unlogged. Withhold the value and draw the dot here, at
    // the bundle's own geometry (bottom: size * 0.14, 5px), in the 5th color.
    const superHeavy = flow === "superHeavy";
    return html`
      <div key=${k} style=${{ position: "relative", display: "inline-flex" }}>
        <${ui.DayCell}
          day=${date.getDate()}
          state=${stateFor(date)}
          flow=${superHeavy ? null : flow}
          today=${daysBetween(date, today) === 0}
          selected=${isSelected}
          onClick=${onClick}
          ...${isOcc ? {
            "aria-label": `${date.getDate()}, ${fmt.symptomLabel(focus.symptom)} day`,
            "aria-pressed": k === selectedOccKey,
          } : {}}
        />
        ${superHeavy && !isSelected && html`
          <span aria-hidden="true" style=${{ position: "absolute", bottom: 5.6, left: "50%",
            transform: "translateX(-50%)", width: 5, height: 5, borderRadius: "50%",
            background: FLOW_COLOR.superHeavy, pointerEvents: "none" }} />`}
        ${isOcc && html`
          <span aria-hidden="true" style=${{ position: "absolute", inset: -3, borderRadius: 12,
            border: `${k === selectedOccKey ? 2.5 : 1.5}px solid ${ringColor}`,
            pointerEvents: "none" }} />`}
      </div>`;
  };

  return html`
    <div class="pad">
      ${focusBanner}
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
            : dayCell(date))}
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
