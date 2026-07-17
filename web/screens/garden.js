// The garden shop — a port of App/Views/GardenShopView.swift. Spend petal points
// on flower stickers (ten of rising rarity), Posey herself, palettes, celebration
// sounds, a custom accent, and the Color Studio. Owned flowers can be worn as the
// Today-tab sticker. All economy + persistence lives in the shared rewards
// singleton (web/core/rewards.js); this screen just reads and drives it.
//
// Nothing here spends a petal without one confirm step, and a tap she can't
// afford opens the "not yet" splash instead of doing nothing.

import { rewards, FLOWERS, SOUNDS, PRICES, PAID_THEMES } from "../core/rewards.js";

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
  const { Card, IconButton, Button, Switch, FlowerMark, PetalRain } = ui;
  const r = useRewards();

  const [burst, setBurst] = useState(0);          // bumps a petal-rain celebration
  const [showShare, setShowShare] = useState(false);
  const [pendingBuy, setPendingBuy] = useState(null);   // { name, price, buy }

  const celebrate = () => {
    setBurst((n) => n + 1);
    r.playCelebrationIfOwned();
  };

  // Affordable → one confirm step; short on petals → the splash. Mis-taps never
  // spend anything. `back: "garden"` brings her home from the splash.
  const confirmOrGap = (name, price, buy) => {
    if (r.canAfford(price)) setPendingBuy({ name, price, buy });
    else nav.open("needPetals", { name, price, back: "garden" });
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
  const pill = (label, { onClick, tone = "soft", icon } = {}) => {
    const bg = tone === "strong" ? "var(--primary-strong)" : "var(--surface-soft)";
    // Swift moved these pills from .white to theme.color(.onPrimary) so the
    // label stays readable on every palette's primary — same token here.
    const fg = tone === "strong" ? "var(--text-on-primary)"
      : tone === "muted" ? "var(--muted)"
      : tone === "primary" ? "var(--primary-strong)" : "var(--deep)";
    return html`<button onClick=${onClick}
      style=${{
        display: "inline-flex", alignItems: "center", gap: 4, padding: "5px 10px", borderRadius: 999,
        border: "none", background: bg, color: fg, fontWeight: 700, fontSize: 12, cursor: "pointer",
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
      confirmOrGap(`the ${f.name}`, f.price, () => { if (r.buyFlower(f.id)) celebrate(); });
    };
    let action;
    if (equipped) action = pill("Worn", { onClick, tone: "strong", icon: "check" });
    else if (owned) action = pill("Tap to wear", { onClick, tone: "primary" });
    else action = pill(String(f.price), { onClick, tone: affordable ? "soft" : "muted", icon: "sparkles" });

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

  // ---- unlock row (palettes / accent / color studio) ----
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
      : pill(String(price), { onClick: buy, tone: r.canAfford(price) ? "soft" : "muted", icon: "sparkles" })}
  </div>`;

  // ---- sound row: elegant unlockable chimes, played when a session ends or a
  // log lands. (The native shelf plays iOS system sounds; the web synthesizes a
  // matching tone per sound — see rewards.js.)
  const soundRow = (s) => {
    const owned = r.soundOwned(s.id);
    const active = r.activeSound === s.id;
    const onClick = () => {
      if (owned) { r.useSound(s.id); return; }
      confirmOrGap(`the ${s.name} sound`, s.price, () => { if (r.buySoundItem(s.id)) setBurst((n) => n + 1); });
    };
    return html`<div key=${s.id} style=${{
      display: "flex", alignItems: "center", gap: 10, padding: "10px 14px",
      background: "var(--surface)", borderRadius: 16, border: "1px solid var(--line)",
    }}>
      <span style=${{ flex: "0 0 auto", width: 20, display: "inline-flex", justifyContent: "center" }}>
        <${Icon} name="bell" size=${16} color=${active ? "var(--primary-strong)" : "var(--muted)"} /></span>
      <span style=${{ flex: 1, fontWeight: 600, color: "var(--deep)", fontSize: 14 }}>${s.name}</span>
      ${active ? pill("On", { onClick, tone: "strong", icon: "check" })
        : owned ? pill("Use", { onClick, tone: "primary" })
        : pill(String(s.price), { onClick, tone: r.canAfford(s.price) ? "soft" : "muted", icon: "sparkles" })}
    </div>`;
  };

  // ---- the daisy chain: owned blooms she taps into a chain that circles her
  // Today ring together. Three or more and Posey can wear it as a crown.
  // (Chaining is free — no petals move, so no confirm step.)
  const chainChip = (f) => {
    const chained = r.inChain(f.id);
    return html`<button key=${f.id} onClick=${() => r.toggleChain(f.id)}
      aria-label=${`${f.name}${chained ? ", in your chain" : ", not in your chain"}`}
      title=${chained ? "Removes it from the chain" : "Adds it to the chain"}
      style=${{
        display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
        gap: 3, minHeight: 52, padding: "6px 4px", cursor: "pointer",
        background: chained ? "var(--surface-soft)" : "var(--surface)", borderRadius: 12,
        border: `${chained ? 1.5 : 1}px solid ${chained ? "var(--primary-strong)" : "var(--line)"}`,
      }}>
      <${Bloom} id=${f.id} size=${24} />
      <${Icon} name=${chained ? "check" : "plus"} size=${12}
        color=${chained ? "var(--good)" : "var(--muted)"} />
    </button>`;
  };

  const chainCard = () => {
    const ownedList = FLOWERS.filter((f) => r.ownedFlowers.has(f.id));
    const n = r.ringChain.length;
    return html`<${Card}>
      <div style=${{ display: "flex", flexDirection: "column", gap: 8 }}>
        <div style=${{ display: "flex", alignItems: "center", gap: 6, fontWeight: 600, color: "var(--deep)", fontSize: 15 }}>
          <${Icon} name="flower-2" size=${16} color="var(--primary-strong)" />Your flower chain
        </div>
        <div style=${{ fontSize: 12, color: "var(--muted)" }}>
          Tap owned blooms into a chain — they circle your Today ring together. Three or more make a crown Posey can wear.
        </div>
        ${ownedList.length === 0
          ? html`<div style=${{ fontSize: 12, fontWeight: 500, color: "var(--muted)" }}>Flowers you own will appear here, ready to chain.</div>`
          : html`<div style=${{ display: "grid", gap: 8, gridTemplateColumns: "repeat(auto-fill, minmax(52px, 1fr))" }}>
              ${ownedList.map(chainChip)}
            </div>`}
        <div style=${{ display: "flex", alignItems: "center", gap: 10, marginTop: 2 }}>
          <div style=${{ flex: 1, display: "flex", flexDirection: "column", gap: 2 }}>
            <div style=${{ fontSize: 14, fontWeight: 600, color: "var(--text)" }}>Posey wears the crown</div>
            <div style=${{ fontSize: 12, color: "var(--muted)" }}>${n >= 3
              ? "Your chain, resting on her petals"
              : `Chain ${3 - n} more bloom${n === 2 ? "" : "s"} to crown her`}</div>
          </div>
          <${Switch} checked=${r.poseyCrowned} disabled=${n < 3}
            label="Posey wears the flower crown"
            onChange=${(on) => r.setPoseyCrowned(on)} />
        </div>
      </div>
    <//>`;
  };

  // ---- Posey card ----
  const poseyOwned = r.poseyOwned;
  const poseyEquipped = r.activeSticker === "posey";
  const poseyAction = () => {
    if (poseyOwned) { r.equip("posey"); return; }
    confirmOrGap("Posey herself", PRICES.posey, () => { if (r.buyPosey()) setBurst((n) => n + 1); });
  };

  // ---- one confirm step before petals leave her balance ----
  const confirmDialog = () => html`<div onClick=${() => setPendingBuy(null)} style=${{
    position: "fixed", inset: 0, background: "var(--surface-soft)", zIndex: 60,
    display: "flex", alignItems: "center", justifyContent: "center", padding: 20,
  }}>
    <div role="dialog" aria-modal="true" onClick=${(e) => e.stopPropagation()} style=${{
      width: "100%", maxWidth: 320, background: "var(--surface)", borderRadius: "var(--radius)",
      border: "1px solid var(--line)", padding: 20, textAlign: "center",
    }}>
      <div style=${{ fontSize: 18, fontWeight: 700, color: "var(--deep)" }}>Bring home ${pendingBuy.name}?</div>
      <div style=${{ fontSize: 13, color: "var(--muted)", margin: "8px 0 16px" }}>
        That leaves ${Math.max(r.balance - pendingBuy.price, 0)} of your ${r.balance} petals.</div>
      <div style=${{ display: "flex", flexDirection: "column", gap: 8 }}>
        <${Button} variant="primary" block=${true} iconLeft=${html`<${Icon} name="sparkles" size=${16} />`}
          onClick=${() => { const b = pendingBuy; setPendingBuy(null); b.buy(); }}>Buy for ${pendingBuy.price} petals<//>
        <${Button} variant="ghost" size="sm" block=${true} onClick=${() => setPendingBuy(null)}>Cancel<//>
      </div>
    </div>
  </div>`;

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

    <!-- flower chain -->
    ${chainCard()}

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
          : pill(String(PRICES.posey), { onClick: poseyAction, tone: r.canAfford(PRICES.posey) ? "soft" : "muted", icon: "sparkles" })}
      </div>
    <//>

    <!-- palettes & colors -->
    <div style=${{ display: "flex", flexDirection: "column", gap: 10 }}>
      <div style=${{ fontSize: 16, fontWeight: 600, color: "var(--deep)" }}>Palettes & colors</div>
      ${PAID_THEMES.map((name) => unlockRow(name, {
        swatch: THEME_SWATCH[name] || "var(--primary)",
        title: `${themeLabel(name)} palette`,
        owned: r.themeOwned(name), price: PRICES.theme,
        buy: () => confirmOrGap(`the ${themeLabel(name)} palette`, PRICES.theme,
          () => { if (r.buyTheme(name)) setBurst((n) => n + 1); }),
      }))}
      ${unlockRow("accent", {
        icon: "sparkles", title: "Custom accent color",
        owned: r.accentUnlocked, price: PRICES.accent,
        buy: () => confirmOrGap("the custom accent color", PRICES.accent,
          () => { if (r.buyAccent()) setBurst((n) => n + 1); }),
      })}
      ${SOUNDS.map(soundRow)}
      ${unlockRow("studio", {
        icon: "settings", title: "Color Studio — recolor nearly everything",
        owned: r.colorStudioUnlocked, price: PRICES.colorStudio,
        buy: () => confirmOrGap("the Color Studio", PRICES.colorStudio,
          () => { if (r.buyColorStudio()) setBurst((n) => n + 1); }),
      })}
      <p style=${{ fontSize: 11, color: "var(--muted)", margin: 0 }}>Cherry, Rose and Dark are always free. Unlocked colors live in the pencil settings on Today.</p>
    </div>

    <${Button} variant="soft" block=${true} iconLeft=${html`<${Icon} name="gift" size=${16} />`} onClick=${() => setShowShare(true)}>Share your garden<//>

    ${pendingBuy && confirmDialog()}
    ${showShare && shareCard()}
  </div>`;
}
