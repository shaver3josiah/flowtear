// The about sheet — a port of App/Views/AboutView.swift. A little love letter
// plus four tap-through FAQs. Opened as an overlay via nav.open("about") — from
// double-tapping the flower in Today's corner, and from the settings sheet.

const { useState } = window.React;

// Swift reads CFBundleShortVersionString/CFBundleVersion. There's no build step
// here to inject one, so this tracks package.json by hand — bump both together.
const VERSION = "Version 0.1.0";

const FAQS = [
  {
    q: "How accurate are the predictions?",
    a: "They're estimates built from your own logs — the ring starts as a best guess and sharpens with every cycle you record. Predictions are never a promise, and the fertile window is not birth control.",
  },
  {
    q: "Where does my data live?",
    a: "On this phone, full stop. No account, no cloud, no analytics. You can export everything as a spreadsheet from Insights whenever you like — it's your data.",
  },
  {
    q: "How do petal points work?",
    a: "Every stretch pose you check earns 15, chains earn +5, a finished day +10, and first-time guided poses +30 — multiplied by your plan (trio ×1, 3-day ×2, 14-day ×4). Spend them in the garden shop. The full rules live behind the book icon in Stretch.",
  },
  {
    q: "Can stretching really help cramps?",
    a: "The research is genuinely promising — clinical trials of gentle poses like Cobra, Cat and Fish reduced period-cramp pain, and a review of many studies agrees. It's preventive, builds over a couple of cycles, and it's wellness support, not medical care.",
  },
];

export default function AboutView({ ctx }) {
  const { html, ui, Icon, nav } = ctx;
  const { IconButton, FlowerMark } = ui;
  const [openFAQ, setOpenFAQ] = useState(null);

  const faqCard = (faq, i) => {
    const open = openFAQ === i;
    return html`<button key=${i}
      aria-expanded=${open}
      onClick=${() => setOpenFAQ(open ? null : i)}
      style=${{
        display: "grid", gap: 8, width: "100%", textAlign: "left", padding: 16, cursor: "pointer",
        background: "var(--surface)", borderRadius: 16, border: "1px solid var(--line)",
      }}>
      <div style=${{ display: "flex", alignItems: "center", gap: 8 }}>
        <span style=${{ flex: 1, fontSize: 13, fontWeight: 700, color: "var(--deep)" }}>${faq.q}</span>
        <span style=${{
          flex: "0 0 auto", display: "inline-flex", transition: `transform var(--dur-fast) var(--ease-signature)`,
          transform: open ? "rotate(180deg)" : "none",
        }}>
          <${Icon} name="chevron-down" size=${11} color="var(--muted)" strokeWidth=${2.5} />
        </span>
      </div>
      ${open && html`<div style=${{ fontSize: 13, color: "var(--text)", lineHeight: 1.5 }}>${faq.a}</div>`}
    </button>`;
  };

  return html`
    <div class="pad" style=${{ padding: "8px 18px 20px", display: "grid", gap: 20, justifyItems: "center" }}>
      <div style=${{ display: "flex", justifyContent: "flex-end", width: "100%" }}>
        <${IconButton} label="Close" onClick=${nav.close}><${Icon} name="x" size=${18} /><//>
      </div>

      <${FlowerMark} size=${64} breathe />

      <div style=${{ fontFamily: "var(--font-script)", fontSize: 38, lineHeight: 1.2, color: "var(--deep)" }}>Uncorked</div>

      <div style=${{ fontSize: 13, color: "var(--muted)", textAlign: "center", lineHeight: 1.5 }}>
        A little garden for your cycle — tracking, honest predictions, and Posey cheering you through the stretchy weeks. Made with love.
      </div>

      <div style=${{ fontSize: 11, fontWeight: 500, color: "var(--muted)" }}>${VERSION}</div>

      <div style=${{ display: "grid", gap: 8, width: "100%" }}>${FAQS.map(faqCard)}</div>
    </div>
  `;
}
