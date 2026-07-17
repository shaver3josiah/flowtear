// Phase detail sheet — the insight overlay opened from the CycleRing / PhaseBadge.
// Port of App/Components/PhaseDetailSheet.swift: what's happening hormonally,
// what's common right now, the short research report for this stretch of the
// cycle (the sheet's centerpiece), and its tips, all phase-colored. Opened via
// nav.open("phase", { phase }); reads that phase from ctx.screenProps.

import { report as phaseReport } from "../core/phaseResearch.js";

// Plain-language, non-alarmist phase content (PhaseDetailSheet.swift:131).
// Tips now come from the research reports in phaseResearch.js — only the
// intro + chips live here.
const CONTENT = {
  menstrual: {
    whatsHappening: "Your period. The uterine lining sheds while estrogen and progesterone sit at their lowest.",
    common: ["Cramps", "Fatigue", "Low back ache", "Low mood", "Headache"],
  },
  follicular: {
    whatsHappening: "Your period is over and estrogen is climbing as a new egg matures. Energy and mood usually lift.",
    common: ["Rising energy", "Brighter mood", "Clearer skin", "Motivation"],
  },
  fertile: {
    whatsHappening: "Your fertile window. Estrogen peaks and cervical mucus turns clear and stretchy. These are the days conception is most likely.",
    common: ["Higher libido", "Egg-white discharge", "More energy", "Sharper focus"],
  },
  ovulation: {
    whatsHappening: "An egg is released. Some feel a brief one-sided twinge; your basal temperature rises just after.",
    common: ["Peak libido", "One-sided twinge", "Temperature rise", "Confidence"],
  },
  luteal: {
    whatsHappening: "After ovulation, before your period. Progesterone rises then falls: the PMS window for many.",
    common: ["Bloating", "Cravings", "Tender breasts", "Mood shifts", "Cramps building"],
  },
};

export default function PhaseDetailScreen({ ctx }) {
  const { store, html, ui, Icon, fmt, today, nav, screenProps } = ctx;
  const { Button, IconButton } = ui;

  const phase = (screenProps && screenProps.phase) || "follicular";
  const c = CONTENT[phase] || CONTENT.follicular;
  const tint = `var(--phase-${phase})`;
  const soft = `var(--phase-${phase}-soft)`;

  const p = store.prediction(today);
  const day = (screenProps && screenProps.day) ?? p.cycleDay ?? 1;
  const cycleLength = (screenProps && screenProps.cycleLength) ?? Math.max(p.averageCycleLength, 1);
  const report = phaseReport(phase, day, cycleLength);

  const dayLine = p.hasHistory
    ? `Cycle day ${p.cycleDay} of ${p.averageCycleLength} · today`
    : null;

  // Real headings mirror Swift's .accessibilityAddTraits(.isHeader).
  const heading = (t) => html`
    <h3 style=${{ fontSize: "var(--text-md)", fontWeight: 600, color: "var(--deep)", margin: 0 }}>${t}</h3>`;

  const section = (title, body) => html`
    <div style=${{ display: "flex", flexDirection: "column", gap: 6 }}>
      ${heading(title)}
      <span style=${{ fontSize: "var(--text-base)", color: "var(--text)", lineHeight: "var(--leading-normal)" }}>${body}</span>
    </div>`;

  // The short report — the research behind this stretch of her cycle, in a
  // phase-tinted card so it reads as the sheet's centerpiece. A phase-colored
  // hairline keeps it distinct from the same-tinted chips above it.
  // (Swift's "text.book.closed" glyph has no offline counterpart — the app's
  // evidence glyph stands in.)
  const reportSection = html`
    <div style=${{
      display: "flex", flexDirection: "column", gap: 10,
      padding: 16, borderRadius: "var(--radius-md)", background: soft,
      border: `1px solid color-mix(in srgb, ${tint} 35%, transparent)`,
    }}>
      <h3 style=${{ display: "flex", alignItems: "center", gap: 6, margin: 0,
        fontSize: "var(--text-md)", fontWeight: 600, color: "var(--deep)" }}>
        <${Icon} name="bar-chart-2" size=${12} color="var(--deep)" />
        <span>A short report · ${report.title}</span>
      </h3>
      <span style=${{ fontSize: "var(--text-base)", color: "var(--text)", lineHeight: "var(--leading-relaxed)" }}>${report.body}</span>
      <span style=${{ fontSize: "var(--text-xs)", color: "var(--muted)", lineHeight: "var(--leading-normal)" }}>${report.evidenceNote}</span>
    </div>`;

  return html`
    <div style=${{ padding: "4px 20px 8px", display: "flex", flexDirection: "column", gap: 18 }}>
      <div style=${{ display: "flex", alignItems: "flex-start" }}>
        <div style=${{ display: "flex", flexDirection: "column", gap: 6, flex: 1 }}>
          ${dayLine && html`<span style=${{ fontSize: "var(--text-sm)", fontWeight: 600, color: "var(--muted)" }}>${dayLine}</span>`}
          <div style=${{ display: "flex", alignItems: "center", gap: 10 }}>
            <span style=${{ width: 14, height: 14, borderRadius: "50%", background: tint, flex: "0 0 auto" }} />
            <span style=${{ fontFamily: "var(--font-display)", fontWeight: 700, fontSize: "var(--text-2xl)", color: "var(--deep)" }}>${fmt.phaseLabel(phase)}</span>
          </div>
        </div>
        <${IconButton} label="Close" variant="ghost" onClick=${() => nav.close()}>
          <${Icon} name="x" size=${18} />
        </${IconButton}>
      </div>

      ${section("What's happening", c.whatsHappening)}

      <div style=${{ display: "flex", flexDirection: "column", gap: 8 }}>
        ${heading("Common right now")}
        <div style=${{ display: "flex", flexWrap: "wrap", gap: 8 }}>
          ${c.common.map((item) => html`
            <span key=${item} style=${{ fontSize: "var(--text-xs)", fontWeight: 500, color: "var(--deep)", padding: "7px 12px", borderRadius: "var(--radius-pill)", background: soft }}>${item}</span>`)}
        </div>
      </div>

      ${reportSection}

      <div style=${{ display: "flex", flexDirection: "column", gap: 8 }}>
        ${heading("Tips")}
        ${report.tips.map((tip) => html`
          <div key=${tip} style=${{ display: "flex", alignItems: "flex-start", gap: 8 }}>
            <span style=${{ width: 6, height: 6, borderRadius: "50%", background: tint, flex: "0 0 auto", marginTop: 7 }} />
            <span style=${{ fontSize: "var(--text-base)", color: "var(--text)", lineHeight: "var(--leading-normal)" }}>${tip}</span>
          </div>`)}
      </div>

      ${(phase === "fertile" || phase === "ovulation") && html`
        <span style=${{ fontSize: "var(--text-xs)", color: "var(--muted)" }}>Fertile-window estimates aren't a birth-control method.</span>`}

      <${Button} variant="soft" block=${true} onClick=${() => nav.close()}>Close</${Button}>
    </div>`;
}
