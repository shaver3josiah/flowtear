// RingSticker — port of App/Components/RingSticker.swift. Her flower rides the
// cycle ring like a bead on a bangle. The hitbox is the flower itself (the rest
// of the ring keeps its own tap). Dragging along the ring band keeps it
// magnetically locked to the ring — always concentric, never offset; fling it
// and it keeps spinning like a fidget spinner, shedding confetti while it's
// fast. Pull it clearly off the band and it PLUCKS free: drop it inside the ring
// or off to the side and it rests there (persisted); carry it back to the band
// and it snaps on again. Reduce Motion: drag still works, no inertia, no trail.

import { rewards, FLOWERS } from "../core/rewards.js";
import { keyFromDate } from "../core/dates.js";

const React = window.React;
const { useState, useRef, useEffect } = React;
const html = window.htm.bind(React.createElement);
const UI = window.FlowtierDesignSystem_6b3d0d || {};

/// Radius of the drawn track for a ring of `size` — the DS CycleRing draws its
/// arcs at r=84 in a 200 viewBox, so the flower beads onto the visible ring,
/// concentric with it. Mirrors CycleRing.trackRadius(for:) in Swift.
export const trackRadius = (size) => (84 * size) / 200;

const SNAP = 26;       // how far off the ring still counts as "on the band"
const FRAME_PAD = 96;  // Swift: diameter = radius * 2 + 96 — room for a free rest
const TAP = 44;        // FFSpace.tapMin — the flower's hitbox
const MAX_TRAIL = 16;

const reduceMotion = () =>
  typeof window.matchMedia === "function" &&
  window.matchMedia("(prefers-reduced-motion: reduce)").matches;

// The worn sticker, drawn inline (no emoji, no external asset) — the same
// procedural bloom the garden shop uses, so a flower reads the same in both.
function Bloom({ id, size }) {
  if (id === "posey" && UI.FlowerMark) return html`<${UI.FlowerMark} size=${size} />`;
  const idx = Math.max(FLOWERS.findIndex((f) => f.id === id), 0);
  const petals = 5 + (idx % 6);
  const fills = ["var(--primary)", "var(--primary-strong)", "var(--flower-center)", "var(--good)"];
  const fill = fills[idx % fills.length];
  const c = size / 2;
  const ring = size * 0.26;
  const nodes = [];
  for (let i = 0; i < petals; i++) {
    const a = (i / petals) * Math.PI * 2;
    const px = c + Math.cos(a) * ring;
    const py = c + Math.sin(a) * ring;
    nodes.push(html`<ellipse key=${i} cx=${px} cy=${py} rx=${size * 0.15} ry=${size * 0.26}
      transform=${`rotate(${(a * 180) / Math.PI + 90} ${px} ${py})`} fill=${fill} />`);
  }
  return html`<svg width=${size} height=${size} viewBox=${`0 0 ${size} ${size}`} aria-hidden="true"
      style=${{ display: "block" }}>
    ${nodes}
    <circle cx=${c} cy=${c} r=${size * 0.17} fill="var(--flower-center)" />
  </svg>`;
}

// RingChainView (RingSticker.swift) — her daisy chain: every bloom she's
// chained in the shop rides the ring together, evenly spaced from 12 o'clock.
// Purely decorative (the one ACTIVE sticker stays the draggable bead); no
// touches stolen from the scrub. Subscribes to rewards itself so chaining in
// the garden shop shows up the moment she's back on Today.
export function RingChain({ radius }) {
  const [, force] = useState(0);
  useEffect(() => rewards.subscribe(() => force((n) => n + 1)), []);
  const chain = rewards.ringChain ?? [];
  if (!chain.length) return null;
  return html`
    <div aria-hidden="true" style=${{
      position: "absolute", left: "50%", top: "50%", width: 0, height: 0, pointerEvents: "none",
    }}>
      ${chain.map((id, i) => {
        const a = (i / Math.max(chain.length, 1)) * 2 * Math.PI - Math.PI / 2;
        return html`<div key=${i} style=${{
          position: "absolute",
          transform: `translate(-50%, -50%) translate(${radius * Math.cos(a)}px, ${radius * Math.sin(a)}px)`,
        }}><${Bloom} id=${id} size=${19} /></div>`;
      })}
    </div>`;
}

