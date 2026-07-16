// The garden shop — a port of App/Views/GardenShopView.swift. Spend petal points
// on flower stickers (ten of rising rarity), Posey herself, palettes, the
// celebration chime, a custom accent, and the Color Studio. Owned flowers can be
// worn as the Today-tab sticker. All economy + persistence lives in the shared
// rewards singleton (web/core/rewards.js); this screen just reads and drives it.

import { rewards, FLOWERS, PRICES, PAID_THEMES } from "../core/rewards.js";

const { useState, useEffect } = window.React;

// Re-render this screen whenever the (separate) rewards store changes.
function useRewards() {
  const [, force] = useState(0);
  useEffect(() => rewards.subscribe(() => force((n) => n + 1)), []);
  return rewards;
}

// A different-color swatch per paid palette. Best-effort, on-token (the real
// per-theme accent lives in the native Theme; here it only needs to read distinct).
const THEME_SWATCH = {
  pink: "var(--primary)",
  peony: "var(--primary-strong)",
  soft: "var(--good)",
  light: "var(--flower-center)",
};
const themeLabel = (n) => n[0].toUpperCase() + n.slice(1);

export default function GardenScreen({ ctx }) {
  const { html, ui, Icon, nav, store } = ctx;
  const { Card, IconButton, Button, FlowerMark, PetalRain } = ui;
  const r = useRewards();

  const [burst, setBurst] = useState(0);          // bumps a petal-rain celebration
  const [showShare, setShowShare] = useState(false);

  const celebrate = () => {
    setBurst((n) => n + 1);
    r.playCelebrationIfOwned();
  };

  // ---- a procedural inline bloom, so the ten flowers read as distinct without
  // any emoji or external asset. Petal count + fill vary by catalog position.
  const Bloom = ({ id, size = 34, dim = false }) => {
    const idx = FLOWERS.findIndex((f) => f.id === id);
    const petals = 5 + (idx % 6);                 // 5..10
    const fills = ["var(--primary)", "var(--primary-strong)", "var(--flower-center)", "var(--good)"];
    const fill = fills[idx % fills.length];
    const c = size / 2;
    const ring = size * 0.26;
    const petalRx = size * 0.15;
    const petalRy = size * 0.26;
    const nodes = [];
    for (let i = 0; i < petals; i++) {
      const a = (i / petals) * Math.PI * 2;
      const px = c + Math.cos(a) * ring;
      const py = c + Math.sin(a) * ring;
      nodes.push(html`<ellipse key=${i} cx=${px} cy=${py} rx=${petalRx} ry=${petalRy}
        transform=${`rotate(${(a * 180) / Math.PI + 90} ${px} ${py})`} fill=${fill} />`);
    }
    return html`<svg width=${size} height=${size} viewBox=${`0 0 ${size} ${size}`} aria-hidden="true"
        style=${{ opacity: dim ? 0.5 : 1, filter: dim ? "saturate(0.35)" : "none", display: "block" }}>
      ${nodes}
      <circle cx=${c} cy=${c} r=${size * 0.17} fill="var(--flower-center)" />
    </svg>`;
  };

  const PointsPill = () => html`<div style=${{
    display: "inline-flex", alignItems: "center", gap: 5, height: 32, padding: "0 12px",
    borderRadius: 999, background: "var(--surface)", border: "1px solid var(--line)",
  }}>
    <${Icon} name="sparkles" size=${13} color="var(--flower-center)" />
    <span style=${{ fontWeight: 600, color: "var(--deep)", fontVariantNumeric: "tabular-nums" }}>${r.balance}</span>
  </div>`;

  // A small pill button used across the shop for buy / wear / owned states.
  const pill = (label, { onClick, tone = "soft", disabled = false, icon } = {}) => {
    const bg = tone === "strong" ? "var(--primary-strong)" : "var(--surface-soft)";
    const fg = tone === "strong" ? "var(--surface)"
      : tone === "muted" ? "var(--muted)"
      : tone === "primary" ? "var(--primary-strong)" : "var(--deep)";
    return html`<button onClick=${onClick} disabled=${disabled} aria-disabled=${disabled}
      style=${{
        display: "inline-flex", alignItems: "center", gap: 4, padding: "5px 10px", borderRadius: 999,
        border: "none", background: bg, color: fg, fontWeight: 700, fontSize: 12,
        cursor: disabled ? "default" : "pointer", opacity: disabled ? 0.6 : 1,
      }}>
      ${icon && html`<${Icon} name=${icon} size=${12} color=${fg} />`}${label}
    </button>`;
  };

  // ---- flower cell ----
  const flowerCell = (f) => {
    const owned = r.ownedFlowers.has(f.id);
    const equipped = r.activeSticker === f.id;
    const affordable = r.canAfford(f.price);
    const onClick = () => {
      if (owned) { r.equip(f.id); return; }
      if (r.buyFlower(f.id)) celebrate();
    };
    let action;
    if (equipped) action = pill("Worn", { onClick, tone: "strong", icon: "check" });
    else if (owned) action = pill("Tap to wear", { onClick, tone: "primary" });
    else action = pill(String(f.price), { onClick, tone: affordable ? "soft" : "muted", disabled: !affordable, icon: "sparkles" });

    return html`<div key=${f.id} style=${{
      display: "flex", flexDirection: "column", alignItems: "center", gap: 6, textAlign: "center",
      padding: "14px 8px", background: "var(--surface)", borderRadius: 16,
      border: `${equipped ? 1.5 : 1}px solid ${equipped ? "var(--primary-strong)" : "var(--line)"}`,
    }}>
      <${Bloom} id=${f.id} size=${34} dim=${!owned && !affordable} />
      <div style=${{ fontWeight: 600, color: "var(--deep)", fontSize: 14 }}>${f.name}</div>
      <div style=${{ fontWeight: 700, fontSize: 10, letterSpacing: 0.6, color: "var(--muted)" }}>${f.rarity.toUpperCase()}</div>
      ${action}
    </div>`;
  };

  // ---- unlock row (palettes / chime / accent / color studio) ----
  const unlockRow = (key, { swatch, icon, title, owned, price, buy }) => html`<div key=${key} style=${{
    display: "flex", alignItems: "center", gap: 10, padding: "10px 14px",
    background: "var(--surface)", borderRadius: 16, border: "1px solid var(--line)",
  }}>
    ${swatch && html`<span style=${{ width: 20, height: 20, borderRadius: 999, background: swatch, border: "1px solid var(--line)", flex: "0 0 auto" }} />`}
    ${icon && html`<span style=${{ flex: "0 0 auto", width: 20, display: "inline-flex", justifyContent: "center" }}>
      <${Icon} name=${icon} size=${16} color="var(--primary-strong)" /></span>`}
    <span style=${{ flex: 1, fontWeight: 600, color: "var(--deep)", fontSize: 14 }}>${title}</span>
    ${owned
      ? html`<span style=${{ display: "inline-flex", alignItems: "center", gap: 4, fontWeight: 700, fontSize: 12, color: "var(--good)" }}>
          <${Icon} name="check" size=${13} color="var(--good)" />Owned</span>`
      : pill(String(price), { onClick: () => { if (buy()) celebrate(); }, tone: r.canAfford(price) ? "soft" : "muted", disabled: !r.canAfford(price), icon: "sparkles" })}
  </div>`;

  // ---- Posey card ----
  const poseyOwned = r.poseyOwned;
  const poseyEquipped = r.activeSticker === "posey";
  const poseyAction = () => {
    if (poseyOwned) { r.equip("posey"); return; }
    if (r.buyPosey()) celebrate();
  };

  // ---- share card (lightweight, screenshot-friendly overlay) ----
  const daysStretched = store.logsSnapshot.filter((l) => l.stretchDone === true).length;
  const flowersCollected = r.ownedFlowers.size + (poseyOwned ? 1 : 0);

  const shareCard = () => html`<div onClick=${() => setShowShare(false)} style=${{
    position: "fixed", inset: 0, background: "var(--surface-soft)", zIndex: 50,
    display: "flex", alignItems: "center", justifyContent: "center", padding: 20,
  }}>
    <div onClick=${(e) => e.stopPropagation()} style=${{ position: "relative", overflow: "hidden",
      width: "100%", maxWidth: 360, background: "var(--surface)", borderRadius: "var(--radius)",
      border: "1px solid var(--line)", padding: "28px 22px", textAlign: "center" }}>
      ${PetalRain && html`<${PetalRain} count=${14} />`}
      <div style=${{ display: "flex", justifyContent: "center", marginBottom: 8 }}>
        <${FlowerMark} size=${60} breathe=${true} /></div>
      <div style=${{ fontSize: 22, fontWeight: 700, color: "var(--deep)" }}>My stretch garden</div>
      <div style=${{ fontSize: 56, fontWeight: 600, color: "var(--primary-strong)", lineHeight: 1.1, marginTop: 6 }}>${r.lifetime}</div>
      <div style=${{ fontWeight: 700, fontSize: 11, letterSpacing: 1.4, color: "var(--muted)" }}>LIFETIME PETAL POINTS</div>
      <div style=${{ display: "flex", justifyContent: "center", gap: 28, marginTop: 16 }}>
        <div><div style=${{ fontSize: 20, fontWeight: 600, color: "var(--deep)" }}>${daysStretched}</div>
          <div style=${{ fontWeight: 700, fontSize: 10, letterSpacing: 0.8, color: "var(--muted)" }}>DAYS STRETCHED</div></div>
        <div><div style=${{ fontSize: 20, fontWeight: 600, color: "var(--deep)" }}>${flowersCollected}</div>
          <div style=${{ fontWeight: 700, fontSize: 10, letterSpacing: 0.8, color: "var(--muted)" }}>FLOWERS COLLECTED</div></div>
      </div>
      ${flowersCollected > 0 && html`<div style=${{ display: "flex", justifyContent: "center", flexWrap: "wrap", gap: 6, marginTop: 16 }}>
        ${FLOWERS.filter((f) => r.ownedFlowers.has(f.id)).map((f) => html`<${Bloom} key=${f.id} id=${f.id} size=${22} />`)}
        ${poseyOwned && html`<${FlowerMark} size=${24} />`}
      </div>`}
      <div style=${{ fontSize: 13, color: "var(--muted)", margin: "18px 0 12px" }}>Screenshot me and show someone you love.</div>
      <${Button} variant="soft" block=${true} onClick=${() => setShowShare(false)}>Done<//>
    </div>
  </div>`;

  return html`<div style=${{ position: "relative", padding: "12px 18px 24px", display: "flex", flexDirection: "column", gap: 22 }}>
    ${PetalRain && burst > 0 && html`<div key=${burst} style=${{ position: "absolute", inset: 0, pointerEvents: "none" }}><${PetalRain} count=${20} /></div>`}

    <!-- header -->
    <div style=${{ display: "flex", alignItems: "flex-start", gap: 12 }}>
      <div style=${{ flex: 1 }}>
        <h2 style=${{ fontSize: 24, fontWeight: 700, color: "var(--deep)", margin: 0 }}>The garden shop</h2>
        <p style=${{ fontSize: 14, color: "var(--muted)", margin: "2px 0 0" }}>Spend your petal points. Lifetime score never goes down.</p>
      </div>
      <div style=${{ display: "flex", flexDirection: "column", alignItems: "flex-end", gap: 6 }}>
        <${PointsPill} />
        <${IconButton} label="Close" onClick=${nav.close}><${Icon} name="x" size=${18} /><//>
      </div>
    </div>

    <!-- flowers -->
    <div style=${{ display: "flex", flexDirection: "column", gap: 10 }}>
      <p style=${{ fontSize: 12, color: "var(--muted)", margin: 0 }}>Flowers you own become stickers — tap one to wear it on your Today tab.</p>
      <div style=${{ display: "grid", gap: 10, gridTemplateColumns: "repeat(auto-fill, minmax(104px, 1fr))" }}>
        ${FLOWERS.map(flowerCell)}
      </div>
    </div>

    <!-- posey -->
    <${Card} variant="accent">
      <div style=${{ display: "flex", alignItems: "center", gap: 14 }}>
        <${FlowerMark} size=${44} />
        <div style=${{ flex: 1 }}>
          <div style=${{ fontSize: 16, fontWeight: 600, color: "var(--deep)" }}>Posey herself</div>
          <div style=${{ fontSize: 12, color: "var(--muted)", marginTop: 3 }}>${poseyOwned
            ? "She's yours. The rarest bloom in the garden."
            : "The legendary sticker. Your coach, on your Today tab."}</div>
        </div>
        ${poseyEquipped ? pill("Worn", { onClick: poseyAction, tone: "strong", icon: "check" })
          : poseyOwned ? pill("Wear", { onClick: poseyAction, tone: "primary" })
          : pill(String(PRICES.posey), { onClick: poseyAction, tone: r.canAfford(PRICES.posey) ? "soft" : "muted", disabled: !r.canAfford(PRICES.posey), icon: "sparkles" })}
      </div>
    <//>

    <!-- palettes & colors -->
    <div style=${{ display: "flex", flexDirection: "column", gap: 10 }}>
      <div style=${{ fontSize: 16, fontWeight: 600, color: "var(--deep)" }}>Palettes & colors</div>
      ${PAID_THEMES.map((name) => unlockRow(name, {
        swatch: THEME_SWATCH[name] || "var(--primary)",
        title: `${themeLabel(name)} palette`,
        owned: r.themeOwned(name), price: PRICES.theme, buy: () => r.buyTheme(name),
      }))}
      ${unlockRow("sound", { icon: "bell", title: "Celebration chime", owned: r.soundUnlocked, price: PRICES.sound, buy: () => r.buySound() })}
      ${unlockRow("accent", { icon: "sparkles", title: "Custom accent color", owned: r.accentUnlocked, price: PRICES.accent, buy: () => r.buyAccent() })}
      ${unlockRow("studio", { icon: "settings", title: "Color Studio — recolor nearly everything", owned: r.colorStudioUnlocked, price: PRICES.colorStudio, buy: () => r.buyColorStudio() })}
      <p style=${{ fontSize: 11, color: "var(--muted)", margin: 0 }}>Cherry, Rose and Dark are always free. Unlocked colors live in the pencil settings on Today.</p>
    </div>

    <${Button} variant="soft" block=${true} iconLeft=${html`<${Icon} name="gift" size=${16} />`} onClick=${() => setShowShare(true)}>Share your garden<//>

    ${showShare && shareCard()}
  </div>`;
}
