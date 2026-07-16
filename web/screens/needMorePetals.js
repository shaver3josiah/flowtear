// The gentle "not yet" splash — a port of App/Components/NeedMorePetalsView.swift.
// Instead of a locked tap silently doing nothing, this names the exact gap, shows
// how far she's come, and walks her straight to the stretching side to earn the
// rest.
//
// Opened as an overlay: nav.open("needPetals", { name, price, back })
//   name  — what she tapped, already phrased for "to bring home ___"
//   price — its cost; the gap is price − balance
//   back  — optional overlay to reopen on "Keep browsing" (the shop sends "garden")
// `needed` is accepted instead of `price` for callers that only know the gap.

import { rewards } from "../core/rewards.js";

const { useState, useEffect } = window.React;

function useRewards() {
  const [, force] = useState(0);
  useEffect(() => rewards.subscribe(() => force((n) => n + 1)), []);
  return rewards;
}

export default function NeedMorePetalsScreen({ ctx }) {
  const { html, ui, Icon, nav, screenProps = {} } = ctx;
  const { Button, IconButton, FlowerMark, PetalRain } = ui;
  const r = useRewards();

  const name = screenProps.name || "that";
  const price = screenProps.price ?? (r.balance + (screenProps.needed ?? 0));
  const needed = Math.max(price - r.balance, 0);
  const progress = Math.min(r.balance / Math.max(price, 1), 1);
  const back = screenProps.back;

  return html`<div
    role="group"
    aria-label=${`You need ${needed} more petal points for ${name}. You have ${r.balance} of ${price}.`}
    style=${{
      position: "relative", overflow: "hidden", padding: "12px 18px 24px",
      display: "flex", flexDirection: "column", alignItems: "center", gap: 14, textAlign: "center",
    }}>
    ${PetalRain && html`<${PetalRain} count=${8} />`}

    <div style=${{ alignSelf: "flex-end" }}>
      <${IconButton} label="Close" onClick=${nav.close}><${Icon} name="x" size=${18} /><//>
    </div>

    <${FlowerMark} size=${56} breathe=${true} />
    <h2 style=${{ fontSize: 24, fontWeight: 700, color: "var(--deep)", margin: 0 }}>Almost there, petal!</h2>

    <div>
      <div style=${{ fontSize: 48, fontWeight: 600, color: "var(--primary-strong)", lineHeight: 1.1, fontVariantNumeric: "tabular-nums" }}>${needed}</div>
      <div style=${{ fontWeight: 700, fontSize: 11, letterSpacing: 1.2, color: "var(--muted)" }}>MORE PETAL POINTS</div>
      <div style=${{ fontSize: 14, fontWeight: 500, color: "var(--deep)", marginTop: 6 }}>to bring home ${name}</div>
    </div>

    <div style=${{ width: "100%", maxWidth: 320, display: "flex", flexDirection: "column", gap: 6 }}>
      <div style=${{ height: 10, borderRadius: 999, background: "var(--surface-soft)", overflow: "hidden" }}>
        <div style=${{ height: "100%", width: `${Math.max(progress * 100, 3)}%`, borderRadius: 999, background: "var(--primary-strong)" }} />
      </div>
      <div style=${{ fontSize: 12, color: "var(--muted)" }}>${r.balance} of ${price} saved</div>
    </div>

    <div style=${{ width: "100%", maxWidth: 320, display: "flex", flexDirection: "column", gap: 8, marginTop: 4 }}>
      <${Button} variant="primary" block=${true} iconLeft=${html`<${Icon} name="activity" size=${16} />`}
        onClick=${() => nav.setTab("stretch")}>Earn petals stretching<//>
      <${Button} variant="ghost" size="sm" block=${true}
        onClick=${() => (back ? nav.open(back) : nav.close())}>Keep browsing<//>
    </div>
  </div>`;
}
