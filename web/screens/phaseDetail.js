// Phase detail sheet — the insight overlay opened from the CycleRing / PhaseBadge.
// Port of App/Components/PhaseDetailSheet.swift: what's happening hormonally,
// what's common right now, and a few gentle tips, all phase-colored. Opened via
// nav.open("phase", { phase }); reads that phase from ctx.screenProps.

// Plain-language, non-alarmist phase content (PhaseDetailSheet.swift:90).
const CONTENT = {
  menstrual: {
    whatsHappening: "Your period. The uterine lining sheds while estrogen and progesterone sit at their lowest.",
    common: ["Cramps", "Fatigue", "Low back ache", "Low mood", "Headache"],
    tips: [
      "Heat on your lower belly eases cramps.",
      "Gentle movement and stretching often help more than lying still.",
      "Iron-rich food and water go a long way now.",
    ],
  },
  follicular: {
    whatsHappening: "Your period is over and estrogen is climbing as a new egg matures. Energy and mood usually lift.",
    common: ["Rising energy", "Brighter mood", "Clearer skin", "Motivation"],
    tips: [
      "A strong stretch of the month for harder workouts or new plans.",
      "Estrogen supports strength and recovery — use it.",
    ],
  },
  fertile: {
    whatsHappening: "Your fertile window. Estrogen peaks and cervical mucus turns clear and stretchy — the days conception is most likely.",
    common: ["Higher libido", "Egg-white discharge", "More energy", "Sharper focus"],
    tips: [
      "Trying to conceive? These are your best days.",
      "Cervical mucus and temperature tell you more than the calendar.",
    ],
  },
  ovulation: {
    whatsHappening: "An egg is released. Some feel a brief one-sided twinge; your basal temperature rises just after.",
    common: ["Peak libido", "One-sided twinge", "Temperature rise", "Confidence"],
    tips: [
      "Log your morning temperature — it confirms ovulation the next day.",
      "The fertile window closes about a day after.",
    ],
  },
  luteal: {
    whatsHappening: "After ovulation, before your period. Progesterone rises then falls — the PMS window for many.",
    common: ["Bloating", "Cravings", "Tender breasts", "Mood shifts", "Cramps building"],
    tips: [
      "Gentle daily stretching across these two weeks can ease cramps.",
      "Magnesium, steady sleep, and lighter movement help.",
      "However today feels, this dip is hormonal — not you.",
    ],
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
  const dayLine = p.hasHistory
    ? `Cycle day ${p.cycleDay} of ${p.averageCycleLength} · today`
    : null;

  const section = (title, body) => html`
    <div style=${{ display: "flex", flexDirection: "column", gap: 6 }}>
      <span style=${{ fontSize: "var(--text-md)", fontWeight: 600, color: "var(--deep)" }}>${title}</span>
      <span style=${{ fontSize: "var(--text-base)", color: "var(--text)", lineHeight: "var(--leading-normal)" }}>${body}</span>
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
        <span style=${{ fontSize: "var(--text-md)", fontWeight: 600, color: "var(--deep)" }}>Common right now</span>
        <div style=${{ display: "flex", flexWrap: "wrap", gap: 8 }}>
          ${c.common.map((item) => html`
            <span key=${item} style=${{ fontSize: "var(--text-xs)", fontWeight: 500, color: "var(--deep)", padding: "7px 12px", borderRadius: "var(--radius-pill)", background: soft }}>${item}</span>`)}
        </div>
      </div>

      <div style=${{ display: "flex", flexDirection: "column", gap: 8 }}>
        <span style=${{ fontSize: "var(--text-md)", fontWeight: 600, color: "var(--deep)" }}>Tips</span>
        ${c.tips.map((tip) => html`
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
