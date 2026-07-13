import React from "react";

function injectOnce(id, css) {
  if (typeof document === "undefined" || document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}

injectOnce(
  "ft-petalrain-css",
  `.ft-petal{position:absolute;top:-8%;border-radius:100% 0 100% 0;will-change:top,transform;animation-name:ft-petal-fall;animation-timing-function:linear;animation-iteration-count:infinite}
@keyframes ft-petal-fall{0%{top:-10%;opacity:0;transform:translateX(0) rotate(0)}12%{opacity:var(--_o,.8)}88%{opacity:var(--_o,.6)}100%{top:110%;opacity:0;transform:translateX(var(--_drift)) rotate(var(--_spin))}}
@media (prefers-reduced-motion: reduce){.ft-petal{animation:none;display:none}}`
);

const rnd = (min, max) => min + Math.random() * (max - min);

/**
 * PetalRain — the signature "magical" layer: soft rose petals drifting down,
 * from the Bloom family's petal curtain. Absolutely fills its positioned parent,
 * ignores pointer events, and disappears entirely under reduced-motion.
 */
export function PetalRain({ count = 14, zIndex = 0, className = "", style, ...rest }) {
  const petals = React.useMemo(
    () =>
      Array.from({ length: count }).map(() => ({
        left: rnd(0, 100),
        size: rnd(8, 17),
        delay: -rnd(0, 14),
        dur: rnd(7, 15),
        drift: rnd(-45, 45),
        spin: rnd(160, 520),
        op: rnd(0.45, 0.9),
        strong: Math.random() < 0.5,
      })),
    [count]
  );
  return (
    <div
      className={["ft-petalrain", className].filter(Boolean).join(" ")}
      aria-hidden="true"
      style={{ position: "absolute", inset: 0, overflow: "hidden", pointerEvents: "none", zIndex, ...style }}
      {...rest}
    >
      {petals.map((p, i) => (
        <span
          key={i}
          className="ft-petal"
          style={{
            left: p.left + "%",
            width: p.size,
            height: p.size * 1.15,
            background: `linear-gradient(135deg, ${p.strong ? "var(--primary)" : "var(--primary-strong)"}, var(--deep))`,
            "--_drift": p.drift + "px",
            "--_spin": p.spin + "deg",
            "--_o": p.op,
            animationDelay: p.delay + "s",
            animationDuration: p.dur + "s",
          }}
        />
      ))}
    </div>
  );
}