export function RingSticker({ radius, periodFraction = 0 }) {
  const [, force] = useState(0);
  useEffect(() => rewards.subscribe(() => force((n) => n + 1)), []);

  // Her last resting place, from the shared garden blob (the same keys the iOS
  // build reads). The free rest is normalized by RADIUS, not the frame, so it
  // keeps the same relation to the band across ring sizes (hero vs preview).
  const [seed] = useState(() => ({
    angle: rewards.stickerAngle,
    free: { x: rewards.stickerX * radius, y: rewards.stickerY * radius },
    onRing: rewards.stickerMode !== "free",
  }));
  const [angle, setAngle] = useState(seed.angle);
  const [free, setFree] = useState(seed.free);
  const [onRing, setOnRing] = useState(seed.onRing);
  const [plucked, setPlucked] = useState(false);
  const [dragging, setDragging] = useState(false);
  const [trail, setTrail] = useState([]);
  const [pop, setPop] = useState(0);
  const [tease, setTease] = useState(false);
  const [bonus, setBonus] = useState(false);

  // React may batch a pointermove's state update past the pointerup that follows
  // it (a fast flick lands both in one frame), so every value the gesture READS
  // lives in a ref; the matching state is only there to paint.
  const wrap = useRef(null);
  const angRef = useRef(seed.angle);
  const freeRef = useRef(seed.free);
  const ringRef = useRef(seed.onRing);
  const vel = useRef(0);
  const lastAng = useRef(null);
  const drag = useRef({ active: false, x: 0, y: 0, plucked: false });
  const spins = useRef(0);
  const raf = useRef(0);
  const timers = useRef([]);

  const putAngle = (a) => { angRef.current = a; setAngle(a); };
  const putFree = (x, y) => { freeRef.current = { x, y }; setFree({ x, y }); };
  const putRing = (v) => { ringRef.current = v; setOnRing(v); };
  const putPlucked = (v) => { drag.current.plucked = v; setPlucked(v); };

  const after = (ms, fn) => timers.current.push(setTimeout(fn, ms));
  useEffect(() => () => {
    cancelAnimationFrame(raf.current);
    timers.current.forEach(clearTimeout);
  }, []);

  const id = rewards.activeSticker;
  const diameter = radius * 2 + FRAME_PAD;
  const pos = plucked || !onRing ? free : { x: Math.cos(angle) * radius, y: Math.sin(angle) * radius };

  const emitTrail = () => setTrail((t) => {
    const i = t.length;
    const next = t.concat({
      key: Date.now() + i,
      angle: angRef.current - vel.current * 2,
      spin: ((i * 97) % 70) - 35,
      tint: i % 3 === 0 ? "var(--flower-center)" : i % 2 === 0 ? "var(--primary)" : "var(--phase-follicular)",
      opacity: 0.85,
    });
    return next.slice(-MAX_TRAIL);
  });

  const fadeTrail = () => setTrail((t) =>
    t.map((b) => ({ ...b, opacity: b.opacity * 0.9 })).filter((b) => b.opacity >= 0.05));

  // Landed on the bleed arc? A small once-a-day bonus, with a note. The arc runs
  // from 12 o'clock clockwise, so the angle is turned a quarter before testing.
  const checkPeriodLanding = (a) => {
    if (!(periodFraction > 0)) return;
    const f = (((((a * 180) / Math.PI + 90) / 360) % 1) + 1) % 1;
    if (f >= periodFraction) return;
    if (!rewards.awardPeriodLanding(keyFromDate(new Date()))) return;
    setBonus(true);
    after(3000, () => setBonus(false));
  };

  const settle = (a) => {
    vel.current = 0;
    rewards.setStickerAngle(a);
    setPop((n) => n + 1);
    checkPeriodLanding(a);
    after(800, () => setTrail([]));
  };

  // The fidget: inertia with gentle friction, confetti while fast.
  const startSpin = () => {
    spins.current += 1;
    if (spins.current >= 5) {
      spins.current = 0;
      setTease(true);
      after(4000, () => setTease(false));
    }
    let frames = 0;
    const step = () => {
      putAngle(angRef.current + vel.current);
      vel.current *= 0.965;
      frames += 1;
      if (Math.abs(vel.current) > 0.05 && frames % 3 === 0) emitTrail();
      fadeTrail();
      if (Math.abs(vel.current) > 0.006) raf.current = requestAnimationFrame(step);
      else settle(angRef.current);
    };
    raf.current = requestAnimationFrame(step);
  };

  const center = () => {
    const b = wrap.current.getBoundingClientRect();
    return { x: b.left + b.width / 2, y: b.top + b.height / 2 };
  };

  const onDown = (e) => {
    e.stopPropagation();
    e.currentTarget.setPointerCapture(e.pointerId);
    cancelAnimationFrame(raf.current);
    drag.current = { active: true, x: e.clientX, y: e.clientY };
    setDragging(true);
  };

  const onMove = (e) => {
    if (!drag.current.active) return;
    const c = center();
    const dx = e.clientX - c.x;
    const dy = e.clientY - c.y;
    const onBand = Math.abs(Math.hypot(dx, dy) - radius) <= SNAP;
    // A free-resting flower needs real movement before it re-beads — a bare tap
    // must never yank it out of its placed spot.
    const moved = Math.hypot(e.clientX - drag.current.x, e.clientY - drag.current.y) > 8;
    if (onBand && (ringRef.current || moved)) {
      // On the band: magnetically locked to the ring, concentric.
      putPlucked(false);
      putRing(true);
      const a = Math.atan2(dy, dx);
      if (lastAng.current != null) {
        let delta = a - lastAng.current;
        if (delta > Math.PI) delta -= 2 * Math.PI;
        if (delta < -Math.PI) delta += 2 * Math.PI;
        vel.current = delta;
        if (!reduceMotion() && Math.abs(delta) > 0.06) emitTrail();
      }
      lastAng.current = a;
      putAngle(a);
    } else if (!onBand && (ringRef.current || drag.current.plucked || moved)) {
      // Plucked: the flower follows her finger anywhere.
      putPlucked(true);
      lastAng.current = null;
      vel.current = 0;
      const limit = diameter / 2 - 14;
      putFree(Math.min(Math.max(dx, -limit), limit), Math.min(Math.max(dy, -limit), limit));
    }
    // else: an untraveled touch on a free-resting flower — hold still.
  };

  const onUp = () => {
    if (!drag.current.active) return;
    drag.current.active = false;
    setDragging(false);
    lastAng.current = null;
    const rest = freeRef.current;
    if (drag.current.plucked) {
      putPlucked(false);
      if (Math.abs(Math.hypot(rest.x, rest.y) - radius) <= SNAP) {
        // Dropped onto the band — it beads back onto the ring.
        const a = Math.atan2(rest.y, rest.x);
        putAngle(a);
        putRing(true);
        rewards.setStickerMode("ring");
        settle(a);
      } else {
        putRing(false);
        rewards.setStickerPosition(rest.x / radius, rest.y / radius);
        rewards.setStickerMode("free");
        setPop((n) => n + 1);
        setTrail([]);
      }
    } else if (ringRef.current) {
      rewards.setStickerMode("ring");
      if (!reduceMotion() && Math.abs(vel.current) > 0.035) startSpin();
      else settle(angRef.current);
    }
    // else: an idle tap on a free-resting flower — leave it be.
  };

  if (!id) return null;

  const at = (x, y) => `translate(-50%, -50%) translate(${x}px, ${y}px)`;

  return html`
    <div ref=${wrap} style=${{
      position: "absolute", left: "50%", top: "50%",
      transform: "translate(-50%, -50%)",
      width: diameter, height: diameter, pointerEvents: "none",
    }}>
      ${trail.map((b) => html`
        <span key=${b.key} style=${{
          position: "absolute", left: "50%", top: "50%", width: 6, height: 9,
          borderRadius: "50%", background: b.tint, opacity: b.opacity,
          transform: `${at(Math.cos(b.angle) * radius, Math.sin(b.angle) * radius)} rotate(${b.spin}deg)`,
        }} />`)}

      <div key=${`pop-${pop}`} onPointerDown=${onDown} onPointerMove=${onMove}
        onPointerUp=${onUp} onPointerCancel=${onUp}
        role="button" tabindex="0"
        aria-label="Your flower sticker"
        aria-description="Drag along the ring to spin it, or pull it off and set it anywhere"
        style=${{
          position: "absolute", left: "50%", top: "50%",
          width: TAP, height: TAP, borderRadius: "50%",
          display: "flex", alignItems: "center", justifyContent: "center",
          transform: `${at(pos.x, pos.y)} scale(${dragging ? 1.2 : 1})`,
          transition: dragging ? "none" : "transform var(--dur-base) var(--ease-signature)",
          filter: dragging ? "drop-shadow(0 2px 6px var(--shadow))" : "none",
          animation: pop && !dragging ? "flowtier-pop var(--dur-base) var(--ease-signature)" : "none",
          pointerEvents: "auto", touchAction: "none", cursor: "grab",
        }}>
        <${Bloom} id=${id} size=${30} />
      </div>

      ${tease && html`
        <div style=${{
          position: "absolute", top: 0, left: "50%", transform: "translateX(-50%)",
          display: "flex", alignItems: "center", gap: 8, whiteSpace: "nowrap",
          padding: "8px 12px", borderRadius: 999, background: "var(--surface)",
          border: "1px solid var(--line)", boxShadow: "0 2px 6px var(--shadow)",
          fontSize: "var(--text-xs)", fontWeight: 500, color: "var(--text)",
        }}>
          ${UI.FlowerMark && html`<${UI.FlowerMark} size=${22} />`}
          All that spinning, petal — imagine the petals if we stretched.
        </div>`}

      ${bonus && html`
        <div style=${{
          position: "absolute", bottom: 0, left: "50%", transform: "translateX(-50%)",
          whiteSpace: "nowrap", padding: "7px 12px", borderRadius: 999,
          background: "var(--phase-menstrual-soft)", color: "var(--deep)",
          fontSize: "var(--text-xs)", fontWeight: 700,
        }}>+5 — right on your period day</div>`}
    </div>`;
}

export default RingSticker;
