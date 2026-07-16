// STUB — replaced by the full-parity theme editor. Wires preset switching so the
// data-theme plumbing can be smoke-tested.
const React = window.React;
const PRESETS = ["cherry", "rose", "peony", "soft"];

export default function ThemeEditor({ ctx }) {
  const { html, ui, nav } = ctx;
  const { Card } = ui;
  return html`
    <div class="pad" style=${{ padding: "8px 18px 20px" }}>
      <h2 style=${{ fontSize: 22, marginBottom: 12 }}>Theme</h2>
      <${Card}>
        <div style=${{ display: "grid", gap: 8 }}>
          ${PRESETS.map((t) => html`
            <button key=${t} onClick=${() => nav.setTheme(t)}
              style=${{ padding: "12px 16px", borderRadius: 14, cursor: "pointer", textAlign: "left",
                border: "1.5px solid var(--line)",
                background: nav.theme === t ? "var(--surface-soft)" : "var(--surface)",
                fontWeight: 600, color: "var(--deep)" }}>${t[0].toUpperCase() + t.slice(1)}</button>`)}
        </div>
      </${Card}>
    </div>
  `;
}
