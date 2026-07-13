import React from "react";

/* Rose-petal ring geometry, recreated faithfully from the Bloom family's
   FlowerLogo (three concentric elliptical-petal rings + a gold center).
   Each petal is an ellipse pushed out along (angle - 90°) and rotated by angle. */
function petalRing({ count, lengthScale, widthScale, offsetFraction }) {
  const C = 50;
  const petalLength = 100 * lengthScale;
  const petalWidth = 100 * widthScale;
  const out = [];
  for (let i = 0; i < count; i++) {
    const angleDeg = i * (360 / count);
    const a = ((angleDeg - 90) * Math.PI) / 180;
    const cx = C + petalLength * offsetFraction * Math.cos(a);
    const cy = C + petalLength * offsetFraction * Math.sin(a);
    out.push(
      <ellipse
        key={i}
        cx={cx}
        cy={cy}
        rx={petalWidth / 2}
        ry={petalLength / 2}
        transform={`rotate(${angleDeg} ${cx} ${cy})`}
      />
    );
  }
  return out;
}

const RINGS = [
  { count: 8, lengthScale: 0.44, widthScale: 0.3, offsetFraction: 0.52, fill: "var(--primary)", opacity: 0.55, rot: 6 },
  { count: 7, lengthScale: 0.34, widthScale: 0.24, offsetFraction: 0.5, fill: "var(--primary)", opacity: 1, rot: -9 },
  { count: 6, lengthScale: 0.24, widthScale: 0.18, offsetFraction: 0.46, fill: "var(--primary-strong)", opacity: 1, rot: 15 },
];

/**
 * FlowerMark — the Flowtier bloom, the brand's signature motif.
 * A procedural rose: three petal rings in the theme pinks around a gold center.
 */
export function FlowerMark({ size = 48, spin = false, breathe = false, title = "Flowtier", style, className, ...rest }) {
  const anim = spin
    ? "flowtier-spin 14s linear infinite"
    : breathe
    ? "flowtier-breathe 4s var(--ease-in-out, ease-in-out) infinite"
    : undefined;
  return (
    <svg
      viewBox="0 0 100 100"
      width={size}
      height={size}
      role="img"
      aria-label={title}
      className={className}
      style={{ display: "block", transformOrigin: "50% 50%", animation: anim, ...style }}
      {...rest}
    >
      {RINGS.map((r, idx) => (
        <g key={idx} transform={`rotate(${r.rot} 50 50)`} fill={r.fill} opacity={r.opacity}>
          {petalRing(r)}
        </g>
      ))}
      <circle cx="50" cy="50" r="11" fill="var(--flower-center)" />
    </svg>
  );
}
