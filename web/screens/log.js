// Full-parity daily Log — a port of App/Views/LogView.swift.
// Sections in Swift order: Flow · Discharge · Temperature · Mood · Symptoms ·
// Note, each in a tinted card, under a serif date header with day-stepping and
// an at-a-glance progress row. Commit is a primary "Log this day" button that
// confirms with "Logged, love." and closes the sheet when opened as a Calendar
// overlay (screenProps.date present); as the Log tab it stays put.
//
// ponytail: every edit writes straight through to the store (upsert of the
// rebuilt DayLog) instead of Swift's separate draft + SlideToLog/commit dance.
// The store is the single source of truth the task requires, re-opening a day
// reads its saved values back, and there is no draft to lose on scrim-dismiss.
// Upgrade path: reintroduce a draft only if per-keystroke saves ever jank.

import { MOODS, DISCHARGE, label, emptyLog, isEmptyLog } from "../core/models.js";
import { addDays, daysBetween, dateFromKey } from "../core/dates.js";
import { FlowScale } from "../components/flowScale.js";
import { GlitterHint } from "../components/glitterHint.js";
import { requestSymptomFocus } from "./calendar.js";

const React = window.React;
const { useState } = React;

// Symptoms clustered the way she'd think of them (LogView.symptomGroups),
// over OUR SYMPTOMS vocabulary.
const SYMPTOM_GROUPS = [
  ["Aches", ["cramps", "headache", "backache"]],
  ["Body", ["bloating", "tenderBreasts", "acne"]],
  ["Digestion", ["nausea", "cravings", "diarrhea", "constipation"]],
  ["Energy & sleep", ["fatigue", "insomnia"]],
];

const toggle = (arr, v) => (arr.includes(v) ? arr.filter((x) => x !== v) : [...arr, v]);

