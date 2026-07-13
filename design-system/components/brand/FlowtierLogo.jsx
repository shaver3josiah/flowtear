import React from "react";

/**
 * FlowtierLogo — the Flowtier brand mark: a smiling pink alarm clock (time +
 * cycles, made friendly). Theme-tinted via tokens, so it re-colors with the
 * active preset. Pair with the Wordmark, or use solo as an app icon / splash.
 */
export function FlowtierLogo({ size = 96, title = "Flowtier", className = "", style, ...rest }) {
  const uid = React.useMemo(() => "ftlogo" + Math.random().toString(36).slice(2, 8), []);
  const cx = 50, cy = 55;
  const ticks = [];
  for (let i = 0; i < 12; i++) {
    const a = (i * 30 * Math.PI) / 180;
    const r1 = 27.5, r2 = i % 3 === 0 ? 23 : 25.2;
    ticks.push({ x1: cx + r1 * Math.sin(a), y1: cy - r1 * Math.cos(a), x2: cx + r2 * Math.sin(a), y2: cy - r2 * Math.cos(a), major: i % 3 === 0 });
  }
  const eyes = [[cx - 10.5, cy - 2], [cx + 10.5, cy - 2]];
  return (
    <svg viewBox="0 0 100 100" width={size} height={size} role="img" aria-label={title} className={className} style={{ display: "block", ...style }} {...rest}>
      <defs>
        <linearGradient id={uid} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="var(--primary)" />
          <stop offset="1" stopColor="var(--primary-strong)" />
        </linearGradient>
      </defs>
      {/* bells + top button */}
      <ellipse cx="30" cy="22" rx="12" ry="9.5" fill="var(--primary-strong)" transform="rotate(-26 30 22)" />
      <ellipse cx="70" cy="22" rx="12" ry="9.5" fill="var(--primary-strong)" transform="rotate(26 70 22)" />
      <rect x="47" y="9" width="6" height="10" rx="3" fill="var(--primary-strong)" />
      {/* feet */}
      <rect x="28" y="85" width="14" height="9" rx="4.5" fill="var(--primary-strong)" transform="rotate(26 35 90)" />
      <rect x="58" y="85" width="14" height="9" rx="4.5" fill="var(--primary-strong)" transform="rotate(-26 65 90)" />
      {/* body + rim + dial */}
      <circle cx={cx} cy={cy} r="38" fill={`url(#${uid})`} />
      <circle cx={cx} cy={cy} r="38" fill="none" stroke="var(--deep)" strokeOpacity="0.15" strokeWidth="1.5" />
      <circle cx={cx} cy={cy} r="30.5" fill="#fff" />
      {/* ticks */}
      {ticks.map((t, i) => (
        <line key={i} x1={t.x1} y1={t.y1} x2={t.x2} y2={t.y2} stroke="var(--primary)" strokeOpacity="0.7" strokeWidth={t.major ? 2.6 : 1.8} strokeLinecap="round" />
      ))}
      {/* cheeks */}
      <ellipse cx={cx - 13.5} cy={cy + 7} rx="4.6" ry="3" fill="var(--primary)" opacity="0.55" />
      <ellipse cx={cx + 13.5} cy={cy + 7} rx="4.6" ry="3" fill="var(--primary)" opacity="0.55" />
      {/* eyes with highlight */}
      {eyes.map(([x, y], i) => (
        <g key={i}>
          <circle cx={x} cy={y} r="3" fill="var(--deep)" />
          <circle cx={x + 1} cy={y - 1} r="0.9" fill="#fff" />
        </g>
      ))}
      {/* smile */}
      <path d={`M ${cx - 8.5} ${cy + 2.5} Q ${cx} ${cy + 13} ${cx + 8.5} ${cy + 2.5}`} fill="none" stroke="var(--deep)" strokeWidth="2.8" strokeLinecap="round" />
    </svg>
  );
}
