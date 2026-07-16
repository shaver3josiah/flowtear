// The tips sheet — a port of App/Components/TipsSheet.swift. "The hidden magic":
// the app's most delightful interactions are gestures with no visible
// affordance, so this little guide hands her all of them. Opened as an overlay
// via nav.open("tips") — from the lightbulb on Today, and from the settings
// sheet.
//
// Icons: the closest names in the offline Lucide set (web/vendor/icon.js) to
// Swift's SF Symbols — the set has no hand.draw / bag / wand equivalents.

const TIPS = [
  {
    icon: "edit-3",
    title: "Scrub the ring",
    text: "Drag anywhere on the cycle ring to travel day by day — tap it to read the story of that phase.",
  },
  {
    icon: "flower-2",
    title: "Spin, fling & pluck your flower",
    text: "Your flower sticker rides the ring like a bead. Fling it and it spins like a fidget; pull it clearly off and rest it anywhere — inside the ring or beside it. Carry it back and it beads on again.",
  },
  {
    icon: "sparkles",
    title: "The period-arc bonus",
    text: "Land your flower on the colored period arc and a few bonus petals fall out — once a day, for luck.",
  },
  {
    icon: "zap",
    title: "Tap-to-jump sliders",
    text: "The flow and log sliders jump straight to wherever you tap — no dragging required.",
  },
  {
    icon: "check",
    title: "The whole plan is tappable",
    text: "In Stretch, open any day of your plan to see its moves, check them off, or run that day's guided session on the spot — even off-schedule.",
  },
  {
    icon: "clock",
    title: "Pause your plan",
    text: "Inside the plan picker there's a pause switch — missed days cost nothing while life happens.",
  },
  {
    icon: "gift",
    title: "Petals buy the pretty things",
    text: "Every stretch earns petal points; the garden shop turns them into flowers, palettes, sounds — even Posey. The book icon has the full rules.",
  },
  {
    icon: "flower",
    title: "Double-tap the bloom",
    text: "The flower in Today's corner opens a little about page with honest answers about predictions and privacy.",
  },
  {
    icon: "bar-chart-2",
    title: "Your data is yours",
    text: "Everything lives on this phone only. Export it all as a spreadsheet from Insights whenever you like.",
  },
];

export default function TipsSheet({ ctx }) {
  const { html, ui, Icon, nav } = ctx;
  const { IconButton } = ui;

  const tipRow = (tip) => html`<div key=${tip.title} style=${{
    display: "flex", alignItems: "flex-start", gap: 12, padding: 16,
    background: "var(--surface)", borderRadius: 16, border: "1px solid var(--line)",
  }}>
    <span style=${{ flex: "0 0 auto", width: 26, display: "inline-flex", justifyContent: "center", paddingTop: 1 }}>
      <${Icon} name=${tip.icon} size=${17} color="var(--primary-strong)" />
    </span>
    <div style=${{ display: "grid", gap: 3 }}>
      <div style=${{ fontSize: 13, fontWeight: 700, color: "var(--deep)" }}>${tip.title}</div>
      <div style=${{ fontSize: 13, color: "var(--text)", lineHeight: 1.5 }}>${tip.text}</div>
    </div>
  </div>`;

  return html`
    <div class="pad" style=${{ padding: "8px 18px 20px", display: "grid", gap: 24 }}>
      <div style=${{ display: "flex", alignItems: "flex-start", gap: 10 }}>
        <div style=${{ flex: 1, display: "grid", gap: 2 }}>
          <h2 style=${{ fontFamily: "var(--font-display)", fontSize: 22, fontWeight: 700, color: "var(--deep)", margin: 0 }}>The hidden magic</h2>
          <div style=${{ fontSize: 13, color: "var(--muted)" }}>
            Everything this garden can do — including the parts that don't announce themselves.
          </div>
        </div>
        <${IconButton} label="Close" onClick=${nav.close}><${Icon} name="x" size=${18} /><//>
      </div>

      <div style=${{ display: "grid", gap: 8 }}>${TIPS.map(tipRow)}</div>
    </div>
  `;
}