export default function LogScreen({ ctx }) {
  const { store, html, ui, Icon, fmt, today, nav, screenProps } = ctx;
  // FlowScale comes from ../components/flowScale.js, NOT ctx.ui: the vendored
  // one only knows four levels and can't render `superHeavy`.
  const { Card, Chip, SymptomChip, Button, IconButton, Toast } = ui;

  const isOverlay = screenProps?.date != null;
  const [date, setDate] = useState(() => screenProps?.date ?? today);
  const [saved, setSaved] = useState(false);

  const key = store.key(date);
  const log = store.logFor(date) ?? emptyLog(key);

  // Rebuild the DayLog for this date and persist it. Reads the store fresh so
  // it never writes over a concurrent edit from a stale closure.
  const mutate = (patch) =>
    store.upsert({ ...(store.logFor(date) ?? emptyLog(key)), ...patch, dateKey: key });

  const atToday = daysBetween(date, today) <= 0;
  const step = (by) => {
    const d = addDays(date, by);
    if (daysBetween(d, today) < 0) return; // never step past today
    setDate(d);
  };

  // Temperature is stored °C, shown/edited in °F.
  const tempF = log.temperatureC == null ? null : fmt.cToF(log.temperatureC);
  const recent = store.recentTemperatures().slice(-1)[0];
  const suggestedF = recent ? fmt.cToF(recent.celsius) : 97.8;
  const tempValue = log.tempSkipped === true
    ? "Not today"
    : (tempF != null ? `${tempF.toFixed(2)}°` : null);

  const count = (n) => (n ? `${n} picked` : null);

  // No commit dance here — every tap is already written through to the store.
  const onSymptom = (s) => mutate({ symptoms: toggle(log.symptoms, s) });

  // A quiet clock pops up beside a picked symptom she's felt before. Nothing
  // opens on its own; the history tour waits for this tap. (LogView.swift
  // historyButton.)
  const openHistory = (s) => {
    const last = store.lastFelt(s, date);
    if (!last) return;
    nav.open("symptomEcho", {
      symptom: s, lastDate: last, loggingDate: date,
      // Swift's onShowSymptomOnCalendar: the sheet asks, RootView wires the
      // tab. Here the Calendar owns the channel (its nav has no params).
      onShowCalendar: (sym, day) => { requestSymptomFocus(sym, day); nav.setTab("calendar"); },
    });
  };

  const onSave = () => {
    setSaved(true); // edits already persisted; this confirms + navigates
    if (isOverlay) setTimeout(nav.close, 1000);
    else setTimeout(() => setSaved(false), 2400);
  };

  // ---- shared section chrome (LogSection.swift) ----
  const Section = (icon, title, tint, soft, value, children) => html`
    <${Card} style=${{ marginTop: 14 }}>
      <div style=${{ display: "flex", alignItems: "center", gap: 10, marginBottom: 12 }}>
        <div style=${{ width: 30, height: 30, borderRadius: "50%", flex: "none",
                       background: `var(${soft})`, display: "grid", placeItems: "center" }}>
          <${Icon} name=${icon} size=${15} color=${`var(${tint})`} />
        </div>
        <div style=${{ fontFamily: "var(--font-display)", fontSize: 17, fontWeight: 600, color: "var(--deep)" }}>${title}</div>
        <div style=${{ flex: 1 }} />
        ${value && html`<div style=${{ fontSize: 13, fontWeight: 700, color: `var(${tint})` }}>${value}</div>`}
      </div>
      ${children}
    </${Card}>
  `;

  const checkbox = (checked, text, onClick) => html`
    <button type="button" onClick=${onClick} style=${{ display: "flex", alignItems: "center", gap: 8,
        marginTop: 8, padding: "6px 0", width: "100%", background: "none", border: "none",
        cursor: "pointer", textAlign: "left", font: "inherit", color: "var(--text)" }}>
      <span style=${{ width: 18, height: 18, borderRadius: 5, flex: "none", display: "grid", placeItems: "center",
          border: `2px solid var(${checked ? "--phase-ovulation" : "--line"})`,
          background: checked ? "var(--phase-ovulation)" : "transparent" }}>
        ${checked && html`<${Icon} name="check" size=${12} color="var(--surface)" />`}
      </span>
      <span style=${{ fontSize: 14, fontWeight: 500 }}>${text}</span>
    </button>
  `;

  const wrap = { display: "flex", flexWrap: "wrap", gap: 8 };

  // at-a-glance dots (pinned in Swift; rendered inline here inside the sheet)
  const glance = [
    ["droplet", log.flow != null, "--phase-menstrual"],
    ["cloud-rain", log.discharge != null, "--phase-fertile"],
    ["thermometer", log.temperatureC != null || log.tempSkipped === true, "--phase-ovulation"],
    ["smile", log.moods.length > 0, "--phase-luteal"],
    ["heart", log.symptoms.length > 0, "--primary-strong"],
    ["edit-3", !!log.note, "--deep"],
  ];

  return html`
    <div style=${{ padding: "8px 16px 24px" }}>
      <!-- header: serif date with day-stepping, plus the garden shop.
           The date stays truly centered and the controls ride the edges: the
           two side groups share the leftover width equally (flex-basis 0), so
           the extra shop button on the right can't push the date off-center.
           (Swift does the same with a ZStack.) -->
      <div style=${{ display: "flex", alignItems: "center", gap: 8 }}>
        <div style=${{ flex: "1 0 0", display: "flex", justifyContent: "flex-start" }}>
          <${IconButton} label="Previous day" onClick=${() => step(-1)}>
            <${Icon} name="chevron-left" size=${20} />
          </${IconButton}>
        </div>
        <div style=${{ textAlign: "center" }}>
          <div style=${{ fontFamily: "var(--font-display)", fontSize: 24, fontWeight: 700, color: "var(--deep)" }}>
            ${atToday ? "Today" : fmt.weekday(date)}
          </div>
          <input type="date" value=${key} max=${store.key(today)}
            onChange=${(e) => e.target.value && setDate(dateFromKey(e.target.value))}
            style=${{ border: "none", background: "none", color: "var(--muted)", font: "inherit",
                      fontSize: 13, textAlign: "center", padding: 0 }} />
        </div>
        <div style=${{ flex: "1 0 0", display: "flex", justifyContent: "flex-end", alignItems: "center", gap: 8 }}>
          <${GlitterHint} hintKey="logShop">
            <${IconButton} label="Garden shop" onClick=${() => nav.open("garden")}>
              <!-- Swift's "bag" glyph has no offline lucide counterpart; "gift"
                   is the shop-shaped icon the vendored set does carry. -->
              <${Icon} name="gift" size=${18} />
            </${IconButton}>
          </${GlitterHint}>
          <${IconButton} label="Next day" onClick=${() => step(1)} disabled=${atToday}
            style=${{ opacity: atToday ? 0.35 : 1 }}>
            <${Icon} name="chevron-right" size=${20} />
          </${IconButton}>
        </div>
      </div>

      <!-- at-a-glance progress -->
      <div style=${{ display: "flex", padding: "10px 0", marginTop: 8,
          borderBottom: "1px solid color-mix(in srgb, var(--flower-center) 60%, transparent)" }}>
        ${glance.map(([icon, filled, tint], i) => html`
          <div key=${i} style=${{ flex: 1, display: "grid", placeItems: "center",
              transform: filled ? "scale(1)" : "scale(0.85)", transition: "transform .2s" }}>
            <${Icon} name=${icon} size=${14} color=${filled ? `var(${tint})` : "var(--line)"} />
          </div>`)}
      </div>

      <!-- Flow -->
      ${Section("droplet", "Flow", "--phase-menstrual", "--phase-menstrual-soft",
        log.flow ? label(log.flow) : null,
        html`<${FlowScale} value=${log.flow} onChange=${(lvl) => mutate({ flow: lvl })} />`)}

      <!-- Discharge (single-select chips over DISCHARGE, tap-to-clear) -->
      ${Section("cloud-rain", "Discharge", "--phase-fertile", "--phase-fertile-soft",
        log.discharge ? label(log.discharge) : null,
        html`<div style=${wrap}>
          ${DISCHARGE.map((d) => html`<${Chip} key=${d} selected=${log.discharge === d}
            onClick=${() => mutate({ discharge: log.discharge === d ? null : d })}>${label(d)}</${Chip}>`)}
        </div>`)}

      <!-- Temperature (edit in °F, store °C; skip -> tempSkipped) -->
      ${Section("thermometer", "Temperature", "--phase-ovulation", "--phase-ovulation-soft", tempValue,
        log.tempSkipped === true
          ? checkbox(true, "Didn't take it this morning", () => mutate({ tempSkipped: null }))
          : html`
            <div>
              <div style=${{ display: "flex", alignItems: "baseline", gap: 6, marginBottom: 8 }}>
                <span style=${{ fontFamily: "var(--font-display)", fontSize: 32, fontWeight: 600,
                    color: tempF == null ? "var(--muted)" : "var(--deep)" }}>${(tempF ?? suggestedF).toFixed(2)}</span>
                <span style=${{ fontSize: 13, fontWeight: 600, color: "var(--muted)" }}>°F</span>
                ${tempF == null && html`<span style=${{ fontSize: 12, color: "var(--muted)" }}>slide to set</span>`}
              </div>
              <input type="range" min="96" max="100" step="0.05" value=${tempF ?? suggestedF}
                aria-label="Basal temperature"
                onChange=${(e) => mutate({ temperatureC: fmt.fToC(parseFloat(e.target.value)), tempSkipped: null })}
                style=${{ width: "100%", accentColor: "var(--phase-ovulation)" }} />
              <div style=${{ display: "flex", justifyContent: "space-between", fontSize: 11,
                  fontWeight: 500, color: "var(--muted)" }}><span>96°</span><span>100°</span></div>
              ${checkbox(false, "Didn't take it this morning", () => mutate({ tempSkipped: true, temperatureC: null }))}
            </div>`)}

      <!-- Mood (multi-select over MOODS) -->
      ${Section("smile", "Mood", "--phase-luteal", "--phase-luteal-soft", count(log.moods.length),
        html`<div style=${wrap}>
          ${MOODS.map((m) => html`<${Chip} key=${m} selected=${log.moods.includes(m)}
            onClick=${() => mutate({ moods: toggle(log.moods, m) })}>${label(m)}</${Chip}>`)}
        </div>`)}

      <!-- Symptoms (grouped, multi-select over our SYMPTOMS). A selected
           symptom she's felt before grows a little clock beside its chip —
           tapping IT (not the chip) opens the history tour. -->
      ${Section("heart", "Symptoms", "--primary-strong", "--surface-soft", count(log.symptoms.length),
        html`<div>
          ${SYMPTOM_GROUPS.map(([group, syms]) => html`
            <div key=${group} style=${{ marginBottom: 10 }}>
              <div style=${{ textTransform: "uppercase", letterSpacing: "var(--tracking-label)",
                  fontSize: 11, fontWeight: 700, color: "var(--muted)", marginBottom: 6 }}>${group}</div>
              <div style=${wrap}>
                ${syms.map((s) => {
                  const selected = log.symptoms.includes(s);
                  const last = selected ? store.lastFelt(s, date) : null;
                  return html`
                    <div key=${s} style=${{ display: "inline-flex", alignItems: "center", gap: 6 }}>
                      <${SymptomChip} symptom=${s} label=${label(s)}
                        selected=${selected} onClick=${() => onSymptom(s)} />
                      ${last && html`
                        <button type="button" onClick=${() => openHistory(s)}
                          aria-label=${`${label(s)} history`}
                          aria-description="Shows the last time you felt this"
                          style=${{
                            display: "grid", placeItems: "center", flex: "none",
                            width: 40, height: 40, borderRadius: "50%", padding: 0, cursor: "pointer",
                            background: "var(--surface-soft)", border: "1px solid var(--line)",
                            animation: "flowtier-bloom-in var(--dur-base) var(--ease-signature)",
                          }}>
                          <${Icon} name="clock" size=${15} color="var(--primary-strong)" />
                        </button>`}
                    </div>`;
                })}
              </div>
            </div>`)}
        </div>`)}

      <!-- Note -->
      ${Section("edit-3", "Note", "--deep", "--surface-2", log.note ? "Written" : null,
        html`<textarea rows=${3} value=${log.note} placeholder="Anything worth remembering…"
          onChange=${(e) => mutate({ note: e.target.value })}
          style=${{ width: "100%", resize: "vertical", minHeight: 64, font: "inherit", color: "var(--text)",
                    background: "var(--surface)", border: "1px solid var(--line)", borderRadius: 12,
                    padding: "10px 12px" }} />`)}

      <!-- commit -->
      <div style=${{ marginTop: 18 }}>
        <${Button} variant="primary" block=${true} onClick=${onSave} disabled=${isEmptyLog(log)}
          iconLeft=${html`<${Icon} name="check" size=${18} color="var(--surface)" />`}>
          Log this day
        </${Button}>
      </div>

      ${saved && html`<div style=${{ marginTop: 12 }}>
        <${Toast} title="Logged, love." message=${atToday ? "Saved to today." : `Saved to ${fmt.longDate(date)}.`} />
      </div>`}
    </div>
  `;
}
